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

  // Use late initialization for controllers bound to initial user data
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  late TextEditingController _skillsController;
  late TextEditingController _phoneController;
  late TextEditingController _cityController;
  late TextEditingController _countryController;

  @override
  void initState() {
    super.initState();
    _currentUser =
        Provider.of<AuthProvider>(context, listen: false).currentUser;

    // Initialize controllers
    _usernameController = TextEditingController(
      text: _currentUser?.username ?? '',
    );
    _bioController = TextEditingController(text: _currentUser?.bio ?? '');
    _skillsController = TextEditingController(
      text: _currentUser?.skillsSummary ?? '',
    );
    _phoneController = TextEditingController(
      text: _currentUser?.phoneNumber ?? '',
    );
    _cityController = TextEditingController(text: _currentUser?.city ?? '');
    _countryController = TextEditingController(
      text: _currentUser?.country ?? '',
    );

    if (_currentUser == null) {
      // Handle missing user data immediately
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
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: User data not available.')),
      );
      return;
    }
    // Hide keyboard
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate() && !_isLoading) {
      setState(() {
        _isLoading = true;
      });

      // Collect updates - handle potential null values from empty text fields
      final Map<String, dynamic> updates = {};
      _addUpdate(
        updates,
        'username',
        _usernameController.text,
        _currentUser!.username,
      );
      _addUpdate(updates, 'bio', _bioController.text, _currentUser!.bio);
      _addUpdate(
        updates,
        'skillsSummary',
        _skillsController.text,
        _currentUser!.skillsSummary,
      );
      _addUpdate(
        updates,
        'phoneNumber',
        _phoneController.text,
        _currentUser!.phoneNumber,
      );
      _addUpdate(updates, 'city', _cityController.text, _currentUser!.city);
      _addUpdate(
        updates,
        'country',
        _countryController.text,
        _currentUser!.country,
      );

      if (updates.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No changes detected.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      bool success = false;
      try {
        success = await authProvider.updateUserProfile(updates);
      } catch (e) {
        success = false;
        print("Error updating profile: $e");
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Profile updated successfully!'
                : (authProvider.errorMessage ?? 'Failed to update profile.'),
          ),
          backgroundColor:
              success ? Colors.green : Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (success) {
        Navigator.of(context).pop(); // Go back on success
      }
    }
  }

  // Helper to add updates only if changed, handling nulls for empty strings
  void _addUpdate(
    Map<String, dynamic> updates,
    String key,
    String newValue,
    String? originalValue,
  ) {
    final String effectiveOriginal = originalValue ?? '';
    final String trimmedNewValue = newValue.trim();
    if (trimmedNewValue != effectiveOriginal) {
      updates[key] = trimmedNewValue.isEmpty ? null : trimmedNewValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      // Show loading/error state if initialization failed
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
          _isLoading
              ? const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
              : IconButton(
                icon: const Icon(Icons.save_outlined),
                tooltip: 'Save Changes',
                onPressed: _saveProfile,
              ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          // Use ListView for scrolling long forms
          padding: const EdgeInsets.all(16.0),
          children: <Widget>[
            _buildSectionHeader(context, 'Personal Information'),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Username cannot be empty';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '(Optional)',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 24),

            _buildSectionHeader(context, 'Location'),
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'City',
                hintText: '(Optional)',
                prefixIcon: Icon(Icons.location_city_outlined),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _countryController,
              decoration: const InputDecoration(
                labelText: 'Country',
                hintText: '(Optional)',
                prefixIcon: Icon(Icons.flag_outlined),
              ),
              textInputAction:
                  userType == UserType.worker
                      ? TextInputAction.next
                      : TextInputAction.done,
            ),
            const SizedBox(height: 24),

            // --- Worker Specific Fields ---
            if (userType == UserType.worker) ...[
              _buildSectionHeader(context, 'Professional Details'),
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: 'Bio / Tagline',
                  hintText: 'A short description about you (Optional)',
                  prefixIcon: Icon(Icons.text_snippet_outlined),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                minLines: 2,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _skillsController,
                decoration: const InputDecoration(
                  labelText: 'Skills Summary',
                  hintText: 'List your key skills (Optional)',
                  prefixIcon: Icon(Icons.star_border_outlined),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                minLines: 2,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  // Helper to build section headers
  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
