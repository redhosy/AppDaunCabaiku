import 'dart:async';
import 'package:flutter/material.dart';
import 'package:klasifikasi_daun/presentation/pages/onboarding/onboarding_page.dart';
import 'package:lottie/lottie.dart';

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen> {
  @override
  void initState() {
    super.initState();
    Timer(
        const Duration(seconds:18),
        () => Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (BuildContext context) => const OnboardingPage())));
  }

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      backgroundColor: Color(0xFF328E6E),
      body: SafeArea(
        child: Center(
            child: Lottie.network(
          'https://lottie.host/efe58d7d-6e37-4501-b1be-d33e12c5b8d3/uPob3jxtJm.json',
          width: 200,
          height: 200,
          fit: BoxFit.fill,
        ),
      ),
      ),
    );
  }
}
