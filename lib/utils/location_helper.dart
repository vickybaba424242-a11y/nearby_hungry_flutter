// lib/utils/location_helper.dart
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';

class LocationHelper {
  static Future<Position?> getCurrentLocation(BuildContext context) async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}
