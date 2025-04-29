// filepath: Mobile/freelancers_mobile_app/lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // For date formatting
import '../../providers/auth_provider.dart';
import '../../models/user.dart'; // Import the User model which contains UserType
import '../../utils/routes.dart'; // Import AppRoutes

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must tap button
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirm Sign Out'),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Sign Out'),
              ),
            ],
          ),
    );

    if (confirm == true && context.mounted) {
      // Check mounted before accessing provider
      await Provider.of<AuthProvider>(context, listen: false).signOut();
      // No need to manually navigate, AuthProvider state change handles it
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Consumer<AuthProvider>(
      builder: (ctx, authProvider, _) {
        final user = authProvider.currentUser;

        // Loading State
        if (authProvider.isLoading && user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        // Error State or Not Logged In
        if (user == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_off_outlined,
                    size: 60,
                    color: colorScheme.secondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    authProvider.errorMessage ?? 'Not Logged In',
                    style: textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please log in to view your profile.', // More specific message
                    style: textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  if (authProvider.errorMessage != null) ...[
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => authProvider.refreshUserProfile(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.errorContainer,
                        foregroundColor: colorScheme.onErrorContainer,
                      ),
                    ),
                  ],
                  // TODO: Add a 'Log In' button here? It might navigate to sign-in if auth state is handled properly
                ],
              ),
            ),
          );
        }

        // --- User Profile Loaded State ---
        final dateFormat = DateFormat.yMMMd(); // Format like Oct 15, 2024

        return RefreshIndicator(
          onRefresh: () => authProvider.refreshUserProfile(),
          color: colorScheme.primary,
          child: ListView(
            // Use ListView for scrollability
            padding:
                EdgeInsets.zero, // Remove default padding if header handles it
            children: [
              // --- Profile Header ---
              _ProfileHeader(user: user),

              // --- Profile Details ---
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 24.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Information',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _InfoTile(
                      icon: Icons.email_outlined,
                      title: 'Email',
                      value: user.email,
                    ),
                    if (user.phoneNumber != null)
                      _InfoTile(
                        icon: Icons.phone_outlined,
                        title: 'Phone',
                        value: user.phoneNumber!,
                      ),
                    _InfoTile(
                      icon: Icons.person_outline,
                      title: 'User Type',
                      value: user.userType.name,
                    ), // Display enum name
                    _InfoTile(
                      icon: Icons.calendar_today_outlined,
                      title: 'Member Since',
                      value: dateFormat.format(user.createdAt.toLocal()),
                    ),

                    // Location Info
                    if (user.city != null || user.country != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Location',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _InfoTile(
                        icon: Icons.location_city_outlined,
                        title: 'City',
                        value: user.city ?? 'N/A',
                      ),
                      _InfoTile(
                        icon: Icons.flag_outlined,
                        title: 'Country',
                        value: user.country ?? 'N/A',
                      ),
                    ],

                    // Worker Specific Info
                    if (user.userType == UserType.worker) ...[
                      if (user.bio != null && user.bio!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'About Me',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(user.bio!, style: textTheme.bodyMedium),
                      ],
                      if (user.skillsSummary != null &&
                          user.skillsSummary!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Skills',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(user.skillsSummary!, style: textTheme.bodyMedium),
                      ],
                      const SizedBox(height: 16),
                      const Divider(),
                      // "My Stats" action for Worker
                      ListTile(
                        leading: Icon(
                          Icons.bar_chart,
                          color: colorScheme.secondary,
                        ),
                        title: Text('My Stats', style: textTheme.bodyLarge),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Worker Stats - Not Implemented Yet',
                              ),
                            ),
                          );
                        },
                        contentPadding:
                            EdgeInsets.zero, // Align with other info if needed
                      ),
                    ],

                    const SizedBox(height: 16),
                    const Divider(),

                    // --- Actions ---
                    ListTile(
                      leading: Icon(
                        Icons.edit_outlined,
                        color: colorScheme.primary,
                      ),
                      title: Text('Edit Profile', style: textTheme.bodyLarge),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).pushNamed(AppRoutes.editProfile);
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    const Divider(),
                    ListTile(
                      leading: Icon(Icons.logout, color: colorScheme.error),
                      title: Text(
                        'Sign Out',
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.error,
                        ),
                      ),
                      onTap: () => _confirmSignOut(context),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const Divider(),
                    // --- Delete Account --- (New)
                    ListTile(
                      leading: Icon(
                        Icons.delete_forever_outlined,
                        color: colorScheme.error,
                      ),
                      title: Text(
                        'Delete Account',
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.error,
                        ),
                      ),
                      onTap: () => _confirmDeleteAccount(context),
                      contentPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(height: 24), // Bottom padding
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Confirmation Dialog for Deleting Account ---
  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // Check if mounted before showing dialog
    if (!context.mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must tap button
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Account?'),
            content: const Text(
              'Are you absolutely sure you want to delete your account? All your data (profile, jobs, applications, messages) will be permanently lost. This action cannot be undone.',
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Delete Permanently'),
              ),
            ],
          ),
    );

    if (confirm == true && context.mounted) {
      // Show loading indicator maybe?
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attempting to delete account...')),
      );
      final success = await authProvider.deleteMyAccount();

      if (context.mounted) {
        if (!success) {
          // Show error if deletion failed
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                authProvider.errorMessage ??
                    'Failed to delete account. Please try again.',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        } else {
          // If successful, AuthProvider change will trigger navigation
          // via the top-level listener (e.g., in main.dart or App widget)
          print("Account deletion initiated successfully by user.");
        }
      }
    }
  }
}

// --- Helper Widget: Profile Header ---
class _ProfileHeader extends StatelessWidget {
  final User user;
  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      color: colorScheme.primaryContainer.withOpacity(
        0.3,
      ), // Light background color
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: colorScheme.secondaryContainer,
            backgroundImage:
                user.profilePictureUrl != null
                    ? NetworkImage(user.profilePictureUrl!)
                    : null,
            child:
                user.profilePictureUrl == null
                    ? Icon(
                      Icons.person,
                      size: 50,
                      color: colorScheme.onSecondaryContainer,
                    )
                    : null,
          ),
          const SizedBox(height: 16),
          Text(
            user.username,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          // Optional: Add tagline or userType here if desired
          // const SizedBox(height: 4),
          // Text(user.userType.name, style: textTheme.titleMedium?.copyWith(color: colorScheme.secondary)),
        ],
      ),
    );
  }
}

// --- Helper Widget: Info Tile ---
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(value, style: textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
