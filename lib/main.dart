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
import 'screens/applications/application_details_screen.dart'; // Import details screen
import 'models/application.dart'; // Import Application model
import 'screens/profile/edit_profile_screen.dart'; // Import EditProfileScreen
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
        // Assume AuthProvider is independent
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // Assume JobProvider and ApplicationProvider are independent
        // (or manage auth internally/differently)
        ChangeNotifierProvider(create: (_) => JobProvider()),
        ChangeNotifierProvider(create: (_) => ApplicationProvider()),

        // ChatProvider depends on AuthProvider
        ChangeNotifierProxyProvider<AuthProvider, ChatProvider>(
          // Create needs to return an instance, use a temporary AuthProvider
          // The `update` callback will provide the real one immediately after.
          create: (_) => ChatProvider(AuthProvider()),
          update:
              (_, auth, previousChatProvider) =>
              // Create new instance or update existing one with new auth
              ChatProvider(auth),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder:
            (ctx, auth, _) => MaterialApp(
              title: 'Freelancers App',
              theme: ThemeData(
                primarySwatch: Colors.blue,
                visualDensity: VisualDensity.adaptivePlatformDensity,
              ),
              debugShowCheckedModeBanner: false,
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
                AppRoutes.applicationDetails: (ctx) {
                  // Extract the Application object from arguments
                  final application =
                      ModalRoute.of(ctx)!.settings.arguments as Application?;
                  // Handle cases where arguments might be missing or wrong type
                  if (application == null) {
                    // Navigate back or show an error screen
                    print(
                      "Error: Missing application arguments for details route.",
                    );
                    // Returning a simple error screen for now
                    return Scaffold(
                      appBar: AppBar(title: const Text("Error")),
                      body: const Center(
                        child: Text("Could not load application details."),
                      ),
                    );
                  }
                  return ApplicationDetailsScreen(application: application);
                },
                AppRoutes.editProfile:
                    (ctx) => const EditProfileScreen(), // Added route
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
