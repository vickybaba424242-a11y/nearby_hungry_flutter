import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nearby_hungry_flutter/chat/services/chat_image_service.dart';

class PaymentService {
  static const String upiId = "7417211941@ptyes";
  static const String phoneNumber = "7417211941";

  static Future<void> openUPI(
      BuildContext context, {
        required bool isCustomer,
        required String chatId,
        required String senderId,
      }) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Row(
          children: const [
            Icon(Icons.account_balance_wallet,
                color: Colors.deepOrange),
            SizedBox(width: 8),
            Text("Payment"),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "🚧 Online payments are coming soon!",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "To confirm your order, please make the payment using the details below.",
                style: TextStyle(fontSize: 15),
              ),

              const SizedBox(height: 20),

              // UPI CARD
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.qr_code,
                    color: Colors.deepPurple,
                  ),
                  title: const Text(
                    "UPI ID",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: SelectableText(
                    upiId,
                    style: const TextStyle(fontSize: 15),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(
                        const ClipboardData(text: upiId),
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("UPI ID copied"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // PHONE CARD
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.phone_android,
                    color: Colors.green,
                  ),
                  title: const Text(
                    "Phone Number",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: SelectableText(
                    phoneNumber,
                    style: const TextStyle(fontSize: 15),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(
                        const ClipboardData(text: phoneNumber),
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Phone number copied"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.orange.shade200,
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "After completing the payment, please share the payment screenshot with the chef in the chat. Your order will be confirmed after payment verification.",
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (isCustomer)
            TextButton.icon(
              icon: const Icon(Icons.image),
              label: const Text("Upload Payment Screenshot"),
              onPressed: () async {
                Navigator.pop(dialogContext);

                final picker = ImagePicker();

                final XFile? image = await picker.pickImage(
                  source: ImageSource.gallery,
                );

                if (image == null) return;

                final imageUrl = await ChatImageService.uploadImage(
                  image,
                  chatId,
                );

                await FirebaseFirestore.instance
                    .collection('chats')
                    .doc(chatId)
                    .collection('messages')
                    .add({
                  "type": "image",
                  "imageUrl": imageUrl,
                  "senderId": senderId,
                  "timestamp": FieldValue.serverTimestamp(),
                  "seen": false,
                });
              },
            ),

          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }
}