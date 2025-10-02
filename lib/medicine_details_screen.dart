// lib/medicine_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medguard/api_service.dart';
//import 'package:medicine_reminder_app/l10n/app_localizations.dart';
import 'package:medguard/set_schedule_screen.dart';

class MedicineDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> medicine;
  const MedicineDetailsScreen({super.key, required this.medicine});

  @override
  State<MedicineDetailsScreen> createState() => _MedicineDetailsScreenState();
}

class _MedicineDetailsScreenState extends State<MedicineDetailsScreen> {
  final ApiService _apiService = ApiService.instance;
  late Map<String, dynamic> _medicineData;
  //bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _medicineData = Map<String, dynamic>.from(widget.medicine);
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Please Confirm'),
          content: const Text('Are you sure you want to delete this medicine? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.of(ctx).pop();
                _deleteMedicine(context);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _deleteMedicine(BuildContext context) async {
    final bool success = await _apiService.deleteMedicine(_medicineData['UserMedicineID']);
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medicine deleted successfully'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop(true);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete medicine'), backgroundColor: Colors.red),
      );
    }
  }
  
  /*void _updateThreshold(int newThreshold) async {
      bool success = await _apiService.updateStockThreshold(
        _medicineData['UserMedicineID'],
        newThreshold,
      );
      if (success) {
        setState(() {
          _medicineData['LowStockThreshold'] = newThreshold;
           _hasChanges = true;
        });
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Threshold updated!"), backgroundColor: Colors.green,));
      }
  }*/

  void _showThresholdDialog(BuildContext context) {
    final thresholdController = TextEditingController(
      // Use the data from our state, which might have been updated
      text: _medicineData['LowStockThreshold'].toString(),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Low Stock Warning'),
        content: TextField(
          controller: thresholdController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(labelText: 'Warn me when stock is at...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final newThreshold = int.tryParse(thresholdController.text);
              if (newThreshold != null) {
                bool success = await _apiService.updateStockThreshold(
                  _medicineData['UserMedicineID'],
                  newThreshold,
                );
                if (success && mounted) {
                  // Update the local state so the UI changes immediately
                  setState(() {
                    _medicineData['LowStockThreshold'] = newThreshold;
                  });
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Threshold updated!"),
                    backgroundColor: Colors.green,
                  ));
                }
              }
              // ignore: use_build_context_synchronously
              if (mounted) Navigator.of(ctx).pop(); // Close the dialog
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
 @override
  Widget build(BuildContext context) {
    //final l10n = AppLocalizations.of(context)!;
      // --- NEW: Expiry Check Logic ---
        bool isExpired = false;
        if (_medicineData['SoonestExpiryDate'] != null) {
          final expiryDate = DateTime.parse(_medicineData['SoonestExpiryDate']);
          final today = DateTime.now();
          final todayWithoutTime = DateTime(today.year, today.month, today.day);
          if (!expiryDate.isAfter(todayWithoutTime)) {
            isExpired = true;
          }
        }
        // --- END OF NEW LOGIC ---

    // NEW: Wrap the Scaffold in PopScope to handle the back button
    return Scaffold(
      appBar: AppBar(
        title: Text(_medicineData['MedicineName'] ?? 'Medicine Details'),
      ),
       body: Padding(
        padding: const EdgeInsets.all(16.0),
       child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
              if (isExpired)
                        Card(
                          color: Colors.red[700],
                          child: const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text(
                              'This medicine has expired.',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dosage: ${widget.medicine['Dosage'] ?? 'Not set'}', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Instruction: ${widget.medicine['Instruction'] ?? 'Not set'}', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Times: ${widget.medicine['TimesToTake'] ?? 'Not set'}', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Current Stock: ${widget.medicine['CurrentInventory'] ?? 0}', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Low Stock Warning'),
              subtitle: Text('Get a reminder when stock reaches ${_medicineData['LowStockThreshold']}'),
              trailing: const Icon(Icons.edit),
              onTap: () => _showThresholdDialog(context),
            ),
            const Spacer(),
            ElevatedButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text('Edit Schedule'),
              onPressed: isExpired ? null : () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SetScheduleScreen(
                      userMedicineId: widget.medicine['UserMedicineID'],
                      existingSchedule: widget.medicine,
                    ),
                  ),
                );
                if (result == true && context.mounted) {
                  Navigator.pop(context, true);
                }
              },
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.delete_forever),
              label: const Text('Delete Medicine'),
              //label: Text(l10n.logOut), // Note: Should probably be a "Delete" key
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
      ),
    );
  }
}

/*// lib/medicine_details_screen.dart
import 'package:flutter/material.dart';
import 'package:medicine_reminder_app/api_service.dart';
import 'package:medicine_reminder_app/set_schedule_screen.dart';

class MedicineDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> medicine;
  final ApiService _apiService = ApiService.instance;

  MedicineDetailsScreen({super.key, required this.medicine});

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Please Confirm'),
          content: const Text('Are you sure you want to delete this medicine? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.of(ctx).pop(); // Close the dialog first
                _deleteMedicine(context);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _deleteMedicine(BuildContext context) async {
    final bool success = await _apiService.deleteMedicine(medicine['UserMedicineID']);
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medicine deleted successfully'), backgroundColor: Colors.green),
      );
      // Pop with a 'true' result to signal the dashboard to refresh
      Navigator.of(context).pop(true);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete medicine'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(medicine['MedicineName']),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dosage: ${medicine['Dosage']}', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Instruction: ${medicine['Instruction']}', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Times: ${medicine['TimesToTake']}', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Current Stock: ${medicine['CurrentInventory']}', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
            ),
            const Spacer(),
         ElevatedButton.icon(
  icon: const Icon(Icons.edit),
  label: const Text('Edit Schedule'),
  onPressed: () async { // Make the function async
    // Navigate to the schedule screen and pass the existing data
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SetScheduleScreen(
          userMedicineId: medicine['UserMedicineID'],
          existingSchedule: medicine, // Pass all the medicine data
        ),
      ),
    );
    // If the schedule was saved, pop this screen too to trigger a refresh on the dashboard
    if (result == true && context.mounted) {
      Navigator.pop(context, true);
    }
  },
),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.delete_forever),
              label: const Text('Delete Medicine'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
      ),
    );
  }
}*/