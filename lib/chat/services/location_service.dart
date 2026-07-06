import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<void> shareLocation({
    required String chatId,
    required String currentUserId,
    required String otherUserId,
  }) async {
    final FirebaseFirestore db = FirebaseFirestore.instance;

    // Check permission
    LocationPermission permission =
    await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception("Location permission denied");
    }

    // Current location
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Address
    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    final place = placemarks.first;

    final address =
        "${place.name ?? ""}, "
        "${place.street ?? ""}, "
        "${place.locality ?? ""}, "
        "${place.administrativeArea ?? ""}, "
        "${place.postalCode ?? ""}";

    // Save location message
    await db
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .add({
      "type": "location",
      "senderId": currentUserId,
      "latitude": position.latitude,
      "longitude": position.longitude,
      "address": address,
      "timestamp": FieldValue.serverTimestamp(),
      "seen": false,
    });

    // Update chat document
    await db.collection("chats").doc(chatId).set({
      "lastMessage": "📍 Shared Location",
      "lastMessageTime": FieldValue.serverTimestamp(),
      "unreadCount_$otherUserId": FieldValue.increment(1),
    }, SetOptions(merge: true));
  }
}