import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ChatImageService {
  static Future<String> uploadImage(
      XFile image,
      String chatId,
      ) async {
    final file = File(image.path);

    // Maximum 5 MB
    final size = await file.length();

    if (size > 5 * 1024 * 1024) {
      throw Exception("Image must be smaller than 5 MB.");
    }

    final fileName =
        "${DateTime.now().millisecondsSinceEpoch}.jpg";

    final ref = FirebaseStorage.instance
        .ref()
        .child("paymentScreenshots")
        .child(chatId)
        .child(fileName);

    await ref.putFile(file);

    return await ref.getDownloadURL();
  }
}