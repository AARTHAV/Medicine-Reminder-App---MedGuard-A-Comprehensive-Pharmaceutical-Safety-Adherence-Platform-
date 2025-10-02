// lib/login_screen.dart
import 'package:flutter/material.dart';
import 'package:medguard/api_service.dart';
import 'package:medguard/l10n/app_localizations.dart';
import 'package:medguard/models/api_response.dart';
import 'package:medguard/otp_screen.dart';
import 'package:logger/logger.dart';
import 'package:flutter/services.dart'; 


var logger = Logger();

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final ApiService _apiService = ApiService.instance;
  bool _isLoading = false;
// In lib/login_screen.dart, replace the _sendOtp method

void _sendOtp() async {
  if (!_formKey.currentState!.validate()) return;
  setState(() => _isLoading = true);

  final ApiResponse response = await _apiService.sendOtp(_mobileController.text);
  
  setState(() => _isLoading = false);

  if (response.success && response.data != null) {
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpScreen(
            mobileNumber: _mobileController.text,
            otpForTesting: response.data as String,
          ),
        ),
      );
    }
  } else {
    if (mounted) {
      // Show the actual error from the API
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message ?? 'Failed to send OTP.'), backgroundColor: Colors.red),
      );
    }
  }
}
  /*void _sendOtp() async {
     logger.i('Attempting to send OTP for mobile number: "${_mobileController.text}"');
    if (_mobileController.text.length < 10) {
      // Basic validation
      return;
    }*/
  /*  void _sendOtp() async {
    // NEW: We now validate the form first. If it's not valid, we stop.
    if (!_formKey.currentState!.validate())return;
    
     //{
    // return;
    //}
    setState(() => _isLoading = true);

    final String? otp = (await _apiService.sendOtp(_mobileController.text)) as String?;

    //bool success = await _apiService.sendOtp(_mobileController.text);

    setState(() => _isLoading = false);
     if (otp != null && mounted) {
    //if (success && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpScreen(mobileNumber: _mobileController.text,
           otpForTesting: otp, // Pass the OTP
          ),
        ),
      );
    } else {
      // Show an error message
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send OTP. Please try again.')),
      );
    }
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: AppBar(title: const Text('Sign In')),
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.signInTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Enter your mobile number to begin', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),
            TextFormField(
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Mobile Number',
                border: OutlineInputBorder(),
                prefixText: '+91 ',
              ),
              // NEW: This is the validation logic
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your mobile number.';
                  }
                  if (value.length != 10) {
                    return 'Mobile number must be 10 digits.';
                  }
                  return null; // Return null if the input is valid
                },
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendOtp,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Send OTP'),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}