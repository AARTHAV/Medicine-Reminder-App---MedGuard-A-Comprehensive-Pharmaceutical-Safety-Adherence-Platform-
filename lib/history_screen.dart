// lib/history_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medguard/api_service.dart';
import 'package:collection/collection.dart';
import 'package:medguard/l10n/app_localizations.dart'; // Add this package
import 'package:flutter_animate/flutter_animate.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<Map<DateTime, List<dynamic>>> _groupedHistoryFuture;
  final ApiService _apiService = ApiService.instance;

  @override
  void initState() {
    super.initState();
    _groupedHistoryFuture = _fetchAndGroupHistory();
  }

  Future<Map<DateTime, List<dynamic>>> _fetchAndGroupHistory() async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 30));

    final historyList = await _apiService.getDoseHistory(startDate, endDate);

    // Group the flat list by date using the 'collection' package
    final groupedData = groupBy(historyList, (dynamic dose) {
      final scheduledDate = DateTime.parse(dose['ScheduledTime']);
      return DateTime(scheduledDate.year, scheduledDate.month, scheduledDate.day);
    });

    return groupedData;
  }

  Widget _buildStatusIcon(String status) {
    switch (status) {
      case 'Taken':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'Missed':
        return const Icon(Icons.cancel, color: Colors.red);
      case 'Reminded':
        return const Icon(Icons.notifications, color: Colors.orange);
      default:
        return const Icon(Icons.help_outline, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
      final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      //appBar: AppBar(title: const Text('Dose History')),
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.doseHistoryTitle)),
      body: FutureBuilder<Map<DateTime, List<dynamic>>>(
        future: _groupedHistoryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No dose history found.'));
          }

          final groupedHistory = snapshot.data!;
          final sortedDates = groupedHistory.keys.toList()..sort((a, b) => b.compareTo(a));

          return ListView.builder(
            itemCount: sortedDates.length,
            itemBuilder: (context, index) {
              final date = sortedDates[index];
              final dosesForDay = groupedHistory[date]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Text(
                      DateFormat.yMMMMEEEEd().format(date), // e.g., "Friday, September 22, 2025"
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  ...dosesForDay.map((dose) {
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: _buildStatusIcon(dose['Status']),
                        title: Text(dose['MedicineName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Scheduled: ${DateFormat.jm().format(DateTime.parse(dose['ScheduledTime']))}'),
                        //trailing: Text(dose['Status']),
                        trailing: Text(dose['Status'] == 'Taken' ? l10n.statusTaken : l10n.statusReminded),
                      ),
                    ).animate().fade(duration: 500.ms).slideY(begin: 0.2, curve: Curves.easeOut); // ADD THIS
                  }),
                ],
              );
            },
          );
        },
      ),
    );
  }
}