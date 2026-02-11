import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String creatorId;
  final String creatorName;
  final String text;
  final double latitude;
  final double longitude;
  final Timestamp? timestamp;
  final Timestamp? expireAt;

  final String? phone;           // from add_post_page
  final String? visibilityType;  // from add_post_page
  final int? views;              // ✅ add this

  Post({
    required this.id,
    required this.creatorId,
    required this.creatorName,
    required this.text,
    required this.latitude,
    required this.longitude,
    this.timestamp,
    this.expireAt,
    this.phone,
    this.visibilityType,
    this.views,                  // ✅ add this
  });

  factory Post.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Post(
      id: doc.id,
      creatorId: data['creatorId'] ?? '',
      creatorName: data['creatorName'] ?? '',
      text: (data['text'] ?? data['content'] ?? '') as String,
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      timestamp: data['timestamp'] as Timestamp?,
      expireAt: data['expireAt'] as Timestamp?,
      phone: data['phone'] as String?,
      visibilityType: data['visibilityType'] as String?,
      views: data['views'] != null ? (data['views'] as num).toInt() : 0, // ✅ handle null
    );
  }
}