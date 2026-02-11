import 'package:flutter/material.dart';
import '../models/post.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final bool isOwnPost;
  final VoidCallback onViewPressed;
  final VoidCallback onChatPressed;
  final VoidCallback onOptionsPressed;
  final String timeText;
  final String? expireText;

  const PostCard({
    super.key,
    required this.post,
    required this.isOwnPost,
    required this.timeText,
    this.expireText,
    required this.onViewPressed,
    required this.onChatPressed,
    required this.onOptionsPressed,
  });

  @override
  Widget build(BuildContext context) {
    final creatorName = isOwnPost ? "You" : (post.creatorName ?? "Nearby User");

    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ---------------- Header ----------------
            Row(
              children: [
                Expanded(
                  child: Text(
                    creatorName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isOwnPost)
                  IconButton(
                    onPressed: onOptionsPressed,
                    icon: const Icon(Icons.more_vert),
                  ),
              ],
            ),

            // ---------------- Chat with chef ----------------
            if (!isOwnPost)
              GestureDetector(
                onTap: onChatPressed,
                child: const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Text(
                    "💬 Chat with Chef",
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFFFF7B00),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 6),

            // ---------------- Content ----------------
            Text(
              post.text, // use text for the post content
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF222222),
              ),
            ),

            const SizedBox(height: 6),

            // ---------------- Time + views ----------------
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF888888),
                  ),
                ),
                if (isOwnPost && post.views != null) ...[
                  const Text(
                    " • ",
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF888888),
                    ),
                  ),
                  Text(
                    "👀 ${post.views} views",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF888888),
                    ),
                  ),
                ],
              ],
            ),

            // ---------------- Expire ----------------
            if (expireText != null) ...[
              const SizedBox(height: 2),
              Text(
                "⏳ Expires: $expireText",
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFD32F2F),
                ),
              ),
            ],

            const SizedBox(height: 8),

            // ---------------- View button ----------------
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onViewPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7B00),
                  foregroundColor: Colors.white,
                ),
                child: const Text("View"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
