import 'package:flutter/material.dart';
import 'package:money_tracker/calender_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                const CalendarPage()), // ✅ Navigate to CalendarPage
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color.fromARGB(255, 0, 0, 0), // ✅ Set full black background
      body: Center(
        child: Image.asset(
          'assets/logo.png', // ✅ Replace with your PNG image
          width: 150, // Adjust size if needed
          height: 300,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
