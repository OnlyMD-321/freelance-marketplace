// filepath: Mobile/freelancers_mobile_app/lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import '../jobs/job_list_screen.dart';
import '../applications/application_list_screen.dart'; // Assuming this is 'My Applications' view
import '../chat/conversation_list_screen.dart'; // Import ConversationListScreen
import '../profile/profile_screen.dart';
// Import other necessary providers/models if needed (e.g., AuthProvider, UserType)

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Define the screens for the BottomNavigationBar
  // TODO: Conditionally include screens based on UserType (Client/Worker)
  final List<Widget> _screens = [
    const JobListScreen(), // For both users
    const ApplicationListScreen(), // Worker: My Applications, Client: Maybe 'Posted Jobs'?
    const ConversationListScreen(), // Add ConversationListScreen
    const ProfileScreen(),
  ];

  // Define the corresponding BottomNavigationBarItems
  // TODO: Conditionally set items based on UserType
  final List<BottomNavigationBarItem> _navBarItems = [
    const BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Jobs'),
    const BottomNavigationBarItem(
      icon: Icon(Icons.assignment),
      label: 'Applications',
    ), // Or 'My Jobs' for Client
    const BottomNavigationBarItem(
      icon: Icon(Icons.chat),
      label: 'Messages',
    ), // Add Messages item
    const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Get user type from AuthProvider to customize tabs if needed
    // final userType = Provider.of<AuthProvider>(context).currentUser?.userType;

    return Scaffold(
      // AppBar might be dynamic based on the selected tab
      // appBar: AppBar(title: Text('Freelancer App')), // Or set title in individual screens
      body: IndexedStack(
        // Use IndexedStack to keep state of inactive screens
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: _navBarItems,
        currentIndex: _selectedIndex,
        selectedItemColor:
            Theme.of(context).primaryColor, // Color for selected item
        unselectedItemColor: Colors.grey, // Color for unselected items
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Ensures all items are visible
      ),
    );
  }
}
