import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../screens/chat_page.dart';

class PostDetailPage extends StatefulWidget {
  final String postId;
  final ScrollController? scrollController;
  final String? searchText;

  const PostDetailPage({
    super.key,
    required this.postId,
    this.scrollController,
    this.searchText,
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

  Widget _highlightText(String text) {

    final keyword = widget.searchText?.trim();

    if (keyword == null || keyword.isEmpty) {
      return Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black,
        ),
      );
    }

    final regex = RegExp(
      RegExp.escape(keyword),
      caseSensitive: false,
    );

    final matches = regex.allMatches(text);

    if (matches.isEmpty) {
      return Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black,
        ),
      );
    }


    List<TextSpan> spans = [];

    int lastIndex = 0;


    for (final match in matches) {

      if (match.start > lastIndex) {
        spans.add(
          TextSpan(
            text: text.substring(
              lastIndex,
              match.start,
            ),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
            ),
          ),
        );
      }


      spans.add(
        TextSpan(
          text: text.substring(
            match.start,
            match.end,
          ),
          style: const TextStyle(
            backgroundColor: Colors.yellow,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 14,
          ),
        ),
      );


      lastIndex = match.end;
    }


    if (lastIndex < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastIndex),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
          ),
        ),
      );
    }


    return RichText(
      text: TextSpan(
        children: spans,
      ),
    );
  }

  // ================= LOAD POST =================

  Future<void> _loadPost() async {
    try {
      final doc =
      await _firestore.collection('posts').doc(widget.postId).get();

      if (!doc.exists) {
        _showNotFound();
        return;
      }

      final data = doc.data();

      final rawText =
          data?['text'] ?? data?['description'] ?? data?['content'];

      final myId = _auth.currentUser?.uid;
      final creator = data?['creatorId'];

      setState(() {
        creatorId = creator ?? '';

        creatorName =
            (data?['creatorName'] ?? 'Nearby User').toString();

        content =
        rawText == null ? '' : rawText.toString().trim();

        timestamp = data?['timestamp'];

        postLat = (data?['latitude'] as num?)?.toDouble();
        postLng = (data?['longitude'] as num?)?.toDouble();

        isOwnPost =
        (myId != null && creator != null && myId == creator);

        loading = false;
      });

      await _fetchMyLocation();
    } catch (e) {
      print("LOAD POST ERROR: $e");
      _showNotFound();
    }
  }

  // ================= NOT FOUND =================

  void _showNotFound() {
    if (!mounted) return;

    setState(() {
      loading = false;
      creatorName = 'Post not found';
      content = '';
    });
  }

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

  // ================= TIME FORMAT =================

  String _formatTime(Timestamp? t) {
    if (t == null) return '';

    final d = t.toDate();

    return "${d.day.toString().padLeft(2, '0')}-"
        "${d.month.toString().padLeft(2, '0')}-"
        "${d.year} "
        "${d.hour.toString().padLeft(2, '0')}:"
        "${d.minute.toString().padLeft(2, '0')}";
  }

  // ================= UI =================

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
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
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
                  // ================= CHEF HEADER =================

                  Row(
                    children: [

                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFFF94449),
                        child: Text(
                          creatorName.isNotEmpty
                              ? creatorName[0].toUpperCase()
                              : "U",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),


                      const SizedBox(width: 10),


                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Row(
                              children: [

                                Flexible(
                                  child: Text(
                                    creatorName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 5),

                                const Icon(
                                  Icons.verified,
                                  size: 16,
                                  color: Color(0xFFF94449),
                                ),
                              ],
                            ),


                            const SizedBox(height: 5),


                            if (timestamp != null)
                              Text(
                                _formatTime(timestamp),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),

                          ],
                        ),
                      ),

                    ],
                  ),

                  const SizedBox(height: 10),

                  // Content
                  // ================= MENU CONTENT =================

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),

                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8F7),
                      borderRadius: BorderRadius.circular(14),
                    ),

                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        const Icon(
                          Icons.restaurant_menu,
                          color: Color(0xFFF94449),
                          size: 20,
                        ),

                        const SizedBox(width: 8),

                        Expanded(
                          child: _highlightText(content),
                        ),
                      ],
                    ),
                  ),


                  const SizedBox(height: 14),

                  // Buttons
                  Row(
                    children: [
                      if (!isOwnPost)
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _openChat,
                              icon: const Icon(Icons.chat_bubble_outline),
                              label: const Text("Chat"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF94449),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),

                      if (!isOwnPost)
                        const SizedBox(width: 10),

                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                            label: const Text("Close"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFF94449),
                              side: const BorderSide(
                                color: Color(0xFFF94449),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Distance
                  // ================= DISTANCE BADGE =================

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: Row(
                      mainAxisSize: MainAxisSize.min,

                      children: [

                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.blue,
                        ),

                        const SizedBox(width: 6),


                        Text(
                          (postLat != null &&
                              postLng != null &&
                              postLat != 0 &&
                              myLat != null &&
                              myLng != null)

                              ? "${_distanceInKm(
                            myLat!,
                            myLng!,
                            postLat!,
                            postLng!,
                          ).toStringAsFixed(2)} km away"

                              : "Distance unavailable",

                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Disclaimer
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