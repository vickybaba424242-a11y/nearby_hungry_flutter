import 'package:flutter/material.dart';

class PostCard extends StatelessWidget {
  final String creator;
  final String content;
  final String timestamp;
  final String? expireText;
  final bool showOptions;
  final bool showViews;
  final int views;
  final VoidCallback? onChatTap;
  final VoidCallback? onViewTap;

  const PostCard({
    super.key,
    required this.creator,
    required this.content,
    required this.timestamp,
    this.expireText,
    this.showOptions = false,
    this.showViews = false,
    this.views = 0,
    this.onChatTap,
    this.onViewTap,
  });

  @override
  Widget build(BuildContext context) {
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    creator,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                if (showOptions)
                  IconButton(
                    icon: const Icon(Icons.more_vert,
                        color: Color(0xFF666666)),
                    onPressed: () {},
                  ),
              ],
            ),

            GestureDetector(
              onTap: onChatTap,
              child: const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text(
                  '💬 Chat with Chef',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF7B00),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF222222),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timestamp,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF888888),
                    ),
                  ),
                  if (showViews) ...[
                    const Text(
                      ' • ',
                      style: TextStyle(
                          fontSize: 12, color: Color(0xFF888888)),
                    ),
                    Text(
                      '👀 $views views',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF888888),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            if (expireText != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '⏳ Expires: $expireText',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFD32F2F),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7B00),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: onViewTap,
                  child: const Text('View'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
