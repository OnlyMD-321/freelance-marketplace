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
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Define Color Scheme (Consider putting this in a separate theme file later)
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF4285F4), // Professional Blue
      brightness: Brightness.light,
      primary: const Color(0xFF4285F4),
      // secondary: const Color(0xFF34A853), // Optional: Accent Green/Teal
      background: const Color(0xFFF8F9FA), // Light Gray Background
      surface: Colors.white, // Card/Input Background
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: const Color(0xFF202124), // Dark text on background
      onSurface: const Color(0xFF202124), // Dark text on surface
      onError: Colors.white,
    );

    // Define Base Text Theme
    final baseTextTheme = ThemeData(brightness: Brightness.light).textTheme;
    final poppinsFont = GoogleFonts.poppinsTextTheme(baseTextTheme);
    final latoFont = GoogleFonts.latoTextTheme(baseTextTheme);

    // Combine fonts for a custom theme
    final customTextTheme = baseTextTheme
        .copyWith(
          displayLarge: poppinsFont.displayLarge?.copyWith(
            color: colorScheme.onSurface,
          ),
          displayMedium: poppinsFont.displayMedium?.copyWith(
            color: colorScheme.onSurface,
          ),
          displaySmall: poppinsFont.displaySmall?.copyWith(
            color: colorScheme.onSurface,
          ),
          headlineLarge: poppinsFont.headlineLarge?.copyWith(
            color: colorScheme.onSurface,
          ),
          headlineMedium: poppinsFont.headlineMedium?.copyWith(
            color: colorScheme.onSurface,
          ),
          headlineSmall: poppinsFont.headlineSmall?.copyWith(
            color: colorScheme.onSurface,
          ),
          titleLarge: poppinsFont.titleLarge?.copyWith(
            color: colorScheme.onSurface,
          ),
          titleMedium: latoFont.titleMedium?.copyWith(
            color: colorScheme.onSurface,
          ), // Lato for slightly smaller titles
          titleSmall: latoFont.titleSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          bodyLarge: latoFont.bodyLarge?.copyWith(
            color: colorScheme.onSurface,
          ),
          bodyMedium: latoFont.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          bodySmall: latoFont.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant.withOpacity(0.8),
          ),
          labelLarge: poppinsFont.labelLarge?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ), // For buttons
          labelMedium: latoFont.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          labelSmall: latoFont.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        )
        .apply(
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        );

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
              title: 'Freelance Marketplace',
              theme: ThemeData(
                colorScheme: colorScheme,
                useMaterial3: true,
                textTheme: customTextTheme, // Apply the custom text theme
                // Define default AppBar theme (optional, can be overridden)
                appBarTheme: AppBarTheme(
                  backgroundColor:
                      colorScheme.surface, // Use surface color for AppBar
                  foregroundColor: colorScheme.onSurface, // Text/icon color
                  elevation: 1.0, // Subtle shadow
                  scrolledUnderElevation: 2.0,
                  titleTextStyle: customTextTheme.titleLarge?.copyWith(
                    // Use textTheme style
                    fontWeight: FontWeight.w600,
                  ),
                  iconTheme: IconThemeData(color: colorScheme.primary),
                ),
                // Define default InputDecoration theme for TextFormFields
                inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                      color: colorScheme.outline.withOpacity(0.5),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                      color: colorScheme.outline.withOpacity(0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 1.5,
                    ), // Slightly thinner focused border
                  ),
                  labelStyle: customTextTheme.bodyMedium, // Use textTheme style
                  floatingLabelStyle: customTextTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                  ), // Use textTheme style
                  prefixIconColor: WidgetStateColor.resolveWith((
                    Set<WidgetState> states,
                  ) {
                    if (states.contains(WidgetState.focused)) {
                      return colorScheme.primary;
                    }
                    if (states.contains(WidgetState.error)) {
                      return colorScheme.error;
                    }
                    return colorScheme.onSurfaceVariant;
                  }),
                ),
                // Define default Button themes
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    textStyle:
                        customTextTheme.labelLarge, // Use textTheme style
                  ),
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    textStyle: customTextTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ), // Use textTheme style
                  ),
                ),
                // Define card theme
                cardTheme: CardTheme(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  margin: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  color: colorScheme.surface,
                ),
                // Define default Text theme (optional)
                // textTheme: GoogleFonts.latoTextTheme(ThemeData(brightness: Brightness.light).textTheme), // Example using Google Fonts
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
