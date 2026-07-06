import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationBubble extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String address;
  final bool isMe;
  final dynamic timestamp;

  const LocationBubble({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.isMe,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment:
      isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(
          maxWidth: 280,
        ),
        decoration: BoxDecoration(
          color: isMe ? Colors.green[100] : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft:
            Radius.circular(isMe ? 18 : 4),
            bottomRight:
            Radius.circular(isMe ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Colors.red,
                ),
                SizedBox(width: 6),
                Text(
                  "Shared Location",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(address),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.map),
                label: const Text("Open in Google Maps"),
                onPressed: () async {
                  final Uri googleMaps = Uri.parse(
                    "geo:$latitude,$longitude?q=$latitude,$longitude",
                  );

                  final Uri browserMaps = Uri.parse(
                    "https://www.google.com/maps/search/?api=1&query=$latitude,$longitude",
                  );

                  if (await canLaunchUrl(googleMaps)) {
                    await launchUrl(
                      googleMaps,
                      mode: LaunchMode.externalApplication,
                    );
                  } else {
                    await launchUrl(
                      browserMaps,
                      mode: LaunchMode.platformDefault,
                    );
                  }
                },
              ),
            ),

            const SizedBox(height: 6),

            Align(
              alignment: Alignment.centerRight,
              child: Text(
                _formatTime(timestamp),
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(dynamic ts) {
    if (ts == null) return '';

    final dt = (ts as Timestamp).toDate();

    int hour = dt.hour % 12;
    if (hour == 0) hour = 12;

    final minute =
    dt.minute.toString().padLeft(2, '0');

    final ampm =
    dt.hour >= 12 ? 'PM' : 'AM';

    return "$hour:$minute $ampm";
  }
}