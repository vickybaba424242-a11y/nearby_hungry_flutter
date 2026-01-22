import 'package:flutter/material.dart';
import '../widgets/item_post.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: const [
            DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFFFFE0B2)),
              child: Text(
                'Nearby Hungry',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(title: Text('Profile')),
            ListTile(title: Text('My Posts')),
            ListTile(title: Text('Orders')),
            ListTile(title: Text('Help')),
            ListTile(title: Text('Logout')),
          ],
        ),
      ),

      appBar: AppBar(
        backgroundColor: const Color(0xFFFFE0B2),
        elevation: 0,
        title: const Text(
          'Nearby Hungry',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () {
              // TODO: Navigate to Inbox
            },
          ),
        ],
      ),

      body: Column(
        children: [
          // LOCATION STRIP
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Card(
              color: const Color(0xFF27AE60),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              elevation: 0,
              child: const SizedBox(
                height: 40,
                child: Row(
                  children: [
                    SizedBox(width: 16),
                    Icon(Icons.location_on, color: Colors.black),
                    SizedBox(width: 8),
                    Text(
                      'Checking location...',
                      style: TextStyle(color: Colors.black, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // REFERRAL STRIP
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Card(
              color: const Color(0xFFFFC77D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              elevation: 0,
              child: const SizedBox(
                height: 40,
                child: Row(
                  children: [
                    SizedBox(width: 16),
                    Icon(Icons.local_fire_department,
                        color: Color(0xFFE65100)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Share your home-cooked meals & earn! 🍽️💸',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // POSTS LIST
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: 3, // temporary mock count
              itemBuilder: (context, index) {
                return PostCard(
                  creator: 'Chef Vishal',
                  content:
                      'Fresh homemade paneer butter masala with 4 rotis.',
                  timestamp: '22 Jan 2026, 09:00 PM',
                  expireText: '10 Jan 2026, 11:30 AM',
                  showOptions: false,
                  showViews: false,
                  views: 0,
                  onChatTap: () {
                    // TODO: open chat screen
                  },
                  onViewTap: () {
                    // TODO: open post detail screen
                  },
                );
              },
            ),
          ),

          // ADMOB PLACEHOLDER
          Container(
            height: 50,
            color: Colors.grey.shade300,
            alignment: Alignment.center,
            child: const Text('AdMob Banner'),
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'My Posts'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.help_outline), label: 'Help'),
          BottomNavigationBarItem(icon: Icon(Icons.share), label: 'Share'),
        ],
      ),
    );
  }
}
