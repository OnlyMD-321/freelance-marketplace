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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitSignIn() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate() && !_isLoading) {
      setState(() {
        _isLoading = true;
      });

      final email = _emailController.text;
      final password = _passwordController.text;

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      // signIn now returns a Map<String, dynamic>
      final result = await authProvider.signIn(email, password);

      // Check the 'success' key in the result map
      final bool success = result['success'] ?? false;
      final String? message = result['message']; // Get the message

      // Check mounted status *before* using context or setState
      if (!mounted) {
        // If the widget was disposed during the async call, do nothing further.
        // Resetting _isLoading might not be necessary if the widget is gone.
        return;
      }

      if (!success) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // Use the message from the provider if available
            content: Text(message ?? 'Sign in failed. Check credentials.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      // No 'else' needed here for success case.
      // The Consumer<AuthProvider> in main.dart will handle navigation
      // by rebuilding the MaterialApp when isAuthenticated changes.
      // We just need to ensure isLoading is handled correctly if the widget
      // is still mounted but sign-in failed.
      else {
        // If successful, the Consumer in main.dart handles navigation.
        // We might still be loading briefly while the Consumer rebuilds.
        // Setting isLoading to false might cause a flicker if done here.
        // It's generally handled by the provider state change triggering rebuild.
        // However, ensure it's false if the widget somehow remains mounted
        // without navigating immediately (though unlikely with this setup).
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _navigateToSignUp() {
    // Use named routes
    Navigator.of(context).pushNamed(AppRoutes.signUp);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Optional: Add logo back if needed
                // Image.asset('assets/images/logo.png', height: 100),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
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
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                      onPressed: _submitSignIn,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ), // Make button wider
                      child: const Text('Sign In'),
                    ),
                TextButton(
                  onPressed: _isLoading ? null : _navigateToSignUp,
                  child: const Text('Don\'t have an account? Sign Up'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
