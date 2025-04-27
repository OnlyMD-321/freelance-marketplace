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
              initialRoute:
                  auth.isLoading
                      ? AppRoutes.splash
                      : auth.isAuthenticated
                      ? AppRoutes.home
                      : AppRoutes.signIn,
              routes: {
                AppRoutes.splash: (ctx) => const SplashScreen(),
                AppRoutes.signIn: (ctx) => const SignInScreen(),
                AppRoutes.signUp: (ctx) => const SignUpScreen(),
                AppRoutes.home: (ctx) => const HomeScreen(),
                AppRoutes.createJob: (ctx) => const CreateJobScreen(),
                AppRoutes.applications: (ctx) => const ApplicationListScreen(),
              },
              onUnknownRoute: (settings) {
                return MaterialPageRoute(
                  builder: (ctx) => const SplashScreen(),
                );
              },
            ),
      ),
    );
  }
}
