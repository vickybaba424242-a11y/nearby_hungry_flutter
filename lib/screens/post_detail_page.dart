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
  Timestamp? timestamp;

  double? postLat;
  double? postLng;

  double? myLat;
  double? myLng;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  Future<void> _loadPost() async {
    try {
      final doc = await _firestore.collection('posts').doc(widget.postId).get();

      if (!doc.exists) {
        _showNotFound();
        return;
      }

      final data = doc.data();

      final rawText = data?['text'] ?? data?['description'] ?? data?['content'];

      final myId = _auth.currentUser?.uid;
      final creator = data?['creatorId'];

      setState(() {
        creatorId = creator ?? '';
        creatorName = (data?['creatorName'] ?? 'Nearby User').toString();
        content = rawText == null ? '' : rawText.toString().trim();
        timestamp = data?['timestamp'];

        postLat = (data?['latitude'] as num?)?.toDouble();
        postLng = (data?['longitude'] as num?)?.toDouble();

        isOwnPost =
        (myId != null && creator != null && myId == creator);

        loading = false;
      });

      await _fetchMyLocation();
    } catch (e) {
      _showNotFound();
    }
  }

  void _showNotFound() {
    if (!mounted) return;
    setState(() {
      loading = false;
      creatorName = 'Post not found';
      content = '';
    });
  }

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

  String _formatTime(Timestamp? t) {
    if (t == null) return '';
    final d = t.toDate();
    return "${d.day.toString().padLeft(2, '0')}-"
        "${d.month.toString().padLeft(2, '0')}-"
        "${d.year} "
        "${d.hour.toString().padLeft(2, '0')}:"
        "${d.minute.toString().padLeft(2, '0')}";
  }

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Text(
                    creatorName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (timestamp != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        _formatTime(timestamp),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Text(
                    content,
                    softWrap: true,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (!isOwnPost)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _openChat,
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
                              borderRadius:
                              BorderRadius.circular(12),
                            ),
                            padding:
                            const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Close'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 10),
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
}
