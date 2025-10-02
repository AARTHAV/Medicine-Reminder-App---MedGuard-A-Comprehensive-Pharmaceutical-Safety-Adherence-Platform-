// lib/scan_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:medguard/models/api_response.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:medguard/api_service.dart';
import 'package:medguard/set_schedule_screen.dart';
import 'package:logger/logger.dart';

  var logger = Logger();
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ApiService _apiService = ApiService.instance;
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;

  // State variables to manually track camera controls
  bool _isTorchOn = false;
  double _zoomScale = 0.0; // Zoom scale from 0.0 to 1.0

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _showErrorDialog(String message) {
    _scannerController.stop();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Scan Error'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('TRY AGAIN'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    ).then((_) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _scannerController.start();
      }
    });
  }
// In lib/scan_screen.dart

void _handleDetection(BarcodeCapture capture) async {
  if (_isProcessing) return;
  setState(() { _isProcessing = true; });

  final String? code = capture.barcodes.first.rawValue;
  if (code != null) {
    logger.i('QR Code Detected and processing: $code');
    try {
      final data = json.decode(code);
// --- NEW: EXPIRY DATE CHECK ---
        final String expiryDateString = data['expiryDate'];
        final DateTime expiryDate = DateTime.parse(expiryDateString);
        final DateTime today = DateTime.now();
        // Set time to 00:00:00 for accurate date comparison
        final todayWithoutTime = DateTime(today.year, today.month, today.day);

        //if (expiryDate.isBefore(todayWithoutTime)) {
        if (!expiryDate.isAfter(todayWithoutTime)) {
          _showErrorDialog('This medicine is expired and cannot be added.');
          return;
        }
        // --- END OF EXPIRY CHECK ---
      // Create a map with the data from the QR code
      final medicineData = {
        'UniqueId': data['uniqueId'],
        'MedicineId': data['medicineId'],
        'BatchNo': data['batchNo'],
        'ExpiryDate': data['expiryDate'],
        'Quantity': data['quantity']
      };

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medicine found. Verifying...')),
      );

      // Call the updated ApiService method
      final ApiResponse response = await _apiService.addMedicineFromScan(medicineData);

      if (response.success && mounted) {
        final int userMedicineBatchId = response.data['userMedicineBatchId'];
        // For now, we just need to know the ID for the schedule screen.
        // In a future step, we would pass the full batch details.
        // ignore: unused_local_variable
        final scheduleSaved = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SetScheduleScreen(userMedicineId: userMedicineBatchId)), // Note: This is now a BatchID
        );

       /* if (scheduleSaved == true && mounted) {
          Navigator.pop(context, true);
        } else {
          _scannerController.start();
          setState(() => _isProcessing = false);
        }
      } else if (mounted) {
        // Show the specific error message from the API
        _showErrorDialog(response.message ?? 'An unknown error occurred.');
      }
    } catch (e) {
      _showErrorDialog('The scanned QR code has an invalid format or is missing data.');
    }
  } else {
    setState(() => _isProcessing = false);
  }
}*/
if (mounted) {
            Navigator.pop(context, true);
          }
        } else if (mounted) {
          _showErrorDialog(response.message ?? 'An unknown error occurred.');
        }
      } catch (e) {
        _showErrorDialog('The scanned QR code has an invalid format or is missing data.');
      }
    } else {
       setState(() => _isProcessing = false);
    }
  }
  /*void _handleDetection(BarcodeCapture capture) async {
    if (_isProcessing) return;
    setState(() { _isProcessing = true; });

    final String? code = capture.barcodes.first.rawValue;
    if (code != null) {
      logger.i('QR Code Detected and processing: $code');
      try {
        final data = json.decode(code);
        final int medicineId = data['medicineId'];
        final int quantity = data['quantity'];
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medicine found. Adding to your list...')),
        );
        
        final int? userMedicineId = await _apiService.addMedicineFromScan(medicineId, quantity);
        
        if (userMedicineId != null && mounted) {
          final scheduleSaved = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SetScheduleScreen(userMedicineId: userMedicineId)),
          );
          if (scheduleSaved == true && mounted) {
            Navigator.pop(context, true);
          } else {
            _scannerController.start();
            setState(() => _isProcessing = false);
          }
        } else if (mounted) {
          _showErrorDialog('Failed to add this medicine. The medicine might not exist in the system.');
        }
      } catch (e) {
        _showErrorDialog('The scanned QR code has an invalid format.');
      }
    } else {
       setState(() => _isProcessing = false);
    }
  }*/

  // Method to toggle the torch and update our state
  void _toggleTorch() {
    _scannerController.toggleTorch();
    setState(() {
      _isTorchOn = !_isTorchOn;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Medicine QR Code'),
        actions: [
          IconButton(
            color: Colors.white,
            icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleTorch,
          ),
        ],
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleDetection,
          ),
          ColorFiltered(
            // ignore: deprecated_member_use
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.srcOut),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    height: 250,
                    width: 250,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Slider(
              value: _zoomScale,
              onChanged: (value) {
                setState(() {
                  _zoomScale = value;
                });
                _scannerController.setZoomScale(value);
              },
            ),
          ),
        ],
      ),
    );
  }
}