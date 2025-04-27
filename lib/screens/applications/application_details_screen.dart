// filepath: Mobile/freelancers_mobile_app/lib/screens/applications/application_details_screen.dart
import 'package:flutter/material.dart';

class ApplicationDetailsScreen extends StatelessWidget {
   final String applicationId; // Example: Pass application ID
  const ApplicationDetailsScreen({super.key, required this.applicationId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Application $applicationId')),
      body: Center(child: Text('Details for Application $applicationId Goes Here')),
    );
  }
}