import 'package:cloud_firestore/cloud_firestore.dart';

class MenuVariant {
  final String name;
  final double price;

  MenuVariant({
    required this.name,
    required this.price,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
    };
  }

  factory MenuVariant.fromMap(Map<String, dynamic> data) {
    return MenuVariant(
      name: data['name'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
    );
  }
}

class MenuItem {
  final String name;
  final double price;
  final String? description;
  final String category;

  // Existing variant support
  final List<MenuVariant> variants;

  MenuItem({
    required this.name,
    required this.price,
    this.description,
    this.category = 'Menu',
    this.variants = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'description': description ?? '',
      'category': category,
      'variants': variants.map((v) => v.toMap()).toList(),
    };
  }

  factory MenuItem.fromMap(Map<String, dynamic> data) {
    final List<MenuVariant> variants = [];

    if (data['variants'] is List) {
      for (final item in data['variants']) {
        if (item is Map) {
          variants.add(
            MenuVariant.fromMap(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    return MenuItem(
      name: data['name'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      description: data['description'],
      category: data['category'] ?? 'Menu',
      variants: variants,
    );
  }
}

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
  final String? address; // ADD THIS
  final String? visibilityType;
  final int? views;
  final double rating;
  final int totalRatings;
  final String providerType;

  final List<MenuItem> menuItems;

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
    this.address, // ADD THIS
    this.visibilityType,
    this.views,
    this.rating = 0.0,
    this.totalRatings = 0,
    this.providerType = 'homeChef',
    this.menuItems = const [],
  });

  factory Post.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    double lat = 0.0;
    double lng = 0.0;

    final position = data['position'];

    if (position is Map && position['geopoint'] is GeoPoint) {
      final gp = position['geopoint'] as GeoPoint;
      lat = gp.latitude;
      lng = gp.longitude;
    } else {
      lat = (data['latitude'] ?? 0.0).toDouble();
      lng = (data['longitude'] ?? 0.0).toDouble();
    }

    final List<MenuItem> menuItems = [];

    if (data['menuItems'] is List) {
      for (final item in data['menuItems']) {
        if (item is Map) {
          menuItems.add(
            MenuItem.fromMap(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
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
      address: data['address'] as String?,
      visibilityType: data['visibilityType'] as String?,
      views: data['views'] != null
          ? (data['views'] as num).toInt()
          : 0,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: (data['totalRatings'] as num?)?.toInt() ?? 0,
      providerType: data['providerType'] ?? 'homeChef',
      menuItems: menuItems,
    );
  }

  factory Post.fromMap(
      Map<String, dynamic> data,
      String id,
      ) {
    double lat = 0.0;
    double lng = 0.0;

    final position = data['position'];

    if (position is Map && position['geopoint'] is GeoPoint) {
      final gp = position['geopoint'] as GeoPoint;
      lat = gp.latitude;
      lng = gp.longitude;
    } else {
      lat = (data['latitude'] ?? 0.0).toDouble();
      lng = (data['longitude'] ?? 0.0).toDouble();
    }

    final List<MenuItem> menuItems = [];

    if (data['menuItems'] is List) {
      for (final item in data['menuItems']) {
        if (item is Map) {
          menuItems.add(
            MenuItem.fromMap(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
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
      address: data['address'] as String?,
      visibilityType: data['visibilityType'] as String?,
      views: data['views'] != null
          ? (data['views'] as num).toInt()
          : 0,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: (data['totalRatings'] as num?)?.toInt() ?? 0,
      providerType: data['providerType'] ?? 'homeChef',
      menuItems: menuItems,
    );
  }
}