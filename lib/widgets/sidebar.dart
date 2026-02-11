import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class Sidebar extends StatelessWidget {
  final User? user;
  final Function(String key) onMenuTap;
  final String selectedKey;

  const Sidebar({
    super.key,
    required this.user,
    required this.onMenuTap,
    required this.selectedKey,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // ------------------------
          // Top profile section
          // ------------------------
          Container(
            width: double.infinity,
            color: const Color(0xFFFF7B00),
            padding: const EdgeInsets.only(
              top: 40,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Text(
                    _getFirstLetter(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user?.displayName?.isNotEmpty == true
                            ? user!.displayName!
                            : 'Nearby User',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFFFF8E1),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ------------------------
          // Menu options
          // ------------------------
          Expanded(
            child: Container(
              color: const Color(0xFFFFE0B2),
              child: ListView(
                padding: EdgeInsets.zero, // very important – removes top gap
                children: [
                  _buildMenuTile('Home', Icons.home, 'home', context),
                  _buildMenuTile('My Posts', Icons.list, 'my_posts', context),
                  _buildMenuTile(
                    'Follow us on Instagram',
                    Icons.camera_alt,
                    'instagram',
                    context,
                  ),
                  _buildMenuTile('Share App', Icons.share, 'share', context),
                  _buildMenuTile('Logout', Icons.logout, 'logout', context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFirstLetter() {
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user!.displayName!.trim()[0].toUpperCase();
    }

    if (user?.email != null && user!.email!.isNotEmpty) {
      return user!.email!.trim()[0].toUpperCase();
    }

    return 'N';
  }

  Widget _buildMenuTile(
      String title,
      IconData icon,
      String key,
      BuildContext context,
      ) {
    final bool isSelected = selectedKey == key;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? const Color(0xFFFF7B00) : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? const Color(0xFFFF7B00) : null,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.white.withOpacity(0.6),
      onTap: () async {
        Navigator.pop(context);

        // ---- Instagram handling here directly
        if (key == 'instagram') {
          final Uri url =
          Uri.parse('https://www.instagram.com/nearbyhungry/');

          if (!await launchUrl(
            url,
            mode: LaunchMode.externalApplication,
          )) {
            debugPrint('Could not open Instagram');
          }
          return;
        }

        onMenuTap(key);
      },
    );
  }
}
