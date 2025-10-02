
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/intl.dart';
import 'package:medguard/api_service.dart';
import 'package:medguard/history_screen.dart';
import 'package:medguard/inventory_screen.dart';
import 'package:medguard/l10n/app_localizations.dart';
import 'package:medguard/medicine_details_screen.dart';
import 'package:medguard/profile_screen.dart';
import 'package:medguard/scan_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService.instance;
  // We now have two futures: one for today's doses, and one for the summary list of all medicines.
  late Future<List<dynamic>> _todaysDosesFuture;
  late Future<List<dynamic>> _allMedicinesFuture;

  @override
  void initState() {
    super.initState();
    _refreshDashboard();
    _setupNotificationListeners();
  }

  void _refreshDashboard() {
    if (mounted) {
      setState(() {
        _todaysDosesFuture = _apiService.getTodaysDoses();
        _allMedicinesFuture = _apiService.getDashboardData();
      });
    }
  }
// In lib/dashboard_screen.dart, inside the _DashboardScreenState class

Future<void> _takeDose(int userMedicineId, DateTime scheduledTime) async {
  // Show a loading indicator or disable the button if you want, for now we just call
  bool success = await _apiService.takeDoseManually(userMedicineId, scheduledTime);
  if (success) {
    // If successful, refresh the entire dashboard to show the updated status and stock
    _refreshDashboard();
  } else if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to record dose.'), backgroundColor: Colors.red),
    );
  }
}
  void _setupNotificationListeners() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessage(message);
    });

    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _handleMessage(message);
      }
    });
  }

  void _handleMessage(RemoteMessage message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final logId = int.tryParse(message.data['logId'] ?? '');
        final body = message.notification?.body ?? 'your medicine';
        if (logId != null) {
          showDoseActionDialog(logId, body);
        }
      }
    });
  }

  void showDoseActionDialog(int logId, String body) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Dose'),
        content: Text('Did you take your dose? ($body)'),
        actions: [
          TextButton(child: const Text('Skip'), onPressed: () => Navigator.of(dialogContext).pop()),
          TextButton(
            child: const Text('Snooze'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _showSnoozeOptions(logId);
            },
          ),
          FilledButton(
            child: const Text('Take'),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              bool success = await _apiService.markDoseAsTaken(logId);
              if (success) {
                _refreshDashboard();
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error updating inventory.'), backgroundColor: Colors.red),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showSnoozeOptions(int logId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Snooze for...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [15, 30, 60].map((minutes) {
            return ListTile(
              title: Text('$minutes minutes'),
              onTap: () async {
                Navigator.of(context).pop();
                await _apiService.snoozeDose(logId, minutes);
                 if (mounted) {
                   // ignore: use_build_context_synchronously
                   ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(content: Text('Reminder snoozed for $minutes minutes.')),
                   );
                 }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _navigateAndRefresh() async {
    final result = await Navigator.push(
      context, MaterialPageRoute(builder: (context) => const ScanScreen()));
    if (result == true) {
      _refreshDashboard();
    }
  }

  void _navigateToDetails(Map<String, dynamic> med) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MedicineDetailsScreen(medicine: med)),
    );
    if (result == true) {
      _refreshDashboard();
    }
  }

  IconData _getMedicineIcon(String medicineName) {
    final name = medicineName.toLowerCase();
    if (name.contains('capsule')) return Icons.medical_services_outlined;
    if (name.contains('syrup') || name.contains('liquid')) return Icons.opacity;
    if (name.contains('inhaler')) return Icons.air;
    if (name.contains('injection')) return Icons.colorize;
    return Icons.medication; // Default pill icon
  }

  Widget _buildStatusIcon(String? status) {
    switch (status) {
      case 'Taken':
        return const Icon(Icons.check_circle, color: Colors.green, size: 30);
      case 'Missed':
        return const Icon(Icons.cancel, color: Colors.red, size: 30);
      default:
        return const Icon(Icons.hourglass_empty, color: Colors.blue, size: 30);
    }
  }

  /*Widget _buildTodayDoseTile(Map<String, dynamic> dose) {
    final scheduledTime = DateTime.parse(dose['ScheduledTime']);
    final status = dose['Status'];
    final bool canBeTaken = (status == 'Upcoming' || status == 'Reminded' || status == 'Snoozed');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: _buildStatusIcon(status),
        title: Text(dose['MedicineName'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(dose['Dosage'] ?? 'No dosage set'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(DateFormat.jm().format(scheduledTime), style: Theme.of(context).textTheme.titleMedium),
            if (canBeTaken) const SizedBox(height: 4),
            if (canBeTaken)
              SizedBox(
                height: 28,
                child: FilledButton(
                  onPressed: () => _apiService.takeDoseManually(dose['UserMedicineID'], scheduledTime).then((_) => _refreshDashboard()),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
                  child: const Text('Take'),
                ),
              ),
          ],
        ),
      ),
    ).animate().fade(duration: 500.ms).slideY(begin: 0.2);
  }*/

  // In lib/dashboard_screen.dart

Widget _buildTodayDoseTile(Map<String, dynamic> dose) {
  final scheduledTime = DateTime.parse(dose['ScheduledTime']);
  final status = dose['Status'];
  final currentStock = dose['CurrentInventory'] ?? 0;
  final bool canBeTaken = (status == 'Upcoming' || status == 'Reminded' || status == 'Snoozed');
  final bool isOutOfStock = currentStock <= 0;

  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: ListTile(
      leading: _buildStatusIcon(status),
      title: Text(dose['MedicineName'], style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(dose['Dosage'] ?? 'No dosage set'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(DateFormat.jm().format(scheduledTime), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          // NEW LOGIC: Show a button OR an "Out of Stock" message
          if (canBeTaken)
            isOutOfStock
                ? const Text('Out of Stock', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                : SizedBox(
                    height: 28,
                    child: FilledButton(
                      // Button is now disabled if out of stock
                      //onPressed: () => _apiService.takeDoseManually(dose['UserMedicineID'], scheduledTime).then((_) => _refreshDashboard()),
                      onPressed: () => _takeDose(dose['UserMedicineID'], scheduledTime),
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
                      child: const Text('Take'),
                    ),
                  )
          else
            // If status is "Taken", just show a blank space
            const SizedBox(height: 28),
        ],
      ),
    ),
  ).animate().fade(duration: 500.ms).slideY(begin: 0.2);
}
  
  Widget _buildAllMedicineTile(Map<String, dynamic> med) {
    bool isExpired = false;
    if (med['SoonestExpiryDate'] != null) {
      final expiryDate = DateTime.parse(med['SoonestExpiryDate']);
      final today = DateTime.now();
      final todayWithoutTime = DateTime(today.year, today.month, today.day);
      if (!expiryDate.isAfter(todayWithoutTime)) {
        isExpired = true;
      }
    }

    bool isLowOnStock = false;
    if (!isExpired && med['CurrentInventory'] <= med['LowStockThreshold']) {
      isLowOnStock = true;
    }

    final card = Card(
      elevation: isLowOnStock ? 4 : 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: isLowOnStock ? Colors.orangeAccent : Colors.black12, width: isLowOnStock ? 2 : 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          _getMedicineIcon(med['MedicineName']),
          color: isExpired ? Colors.red : Theme.of(context).primaryColor,
          size: 36,
        ),
        title: Text(
          med['MedicineName'],
          style: TextStyle(
            decoration: isExpired ? TextDecoration.lineThrough : TextDecoration.none,
            color: isExpired ? Colors.red : null,
          ),
        ),
        subtitle: isExpired
            ? const Text('EXPIRED', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
            : Text('Low stock warning at: ${med['LowStockThreshold']}'),
        trailing: Text('Stock: ${med['CurrentInventory']}', style: Theme.of(context).textTheme.titleLarge),
        onTap: () => _navigateToDetails(med),
      ),
    );

    if (isLowOnStock) {
      return card.animate(onPlay: (controller) => controller.repeat(reverse: true))
                 .scale(duration: 1000.ms, begin: const Offset(1, 1), end: const Offset(1.02, 1.02), curve: Curves.easeInOut);
    }
    return card;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboardTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const InventoryScreen())).then((_) => _refreshDashboard());
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshDashboard(),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 80),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(l10n.todaysDoses, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            FutureBuilder<List<dynamic>>(
              future: _todaysDosesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()));
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text('No doses scheduled for today.')));
                return Column(children: snapshot.data!.map((dose) => _buildTodayDoseTile(dose)).toList());
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 30, 16, 8),
              child: Text(l10n.allMyMedicines, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            FutureBuilder<List<dynamic>>(
              future: _allMedicinesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox.shrink();
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text('No medicines added yet.')));
                return Column(children: snapshot.data!.map((med) => _buildAllMedicineTile(med)).toList());
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateAndRefresh,
        child: const Icon(Icons.add),
      ),
    );
  }
}


