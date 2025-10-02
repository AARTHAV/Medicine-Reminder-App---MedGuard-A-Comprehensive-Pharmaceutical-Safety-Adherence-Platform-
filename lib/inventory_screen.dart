// lib/inventory_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medguard/api_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late Future<List<dynamic>> _batchesFuture;
  final ApiService _apiService = ApiService.instance;

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  void _loadBatches() {
    setState(() {
      _batchesFuture = _apiService.getUserBatches();
    });
  }

  Future<void> _markForReturn(int batchId) async {
    bool success = await _apiService.markBatchForReturn(batchId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Batch marked for return.'), backgroundColor: Colors.green),
      );
      _loadBatches(); // Refresh the list
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to mark batch.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Inventory')),
      body: FutureBuilder<List<dynamic>>(
        future: _batchesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('You have no active medicine batches.'));
          }

          final batches = snapshot.data!;
          return ListView.builder(
            itemCount: batches.length,
            itemBuilder: (context, index) {
              final batch = batches[index];
              final expiryDate = DateTime.parse(batch['ExpiryDate']);
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(batch['MedicineName'], style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text('Quantity: ${batch['Quantity']}'),
                      Text('Batch No: ${batch['BatchNo']}'),
                      Text('Expires: ${DateFormat.yMMMd().format(expiryDate)}'),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton(
                          child: const Text('Mark for Return'),
                          onPressed: () => _markForReturn(batch['UserMedicineBatchID']),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fade(duration: 500.ms).slideY(begin: 0.2, curve: Curves.easeOut); // ADD THIS
            },
          );
        },
      ),
    );
  }
}