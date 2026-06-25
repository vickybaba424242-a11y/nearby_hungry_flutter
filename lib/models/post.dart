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

  final String? phone;
  final String? visibilityType;
  final int? views;

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
    this.views,
  });

  factory Post.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    double lat = 0.0;
    double lng = 0.0;

    // ✅ New GeoFlutterFire structure
    final position = data['position'];

    if (position is Map && position['geopoint'] is GeoPoint) {
      final gp = position['geopoint'] as GeoPoint;
      lat = gp.latitude;
      lng = gp.longitude;
    }

    // ✅ Old fallback support
    else {
      lat = (data['latitude'] ?? 0.0).toDouble();
      lng = (data['longitude'] ?? 0.0).toDouble();
    }

    return Post(
      id: doc.id,
      creatorId: data['creatorId'] ?? '',
      creatorName: data['creatorName'] ?? '',
      text: (data['text'] ?? data['content'] ?? '') as String,

      latitude: lat,
      longitude: lng,

      timestamp: data['timestamp'] as Timestamp?,
      expireAt: data['expireAt'] as Timestamp?,

      phone: data['phone'] as String?,
      visibilityType: data['visibilityType'] as String?,

      views: data['views'] != null
          ? (data['views'] as num).toInt()
          : 0,
    );
  }

  factory Post.fromMap(Map<String, dynamic> data, String id) {

    double lat = 0.0;
    double lng = 0.0;

    // ✅ New GeoFlutterFire structure
    final position = data['position'];

    if (position is Map && position['geopoint'] is GeoPoint) {
      final gp = position['geopoint'] as GeoPoint;
      lat = gp.latitude;
      lng = gp.longitude;
    }

    // ✅ Old fallback support
    else {
      lat = (data['latitude'] ?? 0.0).toDouble();
      lng = (data['longitude'] ?? 0.0).toDouble();
    }

    return Post(
      id: id,
      creatorId: data['creatorId'] ?? '',
      creatorName: data['creatorName'] ?? '',
      text: (data['text'] ?? data['content'] ?? '') as String,

      latitude: lat,
      longitude: lng,

      timestamp: data['timestamp'] as Timestamp?,
      expireAt: data['expireAt'] as Timestamp?,

      phone: data['phone'] as String?,
      visibilityType: data['visibilityType'] as String?,

      views: data['views'] != null
          ? (data['views'] as num).toInt()
          : 0,
    );
  }
}