//29-09-2025
/*// lib/dashboard_screen.dart
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
//import 'package:intl/intl.dart';
import 'package:medguard/api_service.dart';
import 'package:medguard/history_screen.dart';
import 'package:medguard/l10n/app_localizations.dart';
import 'package:medguard/medicine_details_screen.dart';
import 'package:medguard/profile_screen.dart';
import 'package:medguard/scan_screen.dart';
import 'package:medguard/inventory_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DashboardScreen extends StatefulWidget {
  // NEW: Accept an optional logId
  final int? initialLogId;
  const DashboardScreen({super.key, this.initialLogId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

// In lib/dashboard_screen.dart

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService.instance;
  late Future<List<dynamic>> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _refreshDashboard();
    _setupNotificationListeners(); // Set up listeners when the screen is created
  }

IconData _getMedicineIcon(String medicineName) {
    final name = medicineName.toLowerCase();
    if (name.contains('capsule')) return Icons.medical_services_outlined; // A capsule-like icon
    if (name.contains('syrup') || name.contains('liquid')) return Icons.opacity;
    if (name.contains('inhaler')) return Icons.air;
    if (name.contains('injection')) return Icons.colorize;
    return Icons.medication; // Default pill icon
  }

  void _setupNotificationListeners() {
    // Listener for when app is in background and opened by notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessage(message);
    });

    // Check if app was opened from a terminated state by notification
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _handleMessage(message);
      }
    });
  }

  void _handleMessage(RemoteMessage message) {
    // This is a safe way to show a dialog after the screen is built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final logId = int.tryParse(message.data['logId'] ?? '');
        final body = message.notification?.body ?? 'your medicine';
        if (logId != null) {
          showDoseActionDialog(logId, body);
        }
      }
    });
  }
  
  void _refreshDashboard() {
    if (mounted) {
      setState(() {
        _dashboardFuture = _apiService.getDashboardData();
      });
    }
  }

  // All your other methods (_showSnoozeOptions, showDoseActionDialog, build, etc.)
  // should be copied here exactly as they were from our previous working version.
  // Make sure they call the public 'refreshDashboard' if they need to.

//27-09-2025
  void showDoseActionDialog(int logId, String body) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Dose'),
        content: Text('Did you take your dose? ($body)'),
        actions: [
          TextButton(child: const Text('Skip'), onPressed: () => Navigator.of(context).pop()),
          TextButton(
            child: const Text('Snooze'),
            onPressed: () {
              Navigator.of(context).pop();
              _showSnoozeOptions(logId);
            },
          ),
          FilledButton(
            child: const Text('Take'),
            onPressed: () async {
              Navigator.of(context).pop();
              bool success = await _apiService.markDoseAsTaken(logId);
             if (success) {
              _refreshDashboard();
            } else {
              if (mounted) {
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error updating inventory.'), backgroundColor: Colors.red),
                );
              }
            }
          },
          ),
        ],
      ),
    );
  }

  /*void showDoseActionDialog(int logId, String body) {
  showDialog(
    context: context,
    // The 'builder' creates a new context for the dialog, which we call 'dialogContext'
    builder: (dialogContext) => AlertDialog(
      title: const Text('Confirm Dose'),
      content: Text('Did you take your dose? ($body)'),
      actions: [
        TextButton(
          child: const Text('Skip'),
          // We use the dialog's own context to close it
          onPressed: () => Navigator.of(dialogContext).pop(),
        ),
        FilledButton(
          child: const Text('Take'),
          onPressed: () async {
            // First, close the dialog using its own context
            Navigator.of(dialogContext).pop();

            print("---[Dashboard]: Take button tapped for LogID: $logId ---");
            bool success = await _apiService.markDoseAsTaken(logId);
            print("---[Dashboard]: ApiService returned: $success ---");
            
            if (success) {
              print("---[Dashboard]: Refreshing dashboard... ---");
              // Call the private method with the underscore
              _refreshDashboard();
            } else {
              print("---[Dashboard]: API call failed. Not refreshing. ---");
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error updating inventory.'), backgroundColor: Colors.red),
                );
              }
            }
          },
        ),
      ],
    ),
  );
}*/

  void _showSnoozeOptions(int logId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Snooze for...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [5, 15, 30, 60].map((minutes) {
            return ListTile(
              title: Text('$minutes minutes'),
              onTap: () async {
                Navigator.of(context).pop();
                await _apiService.snoozeDose(logId, minutes);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  

  void _navigateAndRefresh() async {
    final result = await Navigator.push(
      context, MaterialPageRoute(builder: (context) => const ScanScreen()));
       logger.e("---[DashboardScreen]: Received pop result: $result ---");
    if (result == true) _refreshDashboard();
     logger.e("---[DashboardScreen]: Refreshing data! ---"); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: AppBar(
       // title: const Text('My Dashboard'),
       appBar: AppBar(title: Text(AppLocalizations.of(context)!.dashboardTitle),
        actions: [
          IconButton(
              icon: const Icon(Icons.inventory_2_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const InventoryScreen()),
                ).then((_) => _refreshDashboard()); // Refresh dashboard when returning
              },
            ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
          ),
        ],
      ),
      body: RefreshIndicator( // Added for easy manual refresh
        onRefresh: () async => _refreshDashboard(),
        child: FutureBuilder<List<dynamic>>(
          future: _dashboardFuture,
          builder: (context, snapshot) {
            // ... The rest of this build method is unchanged
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No medicines added yet.', style: TextStyle(fontSize: 18, color: Colors.grey)));
            }
            final allMedicines = snapshot.data!;
            final todayDoses = allMedicines.where((med) {
              final timesString = med['TimesToTake'];
              return timesString != null && timesString.isNotEmpty;
            }).toList();

            return ListView(
              padding: const EdgeInsets.only(bottom: 80),
              children: [
                if (todayDoses.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Text(AppLocalizations.of(context)!.todaysDoses, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                  ...todayDoses.map((med) => _buildTodayDoseTile(med)),
                ],
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 30, 16, 8),
                  child: Text(AppLocalizations.of(context)!.allMyMedicines, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ),
                ...allMedicines.map((med) => _buildAllMedicineTile(med)),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateAndRefresh,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatusIcon(String? status) {
    switch (status) {
      case 'Taken':
        return const Icon(Icons.check_circle, color: Colors.green, size: 30);
      case 'Missed':
        return const Icon(Icons.cancel, color: Colors.red, size: 30);
      default: // Handles "Reminded", "Snoozed", or null (upcoming)
        return const Icon(Icons.hourglass_empty, color: Colors.blue, size: 30);
    }
  }

  

  Widget _buildTodayDoseTile(Map<String, dynamic> med) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: _buildStatusIcon(med['TodayStatus']),
        title: Text(med['MedicineName'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(med['Dosage'] ?? 'No dosage set'),
        trailing: Text(
          med['TimesToTake'] != null && med['TimesToTake'].isNotEmpty ? json.decode(med['TimesToTake'])[0] : '',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        onTap: () => _navigateToDetails(med),
      ),
    ).animate().fade(duration: 500.ms).slideY(begin: 0.2, curve: Curves.easeOut); // ADD THIS
  }
  // --- THIS IS THE MAINLY UPDATED WIDGET ---
  Widget _buildAllMedicineTile(Map<String, dynamic> med) {
    // --- NEW LOGIC: Determine if the medicine is expired or low on stock ---
    bool isExpired = false;
    if (med['SoonestExpiryDate'] != null) {
      final expiryDate = DateTime.parse(med['SoonestExpiryDate']);
      final today = DateTime.now();
      final todayWithoutTime = DateTime(today.year, today.month, today.day);
      if (!expiryDate.isAfter(todayWithoutTime)) {
        isExpired = true;
      }
    }

    bool isLowOnStock = false;
    if (!isExpired && med['CurrentInventory'] <= med['LowStockThreshold']) {
      isLowOnStock = true;
    }
    // --- END OF NEW LOGIC ---

    final card = Card(
      elevation: isLowOnStock ? 4 : 0, // Give a slight lift if low on stock
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          // Show a yellow/orange border if low on stock
          color: isLowOnStock ? Colors.orangeAccent : Colors.black12,
          width: isLowOnStock ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          _getMedicineIcon(med['MedicineName']),
          color: isExpired ? Colors.red : Theme.of(context).primaryColor,
          size: 36,
        ),
        title: Text(
          med['MedicineName'],
          style: TextStyle(
            decoration: isExpired ? TextDecoration.lineThrough : TextDecoration.none,
            color: isExpired ? Colors.red : null,
          ),
        ),
        subtitle: isExpired
            ? const Text('EXPIRED', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
            : Text('Low stock warning at: ${med['LowStockThreshold']}'),
        trailing: Text('Stock: ${med['CurrentInventory']}', style: Theme.of(context).textTheme.titleLarge),
        onTap: () => _navigateToDetails(med),
      ),
    );

    // If the medicine is low on stock, apply the heartbeat animation
    if (isLowOnStock) {
      return card.animate(onPlay: (controller) => controller.repeat(reverse: true))
                 .scale(
                    duration: 1000.ms,
                    begin: const Offset(1, 1),
                    end: const Offset(1.02, 1.02),
                    curve: Curves.easeInOut,
                  );
    }

    return card;
  }
  /*Widget _buildAllMedicineTile(Map<String, dynamic> med) {
      bool isExpired = false;
      String expiryText = '';

      if (med['SoonestExpiryDate'] != null) {
    final expiryDate = DateTime.parse(med['SoonestExpiryDate']);
    final today = DateTime.now();
    final todayWithoutTime = DateTime(today.year, today.month, today.day);
    if (!expiryDate.isAfter(todayWithoutTime)) {
      isExpired = true;
    }
    expiryText = 'Expires: ${DateFormat.yMMMd().format(expiryDate)}';
  }
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      shape: RoundedRectangleBorder(
            // Show a red border if expired
          side: BorderSide(color: isExpired ? Colors.red : Colors.black12, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
      child: ListTile(
        leading: isExpired ? const Icon(Icons.warning, color: Colors.red) : null,
         title: Text(med['MedicineName'],
         style: TextStyle(
          // Show expired medicine with a strikethrough
          decoration: isExpired ? TextDecoration.lineThrough : TextDecoration.none,
          color: isExpired ? Colors.red : null,
        ),
        ),
         subtitle: isExpired ? const Text('EXPIRED', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)) : Text(expiryText),
        trailing: Text('Stock: ${med['CurrentInventory']}'),
        onTap: () => _navigateToDetails(med),
      ),
    ).animate().fade(duration: 500.ms).slideY(begin: 0.2, curve: Curves.easeOut); // ADD THIS
  }*/
  
  void _navigateToDetails(Map<String, dynamic> med) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MedicineDetailsScreen(medicine: med)),
    );
    if (result == true) {
      _refreshDashboard();
    }
  }
}*/