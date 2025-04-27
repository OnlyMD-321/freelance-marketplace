import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        // You can customize this further, e.g., add your logo
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Optional: Add your logo
            // Make sure 'assets/images/logo.png' exists and is declared in pubspec.yaml
            Image.asset('assets/images/logo.png', height: 120),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
            const SizedBox(height: 10),
            const Text("Loading..."),
          ],
        ),
      ),
    );
  }
}
