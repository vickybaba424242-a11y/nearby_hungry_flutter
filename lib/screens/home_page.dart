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
  import 'dart:async';
  import '../screens/post_detail_page.dart';
  import '../screens/add_post_page.dart';
  import '../screens/chat_page.dart';
  import '../screens/help_support_page.dart';
  import '../models/post.dart';
  import '../utils/location_helper.dart';
  import '../widgets/post_card.dart';
  import '../widgets/sidebar.dart';
  import 'package:google_sign_in/google_sign_in.dart';
  import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
  import 'package:firebase_messaging/firebase_messaging.dart';
  import 'package:flutter/rendering.dart';
  import '../screens/rewards_program_page.dart';
  import '../screens/refer_earn_page.dart';

  class HomePage extends StatefulWidget {
    final bool showOnlyMyPosts;
    const HomePage({super.key, this.showOnlyMyPosts = false});

    @override
    State<HomePage> createState() => _HomePageState();
  }

  class _HomePageState extends State<HomePage> {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final TextEditingController _searchController = TextEditingController();
    final ScrollController _scrollController = ScrollController();

    bool _showTopSection = true;
    bool _showAppBar = true;
    List<Post> allPosts = [];
    List<Post> filteredPosts = [];

    StreamSubscription? _postsSubscription;

    double? userLat;
    double? userLng;

    bool showOnlyMyPosts = false;
    List<Post> posts = [];
    bool loadingPosts = true;
    int unreadChats = 0;

    String selectedCategory = "All";

    void _filterPosts() {
      final search = _searchController.text.trim().toLowerCase();

      filteredPosts = allPosts.where((post) {

        final content =
        "${post.text} ${post.creatorName}".toLowerCase();

        final matchesSearch =
            search.isEmpty ||
                content.contains(search);

        final matchesCategory =
            selectedCategory == "All" ||
                content.contains(selectedCategory.toLowerCase());

        return matchesSearch && matchesCategory;

      }).toList();

      if (mounted) {
        setState(() {});
      }
    }

    @override
    void initState() {
      super.initState();
      _scrollController.addListener(() {
        if (_scrollController.position.userScrollDirection ==
            ScrollDirection.reverse) {

          if (_showAppBar) {
            setState(() {
              _showAppBar = false;
            });
          }
        }

        if (_scrollController.position.userScrollDirection ==
            ScrollDirection.forward) {

          if (!_showAppBar) {
            setState(() {
              _showAppBar = true;
            });
          }
        }
      });
      showOnlyMyPosts = widget.showOnlyMyPosts;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;

        await _startLocationFlow();

        if (!mounted) return;

        await _requestNotificationPermission();
      });

      _listenUnreadChats();
    }

    @override
    void dispose() {
      _postsSubscription?.cancel();
      _scrollController.dispose();
      super.dispose();
    }

    Widget _categoryItem(
        String title,
        String imagePath,
        ) {
      final isSelected = selectedCategory == title;

      return GestureDetector(
        onTap: () {
          setState(() {
            selectedCategory = title;
          });

          if (title != "All") {
            _searchController.text = title;
          } else {
            _searchController.clear();
          }

          _filterPosts();
        },
        child: Container(
          width: 80,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFF94449)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  backgroundImage: AssetImage(imagePath),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                  isSelected ? FontWeight.bold : FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Future<void> _requestNotificationPermission() async {
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint("🔔 HomePage permission status: ${settings.authorizationStatus}");

      try {
        String? apnsToken = await messaging.getAPNSToken();
        int retry = 0;

        while (apnsToken == null && retry < 3) {
          await Future.delayed(const Duration(milliseconds: 800));
          apnsToken = await messaging.getAPNSToken();
          retry++;
        }

        debugPrint("🍎 HomePage APNS token: $apnsToken");

        if (apnsToken == null) {
          debugPrint(
            "⚠️ APNS token not ready in HomePage, skipping FCM token fetch",
          );
          return;
        }

        final token = await messaging.getToken();
        debugPrint("🔑 HomePage FCM token: $token");

        final user = _auth.currentUser;
        if (user != null && token != null) {
          await _firestore.collection('users').doc(user.uid).set({
            'fcmToken': token,
          }, SetOptions(merge: true));
        }
      } catch (e, st) {
        debugPrint("❌ HomePage notification setup failed: $e");
        debugPrintStack(stackTrace: st);
      }
    }

    Future<void> _startLocationFlow() async {
      debugPrint("🚀 Starting location flow...");
      await _askLocationFirstTimeOnly();
      await _ensureLocationAndLoad();
    }

    Future<void> _askLocationFirstTimeOnly() async {
      final prefs = await SharedPreferences.getInstance();
      final alreadyAsked = prefs.getBool('locationAsked') ?? false;
      debugPrint("📍 Location asked before: $alreadyAsked");

      if (alreadyAsked) return;

      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint("📍 Initial location permission: $permission");

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        debugPrint("📍 Permission after request: $permission");
      }

      await prefs.setBool('locationAsked', true);
    }

    Future<void> _ensureLocationAndLoad() async {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint("📍 Location service enabled: $serviceEnabled");

      if (!serviceEnabled) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Location required'),
            content: const Text(
              'Please turn ON location to see nearby food posts.',
            ),
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
      debugPrint("📍 Current permission before load: $permission");

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        debugPrint("📍 Permission after second request: $permission");
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
      debugPrint("📍 initLocation called");

      final position = await LocationHelper.getCurrentLocation(context);
      if (position != null) {
        debugPrint(
          "📍 User location: ${position.latitude}, ${position.longitude}",
        );

        setState(() {
          userLat = position.latitude;
          userLng = position.longitude;
        });

        await _updateUserLocationInFirestore(
          position.latitude,
          position.longitude,
        );
      } else {
        debugPrint("❌ LocationHelper returned null position");
      }
    }

    Future<void> _updateUserLocationInFirestore(double lat, double lng) async {
      final user = _auth.currentUser;
      if (user != null) {
        debugPrint("📍 Updating user location in Firestore for ${user.uid}");
        await _firestore.collection('users').doc(user.uid).set({
          'latitude': lat,
          'longitude': lng,
        }, SetOptions(merge: true));
      }
    }

    void _loadPosts() {

      if (!mounted) return;

      setState(() {
        loadingPosts = true;
        allPosts = [];
        filteredPosts = [];
      });

      if (userLat == null || userLng == null) {
        debugPrint("❌ User location is null");

        if (mounted) {
          setState(() {
            loadingPosts = false;
          });
        }

        return;
      }

      final userId = _auth.currentUser?.uid ?? '';
      final isDemoUser = _auth.currentUser?.email == "nearbyhungry@gmail.com";

      debugPrint("📍 Loading posts...");

      // 🔥 Cancel old listener before creating new one
      _postsSubscription?.cancel();

      // =========================================================
      // 🔥 MY POSTS
      // =========================================================

      if (showOnlyMyPosts) {

        _postsSubscription = _firestore
            .collection('posts')
            .where('creatorId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .snapshots()
            .listen(
              (snapshot) {

            debugPrint("🟢 My Posts count: ${snapshot.docs.length}");

            final freshPosts = snapshot.docs
                .map((doc) => Post.fromDocument(doc))
                .toList();

            if (!mounted) return;

            setState(() {
              allPosts = freshPosts;
              filteredPosts = List.from(freshPosts);
              loadingPosts = false;
            });

            _filterPosts();
          },

          onError: (e) {

            debugPrint("❌ My Posts Error: $e");

            if (!mounted) return;

            setState(() {
              loadingPosts = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error loading posts: $e")),
            );
          },
        );

        return;
      }

      // =========================================================
      // 🔥 DEMO USER
      // =========================================================

      if (isDemoUser) {

        _postsSubscription = _firestore
            .collection('posts')
            .orderBy('timestamp', descending: true)
            .limit(50)
            .snapshots()
            .listen((snapshot) {

          final freshPosts = snapshot.docs
              .map((doc) => Post.fromDocument(doc))
              .where((post) => post.creatorId != userId)
              .toList();

          if (!mounted) return;

          allPosts = freshPosts;

          _filterPosts();

          setState(() {
            loadingPosts = false;
          });
        });

        return;
      }

      // =========================================================
      // 🔥 NORMAL USERS → GEO QUERY
      // =========================================================

      final center = GeoFirePoint(
        GeoPoint(userLat!, userLng!),
      );

      final collection = _firestore.collection('posts');

      final geoCollection = GeoCollectionReference(collection);

      _postsSubscription = geoCollection
          .subscribeWithin(
        center: center,
        radiusInKm: 5,
        field: 'position',
        geopointFrom: (data) {

          final pos = data['position'];

          // ✅ geoflutterfire_plus structure
          if (pos is Map && pos['geopoint'] is GeoPoint) {
            return pos['geopoint'] as GeoPoint;
          }

          // ✅ old structure fallback
          if (data['latitude'] != null &&
              data['longitude'] != null) {

            return GeoPoint(
              (data['latitude'] as num).toDouble(),
              (data['longitude'] as num).toDouble(),
            );
          }

          return const GeoPoint(0, 0);
        },
        strictMode: true,
      )
          .listen(
              (snapshot) async {

        final freshPosts = <Post>[];

        for (final doc in snapshot) {

          final data = doc.data();

          if (data == null) continue;

          final post = Post.fromMap(
            data,
            doc.id,
          );

          // 🚫 Invalid coordinates
          if (post.latitude == 0 ||
              post.longitude == 0) {
            continue;
          }

          // 🚫 Skip own posts
          if (post.creatorId == userId) {
            continue;
          }

          // 🚫 Delete expired posts
          final expireAt = post.expireAt?.toDate();

          if (expireAt != null &&
              expireAt.isBefore(DateTime.now())) {

            await _firestore
                .collection('posts')
                .doc(post.id)
                .delete();

            continue;
          }

          freshPosts.add(post);
        }

        // 🔥 latest first
        freshPosts.sort(
              (a, b) =>
              b.timestamp!.compareTo(a.timestamp!),
        );

        debugPrint(
          "✅ Loaded ${freshPosts.length} nearby posts",
        );

        if (!mounted) return;

        allPosts = freshPosts;
        _filterPosts();

        setState(() {
          loadingPosts = false;
        });
        },

        onError: (e) {

          debugPrint("❌ Geo Query Error: $e");

          if (!mounted) return;

          setState(() {
            loadingPosts = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Geo query error: $e")),
          );
        },
      );
    }

    void _listenUnreadChats() {
      final userId = _auth.currentUser?.uid;
      final isAdmin =
          _auth.currentUser?.email?.toLowerCase() == "nearbyhungry@gmail.com";

      if (userId == null) return;

      Query query = isAdmin
          ? _firestore.collection('chats')
          : _firestore
          .collection('chats')
          .where('participants', arrayContains: userId);

      query.snapshots().listen((snapshot) {
        int unread = 0;

        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;

          if (isAdmin) {
            unread++;
          } else {
            final key = 'unreadCount_$userId';
            final count = (data[key] ?? 0) as int;

            if (count > 0) unread += 1;
          }
        }

        if (mounted) {
          setState(() {
            unreadChats = unread;
          });
        }
      });
    }

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
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
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
      const message =
          "🍲 Discover home-cooked food near you with Nearby Hungry!\n\n"
          "Download the app:\n"
          "Android: https://play.google.com/store/apps/details?id=com.vishal.nearbyhungry\n"
          "iOS: https://apps.apple.com/id/app/nearby-hungry/id6759957734\n\n"
          "Find or share homemade meals easily!";

      try {
        final box = context.findRenderObject() as RenderBox?;

        if (box != null && box.hasSize) {
          Share.share(
            message,
            subject: "Nearby Hungry App",
            sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
          );
        } else {
          Share.share(
            message,
            subject: "Nearby Hungry App",
          );
        }
      } catch (e) {
        debugPrint("❌ Share failed: $e");
      }
    }

    @override
    Widget build(BuildContext context) {
      final user = _auth.currentUser;

      return Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
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
              case 'rewards_program':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RewardsProgramPage(),
                  ),
                );
                break;

              case 'refer_earn':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ReferEarnPage(),
                  ),
                );
                break;
              case 'share':
                _shareApp();
                break;
              case 'logout':
                _logout();
                break;
              case 'delete_account':   // 🔥 ADD THIS
                _confirmDeleteAccount();
                break;
            }
          },
        ),
        appBar: _showAppBar
            ? PreferredSize(
          preferredSize: Size.fromHeight(
            _showTopSection ? 95 : 0,
          ),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF022B52),
                  Color(0xFF0A4D8C),
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(Icons.menu,color: Colors.white),
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                      ),
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: userLat != null
                                    ? Colors.greenAccent
                                    : Colors.redAccent,
                                size: 22,
                              ),

                              const SizedBox(width: 6),

                              Text(
                                userLat != null
                                    ? "Location Detected"
                                    : "Location Disabled",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    Stack(
                      children: [
                        IconButton(
                          icon: Image.asset(
                            'assets/message.png',
                            width: 28,
                            height: 28,
                            color: Colors.white,
                          ),
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
                            right: 4,
                            top: 4,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                unreadChats.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ) : null,
        body: SafeArea(
          child: Column(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF022B52),
                      Color(0xFF0A4D8C),
                    ],
                  ),
                ),
                child: Column(
                  children: [

                    // Search Bar
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 2, 16, 10),
                      height: 55,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 15),
                          const Icon(Icons.search),
                          const SizedBox(width: 10),

                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) {
                                _filterPosts();
                              },
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: "Search meals, chefs, food",
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Category Slider
                    Container(
                      height: 95,
                      margin: const EdgeInsets.only(
                        left: 12,
                        right: 12,
                        bottom: 12,
                      ),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _categoryItem(
                            "All",
                            "assets/categories/all.png",
                          ),
                          _categoryItem(
                            "Burger",
                            "assets/categories/burger.png",
                          ),
                          _categoryItem(
                            "Pizza",
                            "assets/categories/pizza.png",
                          ),
                          _categoryItem(
                            "Samosa",
                            "assets/categories/samosa.png",
                          ),
                          _categoryItem(
                            "Biryani",
                            "assets/categories/biryani.png",
                          ),
                          _categoryItem(
                            "Chicken",
                            "assets/categories/chicken.png",
                          ),
                          _categoryItem(
                            "Vada Pav",
                            "assets/categories/vadapav.png",
                          ),
                          _categoryItem(
                            "Tiffin",
                            "assets/categories/tiffin.png",
                          ),
                          _categoryItem(
                            "Tiffin",
                            "assets/categories/tiffin.png",
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: loadingPosts
                    ? const Center(child: CircularProgressIndicator())
                    : filteredPosts.isEmpty
                    ? Center(
                  child: Text(
                    showOnlyMyPosts
                        ? 'You have not created any posts yet'
                        : 'No posts nearby',
                  ),
                )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.only(bottom: 16),
                            itemCount: filteredPosts.length,
                            itemBuilder: (context, index) {
                              final post = filteredPosts[index];
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
                                      builder: (context, scrollController) {
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
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            height: 65, // fixed height
            margin: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                backgroundColor: const Color(0xFFFFF8E1),
                selectedItemColor: const Color(0xFFF94449),
                unselectedItemColor: Colors.black54,
                elevation: 0,

                // 🔥 Center icons vertically
                iconSize: 24,
                selectedFontSize: 11,
                unselectedFontSize: 11,

                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.list),
                    label: 'My Posts',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.add_box),
                    label: 'Add Post',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.help),
                    label: 'Help',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.share),
                    label: 'Share',
                  ),
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
                        builder: (_) => const HelpSupportPage(),
                      );
                      break;

                    case 4:
                      _shareApp();
                      break;
                  }
                },
              ),
            ),
          ),
        ),
      );
    }
    Future<void> _deleteAccount() async {
      final user = _auth.currentUser;
      if (user == null) return;

      try {
        final uid = user.uid;

        // 🔐 STEP 1: Re-authenticate FIRST
        if (user.providerData.any((p) => p.providerId == 'password')) {
          final password = await _askPassword();
          if (password == null) return;

          final credential = EmailAuthProvider.credential(
            email: user.email!,
            password: password,
          );

          await user.reauthenticateWithCredential(credential);

        } else if (user.providerData.any((p) => p.providerId == 'google.com')) {
          final googleSignIn = GoogleSignIn();

          await googleSignIn.signOut();

          final googleUser = await googleSignIn.signIn();

          if (googleUser == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Google sign-in cancelled")),
            );
            return;
          }

          final googleAuth = await googleUser.authentication;

          final googleCredential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );

          await user.reauthenticateWithCredential(googleCredential);
        }

        // ✅ STEP 2: SHOW loader AFTER auth
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );

        // 🔥 STEP 3: Batch delete
        final batch = _firestore.batch();

        final posts = await _firestore
            .collection('posts')
            .where('creatorId', isEqualTo: uid)
            .get();

        for (var doc in posts.docs) {
          batch.delete(doc.reference);
        }

        final chats = await _firestore
            .collection('chats')
            .where('participants', arrayContains: uid)
            .get();

        for (var doc in chats.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();

        // 🔥 STEP 4: Delete user document
        final userDoc = await _firestore
            .collection('users')
            .doc(uid)
            .get();

        if (userDoc.exists) {
          await _firestore
              .collection('deleted_users')
              .doc(user.email!.toLowerCase())
              .set({
            'referralCode': userDoc['referralCode'],
            'email': user.email!.toLowerCase(),
            'deletedAt': FieldValue.serverTimestamp(),
          });
        }

        await _firestore
            .collection('users')
            .doc(uid)
            .delete();

        // 🔥 STEP 5: Delete auth account
        await user.delete();

        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        if (!mounted) return;

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
              (route) => false,
        );

      } catch (e) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error deleting account or Incorrect password")),
        );
      }
    }
    Future<String?> _askPassword() async {
      String password = '';

      return await showDialog<String>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Confirm Password"),
            content: TextField(
              obscureText: true,
              onChanged: (value) => password = value,
              decoration: const InputDecoration(
                hintText: "Enter your password",
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, password),
                child: const Text("Confirm"),
              ),
            ],
          );
        },
      );
    }
    Future<void> _confirmDeleteAccount() async {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Delete Account"),
          content: const Text(
            "Are you sure you want to delete your account?\n\nThis action is permanent.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirm == true) {
        _deleteAccount(); // ✅ only called once
      }
    }
  }