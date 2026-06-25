import 'package:flutter/material.dart';
import '../models/post.dart';
import 'package:carousel_slider/carousel_slider.dart';

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

  List<String> getMenuImages(String text) {
    final menu = text.toLowerCase();
    final images = <String>{};

    if (menu.contains('paneer')) {
      images.add('assets/images/paneer.jpg');
    }

    if (menu.contains('biryani')) {
      images.add('assets/images/biryani.jpg');
    }

    if (menu.contains('pizza')) {
      images.add('assets/images/pizza.jpeg');
    }

    if (menu.contains('momos')) {
      images.add('assets/images/momos.jpg');
    }

    if (menu.contains('burger')) {
      images.add('assets/images/burger.jpg');
    }

    if (menu.contains('cake')) {
      images.add('assets/images/cake.jpg');
    }

    if (menu.contains('chicken')) {
      images.add('assets/images/chicken.jpg');
    }

    if (menu.contains('daal') || menu.contains('dal')) {
      images.add('assets/images/daal.jpg');
    }

    if (menu.contains('samosa')) {
      images.add('assets/images/samosa.jpeg');
    }

    if (menu.contains('tiffin') || menu.contains('lunch') || menu.contains('dinner')  || menu.contains('thali')) {
      images.add('assets/images/tiffin.jpg');
    }

    if (menu.contains('vada pav') || menu.contains('vadapav')) {
      images.add('assets/images/vadapav.jpg');
    }

    if (menu.contains('sandwich') || menu.contains('sandwitch')) {
      images.add('assets/images/sandwich.jpeg');
    }

    if (menu.contains('paratha')) {
      images.add('assets/images/paratha.jpg');
    }

    if (menu.contains('drink') || menu.contains('shake')) {
      images.add('assets/images/drink.jpg');
    }

    if (images.isEmpty) {
      images.add('assets/images/default.jpg');
    }

    return images.toList();
  }

  @override
  Widget build(BuildContext context) {
    final creatorName = isOwnPost ? "You" : (post.creatorName ?? "Nearby User");

    final menuImages = getMenuImages(post.text);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ---------------- Header ----------------
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFF94449),
                  child: Text(
                    creatorName.isNotEmpty ? creatorName[0].toUpperCase() : "U",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        creatorName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF94449).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isOwnPost ? "Your Post" : "Chef",
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFF94449),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // only show menu for own post
                if (isOwnPost)
                  IconButton(
                    onPressed: onOptionsPressed,
                    icon: const Icon(Icons.more_horiz),
                  ),
              ],
            ),

            const SizedBox(height: 10),

// ---------------- Food Images ----------------
            if (menuImages.isNotEmpty) ...[
              CarouselSlider(
                options: CarouselOptions(
                  height: 180,
                  autoPlay: menuImages.length > 1,
                  autoPlayInterval: const Duration(seconds: 3),
                  enlargeCenterPage: true,
                  viewportFraction: 0.92,
                ),
                items: menuImages.map((imagePath) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      imagePath,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 12),

 // ---------------- Content ----------------
            Text(
              post.text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14.5,
                height: 1.35,
                color: Color(0xFF2B2B2B),
              ),
            ),

            const SizedBox(height: 10),

            // ---------------- Meta ----------------
            Row(
              children: [
                const Icon(Icons.access_time,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  timeText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),

                if (isOwnPost && post.views != null) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.visibility,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    "${post.views}",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),

            if (expireText != null) ...[
              const SizedBox(height: 6),
              Text(
                "⏳ Expires in $expireText",
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.redAccent,
                ),
              ),
            ],

            const SizedBox(height: 12),

            // ---------------- CTA ----------------
            // ---------------- Actions ----------------
            Column(
              children: [

                // View Full Menu (Filled)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onViewPressed,
                    icon: const Icon(Icons.restaurant_menu),
                    label: const Text("View Full Menu"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF94449),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Chat with Chef (Outlined)
                if (!isOwnPost)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onChatPressed,
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text("Chat with Chef"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFF94449),
                        side: const BorderSide(
                          color: Color(0xFFF94449),
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}