import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/inbox_page.dart';

import '../screens/post_detail_page.dart';
import '../screens/add_post_page.dart';
import '../screens/chat_page.dart';
import '../screens/help_support_page.dart';
import '../models/post.dart';
import '../utils/location_helper.dart';
import '../widgets/post_card.dart';
import '../widgets/sidebar.dart';

class HomePage extends StatefulWidget {
  final bool showOnlyMyPosts;
  const HomePage({super.key, this.showOnlyMyPosts = false});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  double? userLat;
  double? userLng;

  bool showOnlyMyPosts = false;
  List<Post> posts = [];
  bool loadingPosts = true;
  int unreadChats = 0;

  @override
  void initState() {
    super.initState();
    showOnlyMyPosts = widget.showOnlyMyPosts;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startLocationFlow();
    });

    _listenUnreadChats();
  }

  // ---------------- Location FLOW ----------------

  Future<void> _startLocationFlow() async {
    await _askLocationFirstTimeOnly();
    await _ensureLocationAndLoad();
  }

  Future<void> _askLocationFirstTimeOnly() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyAsked = prefs.getBool('locationAsked') ?? false;

    if (alreadyAsked) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }

    await prefs.setBool('locationAsked', true);
  }

  Future<void> _ensureLocationAndLoad() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Location required'),
          content:
          const Text('Please turn ON location to see nearby food posts.'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await Geolocator.openLocationSettings();
              },
              child: const Text('Open settings'),
            ),
          ],
        ),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Permission required'),
          content: const Text(
            'Please allow location permission from settings to see nearby food.',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await Geolocator.openAppSettings();
              },
              child: const Text('Open settings'),
            ),
          ],
        ),
      );
      return;
    }

    if (permission == LocationPermission.denied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission is required')),
      );
      return;
    }

    await _initLocation();
    _loadPosts();
  }

  Future<void> _initLocation() async {
    final position = await LocationHelper.getCurrentLocation(context);
    if (position != null) {
      setState(() {
        userLat = position.latitude;
        userLng = position.longitude;
      });
      _updateUserLocationInFirestore(position.latitude, position.longitude);
    }
  }

  Future<void> _updateUserLocationInFirestore(double lat, double lng) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'latitude': lat,
        'longitude': lng,
      });
    }
  }

  // ---------------- Posts ----------------

  void _loadPosts() {
    final userId = _auth.currentUser?.uid ?? '';

    _firestore
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      final freshPosts = <Post>[];

      for (var doc in snapshot.docs) {
        final post = Post.fromDocument(doc);
        final expireAt = post.expireAt?.toDate().millisecondsSinceEpoch;

        if (expireAt != null &&
            expireAt < DateTime.now().millisecondsSinceEpoch) {
          doc.reference.delete();
          continue;
        }

        if (showOnlyMyPosts) {
          if (post.creatorId == userId) freshPosts.add(post);
        } else {
          if (post.creatorId != userId &&
              userLat != null &&
              userLng != null &&
              _distanceInKm(
                userLat!,
                userLng!,
                post.latitude,
                post.longitude,
              ) <=
                  5.0) {
            freshPosts.add(post);
          }
        }
      }

      setState(() {
        posts = freshPosts;
        loadingPosts = false;
      });
    });
  }

  // ---------------- Chats ----------------

  void _listenUnreadChats() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .listen((snapshot) {
      int unread = 0;
      for (var doc in snapshot.docs) {
        final key = 'unreadCount_$userId';
        final count = (doc.data()[key] ?? 0) as int;
        if (count > 0) unread += 1;
      }

      setState(() {
        unreadChats = unread;
      });
    });
  }

  // ---------------- Helpers ----------------

  double _distanceInKm(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180);

  String _formatTime(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.year} "
        "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";
  }

  // ---------------- UI actions ----------------

  Future<void> _openChatWithChef(Post post) async {
    final myId = _auth.currentUser!.uid;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          chefId: post.creatorId,
          customerId: myId,
          chefName: post.creatorName,
        ),
      ),
    );
  }

  void _showPostOptions(Post post) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text("Edit"),
              onTap: () {
                Navigator.pop(context);
                _openAddPostModal(postToEdit: post);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text("Delete"),
              onTap: () async {
                Navigator.pop(context);
                await _firestore.collection('posts').doc(post.id).delete();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openAddPostModal({Post? postToEdit}) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (_) => Padding(
        padding:
        EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: AddPostBottomSheet(
          postToEdit: postToEdit,
          onPostCreated: () {
            setState(() {
              showOnlyMyPosts = true;
            });
            _loadPosts();
          },
        ),
      ),
    );
  }

  void _logout() async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _openInstagram() async {
    const url = 'https://www.instagram.com/nearbyhungry/';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void _shareApp() {
    const link =
        "https://play.google.com/store/apps/details?id=com.vishal.nearbyhungry";
    Share.share("Download Nearby Hungry:\n$link");
  }

  // ---------------- Build ----------------

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFFFE0B2),
      drawer: Sidebar(
        user: user,
        selectedKey: showOnlyMyPosts ? 'my_posts' : 'home',
        onMenuTap: (key) {
          switch (key) {
            case 'home':
              setState(() => showOnlyMyPosts = false);
              _loadPosts();
              break;
            case 'my_posts':
              setState(() => showOnlyMyPosts = true);
              _loadPosts();
              break;
            case 'instagram':
              _openInstagram();
              break;
            case 'share':
              _shareApp();
              break;
            case 'logout':
              _logout();
              break;
          }
        },
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFE0B2),
        title: Text(
          'Nearby Hungry',
          style: GoogleFonts.balooBhai2(color: Colors.black),
        ),
        actions: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.message, color: Colors.black),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const InboxPage(),
                    ),
                  );
                },
              ),
              if (unreadChats > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: CircleAvatar(
                    radius: 9,
                    backgroundColor: Colors.red,
                    child: Text(
                      unreadChats > 99 ? '99+' : unreadChats.toString(),
                      style: const TextStyle(
                          fontSize: 10, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // ✅ UPDATED STRIP (green when ON, red when OFF)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 40,
            decoration: BoxDecoration(
              color: userLat != null
                  ? const Color(0xFF27AE60)
                  : const Color(0xFFE74C3C),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    userLat != null
                        ? 'Your location (Auto)'
                        : 'Location is not ON',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFC77D),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.local_fire_department, color: Color(0xFFE65100)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Share your home-cooked meals & earn! 🍽️💸',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
          ),
          Expanded(
            child: loadingPosts
                ? const Center(child: CircularProgressIndicator())
                : posts.isEmpty
                ? const Center(child: Text('No posts nearby'))
                : ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                final myId = _auth.currentUser!.uid;
                final isOwnPost = post.creatorId == myId;
                final timeText = post.timestamp != null
                    ? _formatTime(post.timestamp!.toDate())
                    : "Unknown";
                final expireText = post.expireAt != null
                    ? _formatTime(post.expireAt!.toDate())
                    : null;

                return PostCard(
                  post: post,
                  isOwnPost: isOwnPost,
                  timeText: timeText,
                  expireText: isOwnPost ? expireText : null,
                  onViewPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => DraggableScrollableSheet(
                        initialChildSize: 0.85,
                        minChildSize: 0.4,
                        maxChildSize: 0.95,
                        builder:
                            (context, scrollController) {
                          return PostDetailPage(
                            postId: post.id,
                            scrollController: scrollController,
                          );
                        },
                      ),
                    );
                  },
                  onChatPressed: () => _openChatWithChef(post),
                  onOptionsPressed: () => _showPostOptions(post),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFFFFF8E1),
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.black,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.list), label: 'My Posts'),
          BottomNavigationBarItem(
              icon: Icon(Icons.add_box), label: 'Add Post'),
          BottomNavigationBarItem(
              icon: Icon(Icons.help), label: 'Help'),
          BottomNavigationBarItem(
              icon: Icon(Icons.share), label: 'Share'),
        ],
        currentIndex: showOnlyMyPosts ? 1 : 0,
        onTap: (index) {
          switch (index) {
            case 0:
              setState(() => showOnlyMyPosts = false);
              _loadPosts();
              break;
            case 1:
              setState(() => showOnlyMyPosts = true);
              _loadPosts();
              break;
            case 2:
              _openAddPostModal();
              break;
            case 3:
              showDialog(
                  context: context,
                  builder: (_) => const HelpSupportPage());
              break;
            case 4:
              _shareApp();
              break;
          }
        },
      ),
    );
  }
}
