// lib/otp_screen.dart
import 'package:flutter/material.dart';
import 'package:medguard/api_service.dart';
import 'package:medguard/dashboard_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:logger/logger.dart';
import 'package:medguard/models/api_response.dart';
//import 'package:medicine_reminder_app/l10n/app_localizations.dart';

var logger = Logger();

class OtpScreen extends StatefulWidget {
  final String mobileNumber;
  final String otpForTesting; // Accepts the OTP for display
  const OtpScreen({super.key, required this.mobileNumber, required this.otpForTesting,});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  final ApiService _apiService = ApiService.instance;
  bool _isLoading = false;

Future<void> _setupNotifications() async {
  final messaging = FirebaseMessaging.instance;
  
  // Request permission from the user (for iOS and modern Android)
  await messaging.requestPermission();

  // Get the unique FCM token for this device
  final fcmToken = await messaging.getToken();
  
  logger.i('--- FCM TOKEN ---');
  logger.i(fcmToken);

  if (fcmToken != null) {
    await _apiService.saveFcmToken(fcmToken);
  }
}
 @override
  void initState() {
    super.initState();
    // Auto-fill the text field with the OTP for easy testing
    _otpController.text = widget.otpForTesting;
  }
 
 //17-09-2025
  /*void _verifyOtp() async {
  if (_otpController.text.length != 6) return;

  setState(() => _isLoading = true);

  try {
    final responseData = await _apiService.verifyOtp(widget.mobileNumber, _otpController.text);

    if (responseData != null && responseData.containsKey('AuthToken')) {
      // --- SUCCESS PATH ---
      final token = responseData['AuthToken'];
      await _apiService.saveToken(token);
      await _setupNotifications();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } else {
      // --- FAILURE PATH ---
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid OTP. Please try again.')),
        );
      }
    }
  } finally {
    // This 'finally' block ensures that the loading indicator is always turned off,
    // whether the API call succeeded or failed.
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}*/

// In lib/otp_screen.dart, replace the _verifyOtp method

/*void _verifyOtp() async {
  if (_otpController.text.length != 6) return;
  setState(() => _isLoading = true);

  final ApiResponse response = (await _apiService.verifyOtp(widget.mobileNumber, _otpController.text)) as ApiResponse;

  if (response.success && mounted) {
    await _apiService.saveToken(response.data['AuthToken']);
    await _setupNotifications();
    // ignore: use_build_context_synchronously
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const DashboardScreen()),
      (route) => false,
    );
  } else {
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message ?? 'Invalid OTP.'), backgroundColor: Colors.red),
      );
    }
  }
}*/
// In lib/otp_screen.dart
void _verifyOtp() async {
  if (_otpController.text.length != 6) return;

  setState(() => _isLoading = true);

  try {
    final ApiResponse response = await _apiService.verifyOtp(widget.mobileNumber, _otpController.text);

    if (response.success && mounted) {
      // Success: Save the token and navigate
      await _apiService.saveToken(response.data['AuthToken']);
      await _setupNotifications();
      // ignore: use_build_context_synchronously
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
        (route) => false,
      );
    } else if (mounted) {
      // Failure: Show the error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message ?? 'An unknown error occurred.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    // This 'finally' block GUARANTEES this code will run,
    // even if we navigate to a new screen in the 'try' block.
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      //appBar: AppBar(title: Text(AppLocalizations.of(context)!.sendOTP)),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Enter the 6-digit code sent to ${widget.mobileNumber}', textAlign: TextAlign.center),
             const SizedBox(height: 20),
            // Display the OTP on screen for easy testing
            Text(
              'For Testing, OTP is: ${widget.otpForTesting}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'OTP',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Verify & Proceed'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}