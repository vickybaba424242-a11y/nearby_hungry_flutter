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
  import '../screens/customer_screen.dart';
  import 'package:flutter/services.dart';
  import '../widgets/restaurant_card.dart';
  import '../screens/chef_reviews_screen.dart';
  import 'package:flutter/foundation.dart';

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
    String searchedKeyword = "";
    List<Post> allPosts = [];
    List<Post> filteredPosts = [];

    StreamSubscription? _postsSubscription;

    double? userLat;
    double? userLng;

    bool showOnlyMyPosts = false;
    List<Post> posts = [];
    bool loadingPosts = true;
    int unreadChats = 0;

    // Post visibility
    bool _hasPosts = false;
    bool _hideMyPosts = false;

    String selectedCategory = "All";
    String selectedProvider = 'homeChef';

    Future<void> _loadPostVisibilitySettings() async {
      final user = _auth.currentUser;

      if (user == null) return;

      try {
        // Check whether user has at least one post
        final postsSnapshot = await _firestore
            .collection('posts')
            .where('creatorId', isEqualTo: user.uid)
            .limit(1)
            .get();

        // Get user's visibility setting
        final userSnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        bool hidePosts = false;

        if (userSnapshot.exists) {
          final data = userSnapshot.data();

          hidePosts = data?['hidePosts'] ?? false;
        }

        if (!mounted) return;

        setState(() {
          _hasPosts = postsSnapshot.docs.isNotEmpty;
          _hideMyPosts = hidePosts;
        });
      } catch (e) {
        debugPrint("❌ Error loading post visibility settings: $e");
      }
    }

    void _showAdminOptions(
        BuildContext context,
        Post post,
        ) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        builder: (sheetContext) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                const SizedBox(height: 8),

                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 15),

                Text(
                  "Admin Options",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 10),

                // ==============================
                // EDIT RESTAURANT
                // ==============================

                ListTile(
                  leading: const Icon(
                    Icons.edit,
                    color: Colors.blue,
                  ),
                  title: Text(
                    "Edit Restaurant",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    // Close admin options first
                    Navigator.pop(sheetContext);

                    // Open edit screen/modal
                    _openAddPostModal(
                      postToEdit: post,
                    );
                  },
                ),

                // ==============================
                // DELETE RESTAURANT
                // ==============================

                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                  title: Text(
                    "Delete Restaurant",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                  onTap: () {
                    // Close admin options first
                    Navigator.pop(sheetContext);

                    // Show confirmation dialog
                    _confirmAdminDeleteRestaurant(post);
                  },
                ),

                const SizedBox(height: 10),
              ],
            ),
          );
        },
      );
    }

    void _filterPosts() {

      searchedKeyword = _searchController.text.trim();

      final search = searchedKeyword.toLowerCase();

      filteredPosts = allPosts.where((post) {

        final content =
        "${post.text} ${post.creatorName}".toLowerCase();

        final matchesSearch =
            search.isEmpty ||
                content.contains(search);

        final matchesCategory =
            selectedCategory == "All" ||
                content.contains(selectedCategory.toLowerCase());

        final matchesProvider =
            selectedProvider == 'all' ||
                post.providerType == selectedProvider;

        return matchesSearch &&
            matchesCategory &&
            matchesProvider;

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
        await _startLocationFlow();
      });

      _listenUnreadChats();
      _listenForFCMTokenRefresh();
      _loadPostVisibilitySettings();
    }
    void _listenForFCMTokenRefresh() {
      FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
        debugPrint("🔄 FCM token refreshed: $token");

        final user = _auth.currentUser;

        if (user == null || token.isEmpty) return;

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        debugPrint("✅ Refreshed FCM token saved");
      });
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 48,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              Container(
                padding: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                    colors: [
                      Color(0xFFF94449),
                      Color(0xFFFF7A45),
                    ],
                  )
                      : null,
                  color: isSelected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : Colors.grey.shade300,
                  ),
                ),
                child: CircleAvatar(
                  radius: 15,
                  backgroundColor: Colors.white,
                  backgroundImage: AssetImage(imagePath),
                ),
              ),

              const SizedBox(height: 3),

              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.w500,
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

      try {
        // Ask notification permission
        final settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );

        debugPrint(
          "🔔 Notification permission: "
              "${settings.authorizationStatus}",
        );

        // =========================================================
        // ANDROID
        // =========================================================

        if (defaultTargetPlatform == TargetPlatform.android) {
          debugPrint("🤖 Android detected");

          final token = await messaging.getToken();

          debugPrint("🔑 Android FCM token: $token");

          final user = _auth.currentUser;

          if (user != null && token != null && token.isNotEmpty) {
            await _firestore
                .collection('users')
                .doc(user.uid)
                .set({
              'fcmToken': token,
              'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));

            debugPrint("✅ Android FCM token saved");
          }

          return;
        }

        // =========================================================
        // IOS
        // =========================================================

        if (defaultTargetPlatform == TargetPlatform.iOS) {
          debugPrint("🍎 iOS detected");

          String? apnsToken = await messaging.getAPNSToken();

          int retry = 0;

          while (apnsToken == null && retry < 10) {
            debugPrint(
              "⏳ Waiting for APNS token... attempt ${retry + 1}",
            );

            await Future.delayed(
              const Duration(seconds: 1),
            );

            apnsToken = await messaging.getAPNSToken();

            retry++;
          }

          debugPrint("🍎 APNS token: $apnsToken");

          if (apnsToken == null) {
            debugPrint(
              "⚠️ APNS token still unavailable",
            );
            return;
          }

          final token = await messaging.getToken();

          debugPrint("🔑 iOS FCM token: $token");

          final user = _auth.currentUser;

          if (user != null && token != null && token.isNotEmpty) {
            await _firestore
                .collection('users')
                .doc(user.uid)
                .set({
              'fcmToken': token,
              'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));

            debugPrint("✅ iOS FCM token saved");
          }
        }
      } catch (e, st) {
        debugPrint("❌ Notification setup failed: $e");
        debugPrintStack(stackTrace: st);
      }
    }

    Future<void> _startLocationFlow() async {
      debugPrint("🚀 Starting location flow...");

      if (!mounted) return;

      setState(() {
        loadingPosts = true;
        userLat = null;
        userLng = null;
      });

      await _askLocationFirstTimeOnly();

      if (!mounted) return;

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
      try {
        // =========================================================
        // 1. CHECK LOCATION SERVICE
        // =========================================================

        bool serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

        debugPrint(
          "📍 Location service enabled: $serviceEnabled",
        );

        if (!serviceEnabled) {
          if (!mounted) return;

          setState(() {
            loadingPosts = false;
            userLat = null;
            userLng = null;
          });

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

        // =========================================================
        // 2. CHECK PERMISSION
        // =========================================================

        LocationPermission permission =
        await Geolocator.checkPermission();

        debugPrint(
          "📍 Current permission: $permission",
        );

        if (permission == LocationPermission.denied) {
          permission =
          await Geolocator.requestPermission();

          debugPrint(
            "📍 Permission after request: $permission",
          );
        }

        if (permission == LocationPermission.deniedForever) {
          if (!mounted) return;

          setState(() {
            loadingPosts = false;
            userLat = null;
            userLng = null;
          });

          await showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Location permission required'),
              content: const Text(
                'Please allow location permission from app settings to see nearby food.',
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
          if (!mounted) return;

          setState(() {
            loadingPosts = false;
            userLat = null;
            userLng = null;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permission is required to show nearby food.',
              ),
            ),
          );

          return;
        }

        // =========================================================
        // 3. GET REAL DEVICE LOCATION
        // =========================================================

        await _initLocation();

        // =========================================================
        // 4. IMPORTANT
        // Only load posts if real location exists
        // =========================================================

        if (userLat == null || userLng == null) {
          debugPrint(
            "❌ Real device location unavailable. Posts will not load.",
          );

          if (!mounted) return;

          setState(() {
            loadingPosts = false;
          });

          return;
        }

        debugPrint(
          "✅ Real location available: "
              "$userLat, $userLng",
        );

        _loadPosts();

      } catch (e, stackTrace) {
        debugPrint(
          "❌ _ensureLocationAndLoad ERROR: $e",
        );

        debugPrintStack(
          stackTrace: stackTrace,
        );

        if (!mounted) return;

        setState(() {
          loadingPosts = false;
          userLat = null;
          userLng = null;
        });
      }
    }

    Future<void> _initLocation() async {
      debugPrint("📍 initLocation called");

      try {
        final position = await LocationHelper
            .getCurrentLocation(context)
            .timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            debugPrint(
              "⏰ Location request timed out",
            );
            return null;
          },
        );

        if (position == null) {
          debugPrint(
            "❌ Could not get device location",
          );

          if (!mounted) return;

          setState(() {
            userLat = null;
            userLng = null;
          });

          return;
        }

        final lat = position.latitude;
        final lng = position.longitude;

        debugPrint(
          "📍 REAL DEVICE LOCATION: $lat, $lng",
        );

        if (lat == 0 || lng == 0) {
          debugPrint(
            "❌ Invalid device coordinates",
          );

          if (!mounted) return;

          setState(() {
            userLat = null;
            userLng = null;
          });

          return;
        }

        if (!mounted) return;

        setState(() {
          userLat = lat;
          userLng = lng;
        });

        await _updateUserLocationInFirestore(
          lat,
          lng,
        );

        debugPrint(
          "✅ Real location saved successfully",
        );

      } catch (e, stackTrace) {
        debugPrint(
          "❌ _initLocation ERROR: $e",
        );

        debugPrintStack(
          stackTrace: stackTrace,
        );

        if (!mounted) return;

        setState(() {
          userLat = null;
          userLng = null;
        });
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

    Future<bool> _isUserPostsHidden(String creatorId) async {
      try {
        final userDoc = await _firestore
            .collection('users')
            .doc(creatorId)
            .get();

        if (!userDoc.exists) {
          return false;
        }

        final data = userDoc.data();

        return data?['hidePosts'] == true;
      } catch (e) {
        debugPrint(
          "❌ Error checking post visibility for $creatorId: $e",
        );

        // If visibility cannot be checked,
        // don't accidentally hide the post.
        return false;
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

          // =========================================================
          // 🚫 CHECK CREATOR POST VISIBILITY
          // =========================================================

          final postsHidden = await _isUserPostsHidden(
            post.creatorId,
          );

          if (postsHidden) {
            debugPrint(
              "🚫 Skipping hidden post: ${post.id}",
            );

            continue;
          }

          // =========================================================
          // 🚫 DELETE EXPIRED POSTS
          // =========================================================

          final expireAt = post.expireAt?.toDate();

          if (expireAt != null &&
              expireAt.isBefore(DateTime.now())) {

            await _firestore
                .collection('posts')
                .doc(post.id)
                .delete();

            continue;
          }

          // =========================================================
          // ✅ ADD ACTIVE POST
          // =========================================================

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

    void _showAdminPostOptions(Post post) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        builder: (sheetContext) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                const SizedBox(height: 10),

                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 15),

                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                  title: const Text(
                    'Delete Restaurant',
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);

                    _confirmAdminDeleteRestaurant(post);
                  },
                ),

                ListTile(
                  leading: const Icon(
                    Icons.close,
                  ),
                  title: const Text(
                    'Cancel',
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                  },
                ),

                const SizedBox(height: 10),
              ],
            ),
          );
        },
      );
    }

    void _confirmAdminDeleteRestaurant(Post post) {
      showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text(
              'Delete Restaurant?',
            ),

            content: Text(
              'Are you sure you want to delete '
                  '${post.creatorName} restaurant?',
            ),

            actions: [

              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text(
                  'Cancel',
                ),
              ),

              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);

                  await _deleteRestaurant(post);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Delete',
                ),
              ),
            ],
          );
        },
      );
    }

    Future<void> _deleteRestaurant(Post post) async {
      try {
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(post.id)
            .delete();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Restaurant deleted successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to delete restaurant: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
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
      debugPrint("🏠 BUILD START");
      final user = _auth.currentUser;

      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Color(0xFF022B52),
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      );

      debugPrint("🏠 BUILDING SCAFFOLD");
      return Scaffold(
        extendBodyBehindAppBar: false,
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
              case 'customers':

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CustomersScreen(),
                  ),
                );

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
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(
            _showAppBar ? 70 : 0,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            height: _showAppBar ? 70 : 0,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF022B52),
                  Color(0xFF0A4D8C),
                ],
              ),
            ),
            child: _showAppBar
                ? SafeArea(
              bottom: false,
              child: SizedBox(
                height: 56,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      // ================= MENU =================
                      Builder(
                        builder: (context) => SizedBox(
                          width: 44,
                          height: 44,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            icon: const Icon(
                              Icons.menu,
                              color: Colors.white,
                              size: 26,
                            ),
                            onPressed: () {
                              Scaffold.of(context).openDrawer();
                            },
                          ),
                        ),
                      ),

                      const SizedBox(width: 4),

                      // ================= LOCATION =================
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: userLat != null
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                              size: 19,
                            ),

                            const SizedBox(width: 4),

                            Flexible(
                              child: Text(
                                userLat != null
                                    ? "Location On"
                                    : "Location Off",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ================= RIGHT SIDE =================
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // MESSAGE
                          SizedBox(
                            width: 42,
                            height: 42,
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 42,
                                    minHeight: 42,
                                  ),
                                  icon: Image.asset(
                                    'assets/message.png',
                                    width: 21,
                                    height: 21,
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
                                    right: -1,
                                    top: -1,
                                    child: Container(
                                      constraints: const BoxConstraints(
                                        minWidth: 17,
                                        minHeight: 17,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 1,
                                      ),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        unreadChats > 9
                                            ? '9+'
                                            : unreadChats.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // VISIBILITY
                          if (_hasPosts) ...[
                            const SizedBox(width: 2),

                            Tooltip(
                              message: _hideMyPosts
                                  ? "Your posts are inactive"
                                  : "Your posts are active",
                              child: SizedBox(
                                height: 42,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _hideMyPosts
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: _hideMyPosts
                                          ? Colors.black
                                          : const Color(0xFFF94449),
                                      size: 19,
                                    ),

                                    Transform.scale(
                                      scale: 0.60,
                                      child: Switch(
                                        value: !_hideMyPosts,
                                        activeColor:
                                        const Color(0xFFF94449),
                                        activeTrackColor: Colors.white,
                                        inactiveThumbColor: Colors.black,
                                        inactiveTrackColor: Colors.black26,
                                        onChanged: (isActive) async {
                                          final user = _auth.currentUser;

                                          if (user == null) return;

                                          final hidePosts = !isActive;

                                          setState(() {
                                            _hideMyPosts = hidePosts;
                                          });

                                          try {
                                            await _firestore
                                                .collection('users')
                                                .doc(user.uid)
                                                .set(
                                              {
                                                'hidePosts': hidePosts,
                                              },
                                              SetOptions(merge: true),
                                            );

                                            if (!mounted) return;

                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                duration:
                                                const Duration(seconds: 2),
                                                content: Text(
                                                  isActive
                                                      ? "Your posts are now active"
                                                      : "Your posts are now inactive",
                                                ),
                                              ),
                                            );
                                          } catch (e) {
                                            debugPrint(
                                              "❌ Error updating post visibility: $e",
                                            );

                                            if (!mounted) return;

                                            setState(() {
                                              _hideMyPosts = !hidePosts;
                                            });

                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "Unable to update post visibility",
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )
                : const SizedBox(),
          ),
        ),
        body: Column(
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

                    const SizedBox(height: 4),

                    // Search Bar
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 2, 16, 6),
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.grey.shade200,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [

                          const SizedBox(width: 16),

                          const Icon(
                            Icons.search_rounded,
                            color: Color(0xFFF94449),
                            size: 21,
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) {
                                setState(() {});
                                _filterPosts();
                              },
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: "Search food, chef or cuisine",
                                hintStyle: GoogleFonts.poppins(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),

                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _searchController.clear();
                                _filterPosts();
                              },
                            ),

                        ],
                      ),
                    ),

                    // Category Slider
                    // Category Slider
                    SizedBox(
                      height: 52,
                      child: Row(
                        children: [

                          // Fixed All Button
                          Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: _categoryItem(
                              "All",
                              "assets/categories/all.png",
                            ),
                          ),


                          // Scrollable Categories
                          Expanded(
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.only(left: 5),
                              children: [

                                _categoryItem(
                                  "Burger",
                                  "assets/categories/burger.png",
                                ),

                                _categoryItem(
                                  "Pizza",
                                  "assets/categories/pizza.png",
                                ),

                                _categoryItem(
                                  "Momos",
                                  "assets/categories/momos.png",
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

                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        height: 34,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [

                            // ================= HOME CHEF =================
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedProvider = 'homeChef';
                                  });

                                  _filterPosts();
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: selectedProvider == 'homeChef'
                                        ? const Color(0xFFF94449)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        '👨‍🍳',
                                        style: TextStyle(fontSize: 13),
                                      ),

                                      const SizedBox(width: 5),

                                      Text(
                                        'Home Chef',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: selectedProvider == 'homeChef'
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 3),

                            // ================= RESTAURANT =================
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedProvider = 'restaurant';
                                  });

                                  _filterPosts();
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: selectedProvider == 'restaurant'
                                        ? const Color(0xFFF94449)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        '🍽️',
                                        style: TextStyle(fontSize: 13),
                                      ),

                                      const SizedBox(width: 5),

                                      Text(
                                        'Restaurant',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: selectedProvider == 'restaurant'
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),
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
                              if (post.providerType == "restaurant") {
                                return RestaurantCard(
                                  post: post,
                                  isOwnPost: isOwnPost,
                                  searchText: searchedKeyword,
                                  onOptionsPressed: () {
                                    _showPostOptions(post);
                                  },
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
                                            searchText: searchedKeyword,
                                          );
                                        },
                                      ),
                                    );
                                  },
                                  onRatingPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChefReviewsScreen(
                                          chefId: post.creatorId,
                                          chefName: post.creatorName,
                                        ),
                                      ),
                                    );
                                  },
                                  onChatPressed: () => _openChatWithChef(post),
                                  onAdminOptionsPressed: () {
                                    _showAdminOptions(context, post);
                                  },

                                );
                              }

                              return PostCard(
                                post: post,
                                isOwnPost: isOwnPost,
                                timeText: timeText,
                                expireText: isOwnPost ? expireText : null,
                                searchText: searchedKeyword,
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
                                          searchText: searchedKeyword,
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
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            height: 70, // fixed height
            margin: const EdgeInsets.only(
              left: 12,
              right: 12,
              bottom: 0,
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