// filepath: Mobile/freelancers_mobile_app/lib/screens/auth/sign_in_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider
import '../../utils/routes.dart'; // Import AppRoutes for navigation
import '../../providers/auth_provider.dart'; // Import AuthProvider

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false; // State for password visibility

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitSignIn() async {
    print("[_SignInScreen] _submitSignIn called."); // Added log
    // Hide keyboard
    FocusScope.of(context).unfocus();

    final isFormValid = _formKey.currentState?.validate() ?? false;
    print(
      "[_SignInScreen] Form valid: $isFormValid, isLoading: $_isLoading",
    ); // Added log

    // Use the local variable for validation check
    if (isFormValid && !_isLoading) {
      print(
        "[_SignInScreen] Form valid and not loading. Setting isLoading=true.",
      ); // Added log
      setState(() {
        _isLoading = true;
      });

      final email = _emailController.text;
      final password = _passwordController.text;
      print("[_SignInScreen] Email: $email"); // Added log

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      print("[_SignInScreen] Calling authProvider.signIn..."); // Added log
      // signIn now returns a Map<String, dynamic>
      final result = await authProvider.signIn(email, password);
      print("[_SignInScreen] authProvider.signIn result: $result"); // Added log

      // Check the 'success' key in the result map
      final bool success = result['success'] ?? false;
      final String? message = result['message']; // Get the message
      print(
        "[_SignInScreen] Sign in success: $success, message: $message",
      ); // Added log

      // Check mounted status *before* using context or setState
      if (!mounted) {
        print(
          "[_SignInScreen] Widget not mounted after async call. Returning.",
        ); // Added log
        // If the widget was disposed during the async call, do nothing further.
        // Resetting _isLoading might not be necessary if the widget is gone.
        return;
      }

      if (!success) {
        print("[_SignInScreen] Sign in failed. Showing SnackBar."); // Added log
        setState(() {
          _isLoading = false;
        });
        // Use a less intrusive error display if possible, but SnackBar is okay
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message ?? 'Sign in failed. Check credentials.'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating, // Make it float
            ),
          );
        }
      } else {
        print(
          "[_SignInScreen] Sign in successful. Letting AuthProvider handle navigation.",
        ); // Added log
        // If successful, the Consumer in main.dart handles navigation.
        // We might still be loading briefly while the Consumer rebuilds.
        // Setting isLoading to false might cause a flicker if done here.
        // It's generally handled by the provider state change triggering rebuild.
        // However, ensure it's false if the widget somehow remains mounted
        // without navigating immediately (though unlikely with this setup).
        if (mounted) {
          // Keep isLoading true until the navigation actually happens via the provider
          // Setting it false here might cause a flicker back to the button
          // setState(() {
          //   _isLoading = false;
          // });
        }
      }
    } else {
      print(
        "[_SignInScreen] Form invalid or already loading. Submit aborted.",
      ); // Added log
    }
  }

  void _navigateToSignUp() {
    // Use named routes for better practice
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.signUp,
    ); // Use pushReplacement if you don't want users going back to sign in
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      // Remove AppBar for a cleaner auth screen look
      // appBar: AppBar(title: const Text('Sign In')),
      backgroundColor: colorScheme.surface, // Use theme background
      body: SafeArea(
        // Ensure content avoids notches/system areas
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0), // Increased padding
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment:
                    CrossAxisAlignment.stretch, // Stretch children horizontally
                children: <Widget>[
                  // Optional: Add logo or App Name Title
                  Text(
                    'Welcome Back',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to your account',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40), // Increased spacing
                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: colorScheme.primary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          12.0,
                        ), // Rounded corners
                        borderSide: BorderSide(color: colorScheme.outline),
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
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: colorScheme.surface, // Subtle background
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty ||
                          !value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                    textInputAction:
                        TextInputAction.next, // Go to password field
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        // color: colorScheme.primary, // Handled by InputDecorationTheme
                      ),
                      // Add suffix icon for visibility toggle
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color:
                              colorScheme
                                  .onSurfaceVariant, // Adjust color as needed
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      // border, enabledBorder, focusedBorder, filled, fillColor - Handled by InputDecorationTheme
                    ),
                    obscureText: !_isPasswordVisible, // Toggle based on state
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.done, // Submit form
                    onFieldSubmitted:
                        (_) => _isLoading ? null : _submitSignIn(),
                  ),
                  // Optional: Add "Forgot Password?" button here later
                  const SizedBox(height: 32),

                  // Sign In Button / Loading Indicator
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                        onPressed: _submitSignIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              colorScheme.primary, // Use primary color
                          foregroundColor:
                              colorScheme.onPrimary, // Text color on button
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ), // Taller button
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              12.0,
                            ), // Match text fields
                          ),
                          textStyle: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: const Text('Sign In'),
                      ),
                  const SizedBox(height: 24), // Spacing before sign up link
                  // Sign Up Navigation
                  Row(
                    // Center the text button
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      TextButton(
                        onPressed: _isLoading ? null : _navigateToSignUp,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                          ), // Reduce padding
                          foregroundColor:
                              colorScheme.primary, // Make link stand out
                          textStyle: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: const Text('Sign Up'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
