import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../screens/chat_page.dart';

class PostDetailPage extends StatefulWidget {
  final String postId;
  final ScrollController? scrollController;

  const PostDetailPage({
    super.key,
    required this.postId,
    this.scrollController,
  });

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool loading = true;
  bool isOwnPost = false;

  String creatorName = '';
  String creatorId = '';
  String content = '';
<<<<<<< HEAD

=======
>>>>>>> 06de8d42fc3ced6379cdde15cb634160a30df99f
  Timestamp? timestamp;

  double? postLat;
  double? postLng;

  double? myLat;
  double? myLng;

  @override
  void initState() {
    super.initState();
<<<<<<< HEAD

    print("INIT STATE CALLED");

    _loadPost();

    Future.delayed(const Duration(milliseconds: 500), () {
      _incrementViews();
    });
  }

  // ================= VIEW COUNT =================

  Future<void> _incrementViews() async {
    try {
      print("===== VIEW START =====");

      final user = _auth.currentUser;

      if (user == null) {
        print("USER NULL");
        return;
      }

      print("CURRENT USER UID: ${user.uid}");
      print("POST ID: ${widget.postId}");

      final ref = _firestore.collection('posts').doc(widget.postId);

      final doc = await ref.get();

      print("DOC EXISTS: ${doc.exists}");

      if (!doc.exists) {
        print("DOCUMENT NOT FOUND");
        return;
      }

      final data = doc.data();

      print("FULL DATA: $data");

      if (data == null) {
        print("DATA NULL");
        return;
      }

      final postCreatorId = data['creatorId'];

      print("POST CREATOR UID: $postCreatorId");

      // Prevent own post view increment
      if (postCreatorId == user.uid) {
        print("OWN POST DETECTED");
        return;
      }

      print("BEFORE UPDATE");

      await ref.update({
        'views': FieldValue.increment(1),
      });

      print("UPDATE SUCCESS");

      // Force server fetch
      final updatedDoc =
      await ref.get(const GetOptions(source: Source.server));

      print("NEW VIEWS: ${updatedDoc.data()?['views']}");

      print("===== VIEW END =====");
    } catch (e, stack) {
      print("VIEW ERROR: $e");
      print(stack);
    }
  }

  // ================= LOAD POST =================

  Future<void> _loadPost() async {
    try {
      final doc =
      await _firestore.collection('posts').doc(widget.postId).get();
=======
    _loadPost();
  }

  Future<void> _loadPost() async {
    try {
      final doc = await _firestore.collection('posts').doc(widget.postId).get();
>>>>>>> 06de8d42fc3ced6379cdde15cb634160a30df99f

      if (!doc.exists) {
        _showNotFound();
        return;
      }

      final data = doc.data();

<<<<<<< HEAD
      final rawText =
          data?['text'] ?? data?['description'] ?? data?['content'];
=======
      final rawText = data?['text'] ?? data?['description'] ?? data?['content'];
>>>>>>> 06de8d42fc3ced6379cdde15cb634160a30df99f

      final myId = _auth.currentUser?.uid;
      final creator = data?['creatorId'];

      setState(() {
        creatorId = creator ?? '';
<<<<<<< HEAD

        creatorName =
            (data?['creatorName'] ?? 'Nearby User').toString();

        content =
        rawText == null ? '' : rawText.toString().trim();

=======
        creatorName = (data?['creatorName'] ?? 'Nearby User').toString();
        content = rawText == null ? '' : rawText.toString().trim();
>>>>>>> 06de8d42fc3ced6379cdde15cb634160a30df99f
        timestamp = data?['timestamp'];

        postLat = (data?['latitude'] as num?)?.toDouble();
        postLng = (data?['longitude'] as num?)?.toDouble();

        isOwnPost =
        (myId != null && creator != null && myId == creator);

        loading = false;
      });

      await _fetchMyLocation();
    } catch (e) {
<<<<<<< HEAD
      print("LOAD POST ERROR: $e");
=======
>>>>>>> 06de8d42fc3ced6379cdde15cb634160a30df99f
      _showNotFound();
    }
  }

<<<<<<< HEAD
  // ================= NOT FOUND =================

  void _showNotFound() {
    if (!mounted) return;

=======
  void _showNotFound() {
    if (!mounted) return;
>>>>>>> 06de8d42fc3ced6379cdde15cb634160a30df99f
    setState(() {
      loading = false;
      creatorName = 'Post not found';
      content = '';
    });
  }

<<<<<<< HEAD
  // ================= LOCATION =================

  Future<void> _fetchMyLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition();

      if (!mounted) return;

      setState(() {
        myLat = pos.latitude;
        myLng = pos.longitude;
      });
    } catch (e) {
      print("LOCATION ERROR: $e");
    }
  }

  double _distanceInKm(
      double lat1,
      double lng1,
      double lat2,
      double lng2,
      ) {
    return Geolocator.distanceBetween(
      lat1,
      lng1,
      lat2,
      lng2,
    ) /
        1000.0;
  }

  // ================= CHAT =================

  Future<void> _openChat() async {
    final user = _auth.currentUser;

    if (user == null) return;

    if (creatorId.isEmpty) return;

=======
  Future<void> _fetchMyLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) return;

    final pos = await Geolocator.getCurrentPosition();

    if (!mounted) return;

