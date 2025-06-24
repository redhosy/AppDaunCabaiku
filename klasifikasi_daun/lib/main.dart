import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:klasifikasi_daun/presentation/pages/auth/forgot_password_page.dart';
import 'package:klasifikasi_daun/presentation/pages/auth/login_page.dart';
import 'package:klasifikasi_daun/presentation/pages/auth/register_page.dart';
import 'package:klasifikasi_daun/presentation/pages/home/home_page.dart';
import 'package:klasifikasi_daun/presentation/pages/onboarding/onboarding_page.dart';
import 'package:klasifikasi_daun/presentation/pages/splash/splashscreen_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool onboardingDone = prefs.getBool('onboarding_done') ?? false;
  runApp(MyApp(onboardingDone: onboardingDone));
}

class MyApp extends StatelessWidget {
  final bool onboardingDone;
  const MyApp({super.key, required this.onboardingDone});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // initialRoute: onboardingDone ? '/login' : '/onboarding',
      title: 'ChapsiCheck',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF3F7D58)),
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: Splashscreen(onboardingDone: onboardingDone),
      routes: {
      '/onboarding':(context)=> const OnboardingPage(),
      '/login':(context)=> LoginPage(),
      '/register':(context)=> RegisterPage(),
      '/forgot':(context)=> ForgotPasswordPage(),
      '/home':(context)=> HomePage(),
      },
    );
  }
}