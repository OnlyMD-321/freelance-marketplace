import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart'; // Import User model

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  User? _currentUser; // Make currentUser nullable

  // Controllers for editable fields
  // Initialize directly in initState
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Directly access the provider data (listen: false is crucial here)
    // This assumes AuthProvider already has the user data when this screen is pushed.
    _currentUser =
        Provider.of<AuthProvider>(context, listen: false).currentUser;

    // Initialize controllers if currentUser is available
    if (_currentUser != null) {
      _usernameController.text = _currentUser!.username;
      _bioController.text = _currentUser!.bio ?? '';
      _skillsController.text = _currentUser!.skillsSummary ?? '';
      _phoneController.text = _currentUser!.phoneNumber ?? '';
      _cityController.text = _currentUser!.city ?? '';
      _countryController.text = _currentUser!.country ?? '';
    } else {
      // Handle case where user data isn't available (should ideally not happen if navigation is correct)
      print("Error: EditProfileScreen initialized without currentUser data.");
      // Optionally show an error or pop the screen after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Error loading user data. Please try again."),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.of(context).pop();
        }
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    _skillsController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    // Ensure _currentUser is not null before proceeding
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: User data not available.')),
      );
      return;
    }
    if (_formKey.currentState!.validate() && !_isLoading) {
      setState(() {
        _isLoading = true;
      });

      // Collect updated data - only include fields that have changed
      final Map<String, dynamic> updates = {};
      // Use _currentUser! safely now because we checked for null above
      if (_usernameController.text != _currentUser!.username) {
        updates['username'] = _usernameController.text;
      }
      if (_bioController.text != (_currentUser!.bio ?? '')) {
        updates['bio'] =
            _bioController.text.isEmpty ? null : _bioController.text;
      }
      if (_skillsController.text != (_currentUser!.skillsSummary ?? '')) {
        updates['skillsSummary'] =
            _skillsController.text.isEmpty ? null : _skillsController.text;
      }
      if (_phoneController.text != (_currentUser!.phoneNumber ?? '')) {
        updates['phoneNumber'] =
            _phoneController.text.isEmpty ? null : _phoneController.text;
      }
      if (_cityController.text != (_currentUser!.city ?? '')) {
        updates['city'] =
            _cityController.text.isEmpty ? null : _cityController.text;
      }
      if (_countryController.text != (_currentUser!.country ?? '')) {
        updates['country'] =
            _countryController.text.isEmpty ? null : _countryController.text;
      }

      if (updates.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No changes detected.')));
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.updateUserProfile(updates);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); // Go back to profile screen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.errorMessage ?? 'Failed to update profile.',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Handle the case where currentUser might still be null initially
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final userType = _currentUser!.userType;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save Changes',
            onPressed: _isLoading ? null : _saveProfile,
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: <Widget>[
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Username cannot be empty';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number (Optional)',
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _cityController,
                        decoration: const InputDecoration(
                          labelText: 'City (Optional)',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _countryController,
                        decoration: const InputDecoration(
                          labelText: 'Country (Optional)',
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (userType == UserType.worker) ...[
                        TextFormField(
                          controller: _bioController,
                          decoration: const InputDecoration(
                            labelText: 'Bio (Optional)',
                            alignLabelWithHint: true,
                          ),
                          maxLines: 3,
                          minLines: 1,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _skillsController,
                          decoration: const InputDecoration(
                            labelText: 'Skills Summary (Optional)',
                            alignLabelWithHint: true,
                          ),
                          maxLines: 3,
                          minLines: 1,
                        ),
                        const SizedBox(height: 16),
                      ],
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        child: const Text('Save Changes'),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }
}
