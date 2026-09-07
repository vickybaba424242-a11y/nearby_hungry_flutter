import 'package:flutter/material.dart';
import '../models/post.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/chef_reviews_screen.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final bool isOwnPost;
  final VoidCallback onViewPressed;
  final VoidCallback onChatPressed;
  final VoidCallback onOptionsPressed;
  final String timeText;
  final String? expireText;
  final String searchText;

  const PostCard({
    super.key,
    required this.post,
    required this.isOwnPost,
    required this.timeText,
    this.expireText,
    required this.onViewPressed,
    required this.onChatPressed,
    required this.onOptionsPressed,
    this.searchText = "",
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

    if (menu.contains('chicken biryani')) {
      images.add('assets/images/chickenbiryani.jpg');
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

    if (menu.contains('kadhi')) {
      images.add('assets/images/kadhi.jpg');
    }

    if (menu.contains('chole') || menu.contains('chhole')) {
      images.add('assets/images/chole.jpg');
    }

    if (menu.contains('rajma') || menu.contains('raajma')) {
      images.add('assets/images/rajma.jpg');
    }

    if (menu.contains('noodles') || menu.contains('noodle')) {
      images.add('assets/images/noodles.jpg');
    }

    if (menu.contains('poori') || menu.contains('puri')) {
      images.add('assets/images/poori.jpg');
    }

    if (menu.contains('idli') || menu.contains('idly')) {
      images.add('assets/images/idli.jpg');
    }

    if (menu.contains('dosa') || menu.contains('dhosa')) {
      images.add('assets/images/dosa.jpg');
    }

    if (menu.contains('coffee') || menu.contains('cofee')) {
      images.add('assets/images/coffee.jpg');
    }

    if (images.isEmpty) {
      images.add('assets/images/default.jpg');
    }

    return images.toList();
  }

  Widget highlightText(String text, String query) {
    if (query.trim().isEmpty) {
      return Text(
        text,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 14.5,
          height: 1.35,
          color: Color(0xFF2B2B2B),
        ),
      );
    }

    final matches = <TextSpan>[];

    final pattern = RegExp(
      RegExp.escape(query),
      caseSensitive: false,
    );

    int lastMatchEnd = 0;

    for (final match in pattern.allMatches(text)) {

      // Normal text before match
      if (match.start > lastMatchEnd) {
        matches.add(
          TextSpan(
            text: text.substring(lastMatchEnd, match.start),
            style: const TextStyle(
              fontSize: 14.5,
              height: 1.35,
              color: Color(0xFF2B2B2B),
            ),
          ),
        );
      }


      // Highlight text
      matches.add(
        TextSpan(
          text: text.substring(match.start, match.end),
          style: const TextStyle(
            fontSize: 14.5,
            height: 1.35,
            color: Color(0xFFF94449),
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      lastMatchEnd = match.end;
    }


    // Remaining text after last match
    if (lastMatchEnd < text.length) {
      matches.add(
        TextSpan(
          text: text.substring(lastMatchEnd),
          style: const TextStyle(
            fontSize: 14.5,
            height: 1.35,
            color: Color(0xFF2B2B2B),
          ),
        ),
      );
    }


    return Text.rich(
      TextSpan(
        children: matches,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
  @override
  Widget build(BuildContext context) {
    final creatorName = isOwnPost ? "You" : (post.creatorName ?? "Nearby User");

    final user = FirebaseAuth.instance.currentUser;

    final bool isAdmin =
        user?.email?.toLowerCase() == 'nearbyhungry@gmail.com';

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
            // ---------------- Header ----------------
            Row(
              children: [

                // Chef Avatar
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF94449),
                  ),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white,
                    child: Text(
                      creatorName.isNotEmpty
                          ? creatorName[0].toUpperCase()
                          : "U",
                      style: const TextStyle(
                        color: Color(0xFFF94449),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Row(
                        children: [

                          Flexible(
                            child: Text(
                              creatorName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),

                          const SizedBox(width: 4),

                          // Verified Badge
                          const Icon(
                            Icons.verified,
                            color: Color(0xFFF94449),
                            size: 16,
                          ),

                          const SizedBox(width: 8),


                          // Rating
                          StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(post.creatorId)
                                .snapshots(),

                            builder: (context, snapshot) {

                              double rating = 0;
                              int totalRatings = 0;


                              if (snapshot.hasData &&
                                  snapshot.data!.exists) {

                                final data =
                                snapshot.data!.data()
                                as Map<String, dynamic>;

                                rating =
                                    (data['rating'] ?? 0).toDouble();

                                totalRatings =
                                    data['totalRatings'] ?? 0;
                              }


                              return GestureDetector(
                                onTap: () {

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChefReviewsScreen(
                                        chefId: post.creatorId,
                                        chefName: post.creatorName ?? "Chef",
                                      ),
                                    ),
                                  );

                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),

                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),

                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [

                                      const Icon(
                                        Icons.star,
                                        size: 13,
                                        color: Colors.amber,
                                      ),

                                      const SizedBox(width: 3),

                                      Text(
                                        rating.toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                      Text(
                                        " ($totalRatings) ",
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),

                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),


                      const SizedBox(height: 5),

                      Wrap(
                        spacing: 6,
                        children: [

                          // Chef Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF94449)
                                  .withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isOwnPost ? "Your Post" : "HomeChef",
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFFF94449),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),


                // More button
                // More button
                if (isOwnPost || isAdmin)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: onOptionsPressed,
                      icon: const Icon(
                        Icons.more_horiz,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

// ---------------- Food Images ----------------
            // ---------------- Premium Food Images ----------------
            if (menuImages.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  height: 160,
                  child: CarouselSlider(
                    options: CarouselOptions(
                      height: 160,
                      viewportFraction: 1,
                      autoPlay: menuImages.length > 1,
                      autoPlayInterval: const Duration(seconds: 3),
                      enlargeCenterPage: false,
                    ),
                    items: menuImages.map((imagePath) {
                      return Stack(
                        fit: StackFit.expand,
                        children: [

                          // Food Image
                          Image.asset(
                            imagePath,
                            fit: BoxFit.cover,
                          ),

                          // Dark Gradient
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(.55),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Fresh Today Badge
                          Positioned(
                            left: 12,
                            top: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.eco,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    "Fresh Today",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Bottom Text
                          Positioned(
                            left: 16,
                            bottom: 18,
                            right: 16,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                Text(
                                  creatorName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                const Text(
                                  "Delicious Homemade Food",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 8),
            ],

            // ---------------- Meta ----------------
            if (isOwnPost || isAdmin)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      size: 16,
                      color: Color(0xFFF94449),
                    ),

                    const SizedBox(width: 6),

                    Text(
                      timeText,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const Spacer(),

                    if (isOwnPost && post.views != null) ...[
                      const Icon(
                        Icons.visibility_outlined,
                        size: 16,
                        color: Color(0xFFF94449),
                      ),

                      const SizedBox(width: 5),

                      Text(
                        "${post.views}",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            if (expireText != null) ...[
              const SizedBox(height: 6),
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [

                    const Icon(
                      Icons.timer,
                      color: Colors.red,
                      size: 16,
                    ),

                    const SizedBox(width: 6),

                    Expanded(
                      child: Text(
                        "Available for another $expireText",
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // ---------------- CTA ----------------
            // ---------------- Actions ----------------
            Row(
              children: [

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onViewPressed,
                    icon: const Icon(Icons.restaurant_menu,size:18),
                    label: const Text("Menu"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF94449),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),

                if (!isOwnPost) ...[
                  const SizedBox(width: 10),

                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onChatPressed,
                      icon: const Icon(Icons.chat,size:18),
                      label: const Text("Chat"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFF94449),
                        minimumSize: const Size.fromHeight(44),
                        side: const BorderSide(
                          color: Color(0xFFF94449),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}