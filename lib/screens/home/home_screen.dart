// filepath: Mobile/freelancers_mobile_app/lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider
import '../jobs/job_list_screen.dart';
import '../applications/application_list_screen.dart'; // Assuming this is 'My Applications' view
import '../chat/conversation_list_screen.dart'; // Import ConversationListScreen
import '../profile/profile_screen.dart';
import '../../providers/chat_provider.dart'; // Import ChatProvider for badge
import '../../providers/auth_provider.dart'; // Needed for client check
import '../../providers/job_provider.dart'; // Needed to trigger search
import '../../utils/routes.dart'; // Needed for FAB navigation
import '../../models/user.dart'; // Import User model for UserType
import 'dart:async'; // Needed for debounce timer

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  // REMOVE static keyword and List initialization here
  // static const List<Widget> _widgetOptions = <Widget>[
  //   JobListScreen(), // Index 0: Jobs
  //   ApplicationListScreen(), // Index 1: Applications (Label might change based on user type)
  //   ConversationListScreen(), // Index 2: Messages
  //   ProfileScreen(), // Index 3: Profile
  // ];

  // Titles corresponding to each screen/tab for the AppBar
  // Make this dynamic too, or adjust based on _selectedIndex and user type later
  // static const List<String> _appBarTitles = <String>[
  //   'Job Feed',
  //   'My Applications', // TODO: Adjust title based on user type (e.g., 'Posted Jobs' for Client)
  //   'Messages',
  //   'Profile',
  // ];

  void _onItemTapped(int index) {
    setState(() {
      // Clear search if navigating away from Job Feed
      if (_selectedIndex == 0 && index != 0) {
        _searchController.clear();
        // Optionally trigger fetchJobs with empty search immediately
        // Provider.of<JobProvider>(context, listen: false).fetchJobs(search: '');
      }
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // Fetch initial conversations for badge count
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(context, listen: false).fetchConversations();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Debounce search calls directly triggering JobProvider
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_selectedIndex == 0) {
        // Only trigger search if on Job list screen
        Provider.of<JobProvider>(
          context,
          listen: false,
        ).fetchJobs(search: _searchController.text);
      }
    });
  }

  void _navigateToCreateJob() {
    // Logic moved from JobListScreen
    Navigator.of(context).pushNamed(AppRoutes.createJob);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final bool isClient = authProvider.currentUser?.userType == UserType.client;

    // --- Dynamically build widget options and titles ---
    final List<Widget> widgetOptions = [
      const JobListScreen(), // Index 0: Always Job Feed (might filter internally?)
      isClient
          ? const JobListScreen(
            showMyJobs: true,
          ) // Index 1 (Client): Show own jobs
          : const ApplicationListScreen(), // Index 1 (Worker): Show own applications
      const ConversationListScreen(), // Index 2: Messages
      const ProfileScreen(), // Index 3: Profile
    ];

    final List<String> appBarTitles = [
      'Job Feed', // Index 0
      isClient ? 'My Posted Jobs' : 'My Applications', // Index 1
      'Messages', // Index 2
      'Profile', // Index 3
    ];
    // --- End dynamic build ---

    // Define BottomNavigationBarItems (Consider making this dynamic based on userType later)
    final List<BottomNavigationBarItem> navBarItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.work_outline), // Outlined icon
        activeIcon: Icon(Icons.work), // Filled icon when active
        label: 'Jobs',
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.assignment_outlined), // Outlined icon
        activeIcon: const Icon(Icons.assignment), // Filled icon when active
        label:
            isClient ? 'Posted Jobs' : 'Applications', // Label remains dynamic
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.chat_bubble_outline), // Outlined icon
        activeIcon: Icon(Icons.chat_bubble), // Filled icon when active
        label: 'Messages',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline), // Outlined icon
        activeIcon: Icon(Icons.person), // Filled icon when active
        label: 'Profile',
      ),
    ];

    // Build AppBar conditionally
    AppBar appBar = AppBar(
      title:
          _selectedIndex ==
                  0 // Show search bar only on Job Feed
              ? _buildSearchField(theme)
              : Text(appBarTitles[_selectedIndex]), // Use dynamic title
      actions: [
        Consumer<ChatProvider>(
          builder: (context, chatProvider, child) {
            final unreadCount = chatProvider.unreadMessageCount;
            return IconButton(
              icon: Badge(
                // Use Badge widget (ensure badges package is added or use Stack)
                label: Text(unreadCount.toString()),
                isLabelVisible: unreadCount > 0,
                backgroundColor: colorScheme.error,
                child: Icon(
                  Icons.notifications_none,
                  color: colorScheme.primary,
                ),
              ),
              onPressed: () => _onItemTapped(2),
              tooltip: 'Notifications',
            );
          },
        ),
        const SizedBox(width: 8), // Add some padding
      ],
      // Hide back button automatically added by nested Navigators
      automaticallyImplyLeading: false,
    );

    return Scaffold(
      appBar: appBar,
      body: IndexedStack(
        index: _selectedIndex,
        children: widgetOptions,
      ), // Use dynamic widgets
      // Show FAB conditionally based on index and AuthProvider state
      floatingActionButton: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          // Correct check: Compare against the UserType enum
          final bool isClient =
              authProvider.currentUser?.userType == UserType.client;
          // FAB should show on the 'My Posted Jobs' tab for clients (index 1)
          // OR on the main Job Feed (index 0) if that's preferred? Let's stick to index 1 for now.
          final bool shouldShow = _selectedIndex == 1 && isClient;
          print(
            "[FAB Build] SelectedIndex: $_selectedIndex, IsClient: $isClient, ShouldShow: $shouldShow",
          );

          if (shouldShow) {
            return FloatingActionButton.extended(
              onPressed: _navigateToCreateJob,
              tooltip: 'Post New Job',
              icon: const Icon(Icons.add),
              label: const Text('Post Job'),
            );
          } else {
            // Return an empty container when FAB should not be shown
            return const SizedBox.shrink();
          }
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: navBarItems,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        // Styling using the theme defined in main.dart
        backgroundColor: colorScheme.surface, // Background color of the bar
        type: BottomNavigationBarType.fixed, // Keep labels visible
        selectedItemColor:
            colorScheme.primary, // Color for icon and label when selected
        unselectedItemColor: colorScheme.onSurfaceVariant.withOpacity(
          0.7,
        ), // Lighter color for unselected
        selectedFontSize: 12, // Adjust font size if needed
        unselectedFontSize: 12,
        elevation: 8.0, // Add more elevation for a distinct look
        // Use showSelectedLabels/showUnselectedLabels if needed
      ),
    );
  }

  // Helper to build the search field for AppBar
  Widget _buildSearchField(ThemeData theme) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface, // Use theme surface color
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: theme.colorScheme.onSurface),
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.search,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          suffixIcon:
              _searchController.text.isNotEmpty
                  ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      // Trigger search with empty string after clearing
                      Provider.of<JobProvider>(
                        context,
                        listen: false,
                      ).fetchJobs(search: '');
                    },
                  )
                  : null,
          hintText: 'Search jobs...',
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 10,
          ), // Adjust padding
        ),
      ),
    );
  }
}
