// filepath: Mobile/freelancers_mobile_app/lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart'; // Import the User model which contains UserType

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (ctx, authProvider, _) {
        final user = authProvider.currentUser;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Sign Out',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder:
                        (ctx) => AlertDialog(
                          title: const Text('Confirm Sign Out'),
                          content: const Text(
                            'Are you sure you want to sign out?',
                          ),
                          actions: [
                            TextButton(
                              child: const Text('Cancel'),
                              onPressed: () => Navigator.of(ctx).pop(false),
                            ),
                            TextButton(
                              child: const Text('Sign Out'),
                              onPressed: () => Navigator.of(ctx).pop(true),
                            ),
                          ],
                        ),
                  );
                  if (confirm == true) {
                    await Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    ).signOut();
                  }
                },
              ),
            ],
          ),
          body:
              authProvider.isLoading && user == null
                  ? const Center(child: CircularProgressIndicator())
                  : user == null
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          authProvider.errorMessage ??
                              'Could not load profile information.',
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed:
                              () =>
                                  Provider.of<AuthProvider>(
                                    context,
                                    listen: false,
                                  ).refreshUserProfile(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                  : RefreshIndicator(
                    onRefresh:
                        () =>
                            Provider.of<AuthProvider>(
                              context,
                              listen: false,
                            ).refreshUserProfile(),
                    child: ListView(
                      padding: const EdgeInsets.all(16.0),
                      children: [
                        Center(
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage:
                                user.profilePictureUrl != null
                                    ? NetworkImage(user.profilePictureUrl!)
                                    : null,
                            child:
                                user.profilePictureUrl == null
                                    ? const Icon(Icons.person, size: 50)
                                    : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            user.username,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            user.email,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(child: Chip(label: Text(user.userType.name))),
                        const SizedBox(height: 16),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.edit),
                          title: const Text('Edit Profile'),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Edit Profile - Not Implemented'),
                              ),
                            );
                          },
                        ),
                        if (user.userType == UserType.worker)
                          ListTile(
                            leading: const Icon(Icons.bar_chart),
                            title: const Text('My Stats'),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Worker Stats - Not Implemented',
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
        );
      },
    );
  }
}
