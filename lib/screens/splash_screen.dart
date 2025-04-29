import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Widget to display logo or fallback
    Widget logoWidget;
    try {
      // Attempt to load the logo
      logoWidget = Image.asset('assets/images/logo.png', height: 150);
    } catch (e) {
       print("Splash screen logo not found or failed to load: $e");
       // Fallback widget if logo fails
       logoWidget = Icon(Icons.workspaces_outline, size: 80, color: colorScheme.primary);
    }

    return Scaffold(
       backgroundColor: colorScheme.surface, // Use theme surface color
       body: Center(
         child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             logoWidget, // Display the logo or fallback
             const SizedBox(height: 40),
             CircularProgressIndicator(
               valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary), // Use primary color
             ),
             // Removed the "Loading..." text
           ],
         ),
       ),
    );
  }
}
