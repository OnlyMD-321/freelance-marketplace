import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/job_provider.dart';
import 'providers/application_provider.dart';
import 'providers/chat_provider.dart'; // Import ChatProvider
import 'screens/auth/sign_in_screen.dart';
import 'screens/auth/sign_up_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/jobs/create_job_screen.dart';
import 'screens/applications/application_list_screen.dart';
import 'utils/routes.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => AuthProvider()),
        ChangeNotifierProvider(create: (ctx) => JobProvider()),
        ChangeNotifierProvider(create: (ctx) => ApplicationProvider()),
        ChangeNotifierProvider(
          create: (ctx) => ChatProvider(),
        ), // Add ChatProvider
      ],
      child: Consumer<AuthProvider>(
        builder:
            (ctx, auth, _) => MaterialApp(
              title: 'Freelancers App',
              theme: ThemeData(
                primarySwatch: Colors.blue,
                visualDensity: VisualDensity.adaptivePlatformDensity,
              ),
              // Determine the initial screen based on auth state
              home: _buildHomeScreen(auth),
              // Define named routes for navigation
              routes: {
                // Do NOT define routes handled by the 'home' property here ('/', '/signin', '/home')
                // AppRoutes.splash: (ctx) => const SplashScreen(), // Handled by home
                // AppRoutes.signIn: (ctx) => const SignInScreen(), // Handled by home
                // AppRoutes.home: (ctx) => const HomeScreen(),     // Handled by home

                // Keep other routes needed for navigation:
                AppRoutes.signUp: (ctx) => const SignUpScreen(),
                AppRoutes.createJob: (ctx) => const CreateJobScreen(),
                AppRoutes.applications: (ctx) => const ApplicationListScreen(),
                // Define other routes...
              },
              onUnknownRoute: (settings) {
                // Fallback to splash or sign-in if route is unknown
                return MaterialPageRoute(
                  builder: (ctx) => const SplashScreen(), // Or SignInScreen?
                );
              },
            ),
      ),
    );
  }

  // Helper function to decide which screen to show initially
  Widget _buildHomeScreen(AuthProvider auth) {
    if (auth.isLoading) {
      return const SplashScreen(); // Show splash while checking auth
    }
    if (auth.isAuthenticated) {
      return const HomeScreen(); // User is logged in
    }
    return const SignInScreen(); // User is not logged in
  }
}