    setState(() {
      myLat = pos.latitude;
      myLng = pos.longitude;
    });
  }

  double _distanceInKm(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000.0;
  }

  // ---------------- Chat (FIXED) ----------------
  Future<void> _openChat() async {
    final user = _auth.currentUser;
    if (user == null) return;
    if (creatorId.isEmpty) return;
>>>>>>> 06de8d42fc3ced6379cdde15cb634160a30df99f
    if (creatorId == user.uid) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          chefId: creatorId,
          customerId: user.uid,
          chefName: creatorName,
        ),
      ),
    );
  }

<<<<<<< HEAD
  // ================= TIME FORMAT =================

  String _formatTime(Timestamp? t) {
    if (t == null) return '';

    final d = t.toDate();

=======
  String _formatTime(Timestamp? t) {
    if (t == null) return '';
    final d = t.toDate();
>>>>>>> 06de8d42fc3ced6379cdde15cb634160a30df99f
    return "${d.day.toString().padLeft(2, '0')}-"
        "${d.month.toString().padLeft(2, '0')}-"
        "${d.year} "
        "${d.hour.toString().padLeft(2, '0')}:"
        "${d.minute.toString().padLeft(2, '0')}";
  }

<<<<<<< HEAD
  // ================= UI =================

=======
>>>>>>> 06de8d42fc3ced6379cdde15cb634160a30df99f
  @override
  Widget build(BuildContext context) {
    return Center(
      child: loading
          ? const CircularProgressIndicator()
          : ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.95,
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: SingleChildScrollView(
          controller: widget.scrollController,
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: const Color(0xFFFFF8E1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
<<<<<<< HEAD
                crossAxisAlignment:
                CrossAxisAlignment.start,
=======
                crossAxisAlignment: CrossAxisAlignment.start,
>>>>>>> 06de8d42fc3ced6379cdde15cb634160a30df99f
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
<<<<<<< HEAD
                      margin:
                      const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius:
                        BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // Creator Name
=======
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
>>>>>>> 06de8d42fc3ced6379cdde15cb634160a30df99f
                  Text(
                    creatorName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
<<<<<<< HEAD

                  // Time
                  if (timestamp != null)
                    Padding(
                      padding:
                      const EdgeInsets.only(top: 2),
=======
                  if (timestamp != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
>>>>>>> 06de8d42fc3ced6379cdde15cb634160a30df99f
                      child: Text(
                        _formatTime(timestamp),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
<<<<<<< HEAD

                  const SizedBox(height: 10),

                  // Content
=======
                  const SizedBox(height: 10),
>>>>>>> 06de8d42fc3ced6379cdde15cb634160a30df99f
                  Text(
                    content,
                    softWrap: true,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
<<<<<<< HEAD

                  const SizedBox(height: 16),

                  // Buttons
=======
                  const SizedBox(height: 16),
>>>>>>> 06de8d42fc3ced6379cdde15cb634160a30df99f
                  Row(
                    children: [
                      if (!isOwnPost)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _openChat,
<<<<<<< HEAD
                            style:
                            ElevatedButton.styleFrom(
                              backgroundColor:
                              const Color(0xFF4CAF50),
                              foregroundColor:
                              Colors.white,
                              shape:
                              RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(
                                    12),
                              ),
                              padding:
                              const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                            child: const Text(
                              'Chat with Chef',
                            ),
                          ),
                        ),

                      if (!isOwnPost)
                        const SizedBox(width: 10),

                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              Navigator.pop(context),
                          style:
                          ElevatedButton.styleFrom(
                            backgroundColor:
                            const Color(0xFFFF7B00),
                            foregroundColor:
                            Colors.white,
                            shape:
                            RoundedRectangleBorder(
=======
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                              const Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(12),
                              ),
                              padding:
                              const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Chat with Chef'),
                          ),
                        ),
                      if (!isOwnPost) const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            const Color(0xFFFF7B00),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
>>>>>>> 06de8d42fc3ced6379cdde15cb634160a30df99f
                              borderRadius:
                              BorderRadius.circular(12),
                            ),
                            padding:
<<<<<<< HEAD
                            const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
=======
                            const EdgeInsets.symmetric(vertical: 14),
>>>>>>> 06de8d42fc3ced6379cdde15cb634160a30df99f
                          ),
                          child: const Text('Close'),
                        ),
                      ),
                    ],
                  ),
<<<<<<< HEAD

                  const SizedBox(height: 12),

                  // Distance
=======
                  const SizedBox(height: 12),
>>>>>>> 06de8d42fc3ced6379cdde15cb634160a30df99f
                  Text(
                    (postLat != null &&
                        postLng != null &&
                        postLat != 0 &&
                        myLat != null &&
                        myLng != null)
                        ? "📍 ${_distanceInKm(myLat!, myLng!, postLat!, postLng!).toStringAsFixed(2)} km away"
                        : "📍 Distance unavailable",
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
<<<<<<< HEAD

                  const SizedBox(height: 10),

                  // Disclaimer
=======
                  const SizedBox(height: 10),
>>>>>>> 06de8d42fc3ced6379cdde15cb634160a30df99f
                  const Text(
                    "⚠️ Disclaimer: Food is prepared and sold by independent chefs. Nearby Hungry does not sell or deliver food. All food safety compliance is the responsibility of the chef.",
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFFF4500),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
<<<<<<< HEAD
}
=======
}
>>>>>>> 06de8d42fc3ced6379cdde15cb634160a30df99f
