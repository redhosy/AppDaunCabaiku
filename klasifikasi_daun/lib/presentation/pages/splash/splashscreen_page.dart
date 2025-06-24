import 'dart:async';
import 'package:flutter/material.dart';
import 'package:klasifikasi_daun/presentation/pages/onboarding/onboarding_page.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Splashscreen extends StatefulWidget {
  final bool onboardingDone;

  const Splashscreen({super.key, required this.onboardingDone});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 3), () async {
      if (!widget.onboardingDone) {
        Navigator.pushReplacementNamed(context, '/onboarding');
        return;
      }

      // Misal cek token login dari SharedPreferences
      final isLoggedIn = await checkIfLoggedIn(); // buat method cek token

      if (isLoggedIn) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

/// Cek token login dari SharedPreferences
  Future<bool> checkIfLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null && token.isNotEmpty) {
        print('Token ditemukan: ${token.substring(0, 20)}...');
        return true;
      }
    } catch (e) {
      debugPrint('Error cek token login: $e');
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF328E6E),
      body: SafeArea(
        child: Center(
          child: Lottie.asset(
            'assets/animasilogo.json',
            width: 200,
            height: 200,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
