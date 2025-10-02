// lib/animated_splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:medguard/api_service.dart';
import 'package:medguard/app_theme.dart'; // Import your theme
import 'package:medguard/dashboard_screen.dart';
import 'package:medguard/login_screen.dart';
import 'package:medguard/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen> {
  @override
  void initState() {
    super.initState();
    // Wait for 3 seconds then navigate
    Timer(const Duration(milliseconds: 3000), _navigateHome);
  }

  void _navigateHome() async {
    final prefs = await SharedPreferences.getInstance();
    final bool onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
    
    Widget targetScreen;
    if (!onboardingComplete) {
      targetScreen = const OnboardingScreen();
    } else {
      final String? token = await ApiService.instance.getToken();
      targetScreen = (token != null) ? const DashboardScreen() : const LoginScreen();
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => targetScreen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // UPDATED: Use the same primary blue color from our theme
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Your app icon, fading in
            Image.asset('assets/icon.png', width: 120)
                .animate()
                .fade(duration: 1200.ms),
            
            const SizedBox(height: 30),
            
            // Your brand name with a heartbeat animation
            const Text(
              'MedGuard',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            )
            .animate(
              // Start the animation after a short delay
              delay: 500.ms, 
              // This makes the animation repeat
              onPlay: (controller) => controller.repeat(reverse: true),
            )
            // The heartbeat effect: scale up, then back down
            .scale(
              duration: 1500.ms,
              begin: const Offset(1, 1),
              end: const Offset(1.1, 1.1),
              curve: Curves.easeInOut,
            ),
          ],
        ),
      ),
    );
  }
}