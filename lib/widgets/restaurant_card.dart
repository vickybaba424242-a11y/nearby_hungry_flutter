  import 'package:flutter/material.dart';
  import 'package:google_fonts/google_fonts.dart';
  import '../models/post.dart';
  import 'package:provider/provider.dart';
  import '../providers/cart_provider.dart';
  import '../screens/cart_page.dart';
  import '../screens/full_menu_page.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:carousel_slider/carousel_slider.dart';
  
  class RestaurantCard extends StatefulWidget {
    final Post post;
    final bool isOwnPost;
  
    final String searchText;
    final VoidCallback? onRatingPressed;
    final VoidCallback? onViewPressed;
    final VoidCallback? onChatPressed;
    final VoidCallback? onOptionsPressed;
    final VoidCallback? onAdminOptionsPressed;
  
    const RestaurantCard({
      super.key,
      required this.post,
      required this.isOwnPost,
      this.searchText = '',
      this.onViewPressed,
      this.onChatPressed,
      this.onRatingPressed,
      this.onOptionsPressed,
      this.onAdminOptionsPressed,
    });
  
    @override
    State<RestaurantCard> createState() => _RestaurantCardState();
  
  }
  class _RestaurantCardState extends State<RestaurantCard> {

    void _addToCartWithVariant(
        BuildContext context,
        MenuItem item,
        MenuVariant? variant,
        ) {
      final cart = context.read<CartProvider>();

      // ============================================================
      // CART IS EMPTY
      // ============================================================

      if (cart.isEmpty) {
        cart.addItem(
          widget.post,
          item,
          variant: variant,
        );
        return;
      }

      // ============================================================
      // SAME RESTAURANT / CHEF
      // ============================================================

      if (!cart.isDifferentRestaurant(widget.post)) {
        cart.addItem(
          widget.post,
          item,
          variant: variant,
        );
        return;
      }

      // ============================================================
      // DIFFERENT RESTAURANT / CHEF
      // ============================================================

      _showDifferentRestaurantDialogWithVariant(
        context,
        item,
        variant,
      );
    }

    List<String> getMenuImages(String text) {
      final menu = text.toLowerCase();
      final images = <String>{};

      if (menu.contains('paneer')) {
        images.add('assets/images/paneer.jpg');
      }

      if (menu.contains('chicken biryani')) {
        images.add('assets/images/chickenbiryani.jpg');
      } else if (menu.contains('biryani')) {
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

      if (menu.contains('tiffin') ||
          menu.contains('lunch') ||
          menu.contains('dinner') ||
          menu.contains('thali')) {
        images.add('assets/images/tiffin.jpg');
      }

      if (menu.contains('vada pav') ||
          menu.contains('vadapav')) {
        images.add('assets/images/vadapav.jpg');
      }

      if (menu.contains('sandwich') ||
          menu.contains('sandwitch')) {
        images.add('assets/images/sandwich.jpeg');
      }

      if (menu.contains('paratha')) {
        images.add('assets/images/paratha.jpg');
      }

      if (menu.contains('drink') ||
          menu.contains('shake')) {
        images.add('assets/images/drink.jpg');
      }

      if (menu.contains('kadhi')) {
        images.add('assets/images/kadhi.jpg');
      }

      if (menu.contains('chole') ||
          menu.contains('chhole')) {
        images.add('assets/images/chole.jpg');
      }

      if (menu.contains('rajma') ||
          menu.contains('raajma')) {
        images.add('assets/images/rajma.jpg');
      }

      if (menu.contains('noodles') ||
          menu.contains('noodle')) {
        images.add('assets/images/noodles.jpg');
      }

      if (menu.contains('poori') ||
          menu.contains('puri')) {
        images.add('assets/images/poori.jpg');
      }

      if (menu.contains('idli') ||
          menu.contains('idly')) {
        images.add('assets/images/idli.jpg');
      }

      if (menu.contains('dosa') ||
          menu.contains('dhosa')) {
        images.add('assets/images/dosa.jpg');
      }

      if (menu.contains('coffee') ||
          menu.contains('cofee')) {
        images.add('assets/images/coffee.jpg');
      }

      if (images.isEmpty) {
        images.add('assets/images/default.jpg');
      }

      return images.toList();
    }

    Widget _buildFoodImages() {
      final menuImages = getMenuImages(widget.post.text);

      if (menuImages.isEmpty) {
        return const SizedBox.shrink();
      }

      return ClipRRect(
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

                  // FOOD IMAGE
                  Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                  ),

                  // DARK GRADIENT
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

                  // FRESH TODAY
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

                  // RESTAURANT NAME
                  Positioned(
                    left: 16,
                    bottom: 18,
                    right: 16,
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [

                        Text(
                          widget.post.creatorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),

                        const SizedBox(height: 4),

                        const Text(
                          "Delicious Food Near You",
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
      );
    }

    Widget _buildViewFullMenuButton(BuildContext context) {
      final menuItems = widget.post.menuItems;

      final itemCount = menuItems.length;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullMenuPage(
                    restaurant: widget.post,
                    searchText: widget.searchText,
                  ),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF27AE60),
              side: const BorderSide(
                color: Color(0xFF27AE60),
                width: 1.2,
              ),
              backgroundColor: const Color(0xFFF8FFF9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.restaurant_menu,
                  size: 18,
                ),

                const SizedBox(width: 8),

                Text(
                  itemCount > 0
                      ? "View Full Menu • $itemCount items"
                      : "View Full Menu",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(width: 6),

                const Icon(
                  Icons.arrow_forward_ios,
                  size: 13,
                ),
              ],
            ),
          ),
        ),
      );
    }

    void _showDifferentRestaurantDialogWithVariant(
        BuildContext context,
        MenuItem item,
        MenuVariant? variant,
        ) {
      final cart = context.read<CartProvider>();

      final oldChefName =
          cart.restaurant?.creatorName ?? 'another chef';

      final newItemName = variant == null
          ? item.name
          : '${item.name} - ${variant.name}';

      showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),

            title: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.shopping_cart_outlined,
                    color: Color(0xFFF57C00),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    "Start a new cart?",
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            content: Text(
              "Your cart already contains items from "
                  "$oldChefName.\n\n"
                  "You are trying to add "
                  "$newItemName from "
                  "${widget.post.creatorName}.\n\n"
                  "Your current cart will be cleared "
                  "and this item will be added instead.",
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),

            actionsPadding: const EdgeInsets.fromLTRB(
              16,
              0,
              16,
              14,
            ),

            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: Text(
                  "Cancel",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),

              ElevatedButton(
                onPressed: () {
                  // Clear old chef's cart
                  cart.clearCart();

                  // Add selected item from new chef
                  cart.addItem(
                    widget.post,
                    item,
                    variant: variant,
                  );

                  Navigator.pop(dialogContext);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF27AE60),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  "Clear & Add",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      );
    }
  
    void _addToCart(
        BuildContext context,
        MenuItem item,
        ) {
      final cart = context.read<CartProvider>();
  
      // No existing cart → directly add
      if (cart.isEmpty) {
        cart.addItem(widget.post, item);
        return;
      }
  
      // Same restaurant → directly add
      if (!cart.isDifferentRestaurant(widget.post)) {
        cart.addItem(widget.post, item);
        return;
      }
  
      // Different restaurant → ask user
      _showDifferentRestaurantDialog(
        context,
        item,
      );
    }
  
    void _showDifferentRestaurantDialog(
        BuildContext context,
        MenuItem item,
        ) {
      final cart = context.read<CartProvider>();
  
      showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.shopping_cart_outlined,
                    color: Color(0xFFF57C00),
                  ),
                ),
  
                const SizedBox(width: 12),
  
                Expanded(
                  child: Text(
                    "Start a new cart?",
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
  
            content: Text(
              "Your cart contains items from "
                  "${cart.restaurant?.creatorName ?? 'another restaurant'}.\n\n"
                  "Your current cart will be cleared and "
                  "this item will be added instead.",
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
  
            actionsPadding: const EdgeInsets.fromLTRB(
              16,
              0,
              16,
              14,
            ),
  
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: Text(
                  "Cancel",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
  
              ElevatedButton(
                onPressed: () {
                  cart.clearCart();
  
                  cart.addItem(
                    widget.post,
                    item,
                  );
  
                  Navigator.pop(dialogContext);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF27AE60),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  "Clear & Add",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      );
    }
  
    Widget _highlightText(
        String text,
        String query,
        ) {
      final cleanQuery = query.trim();
  
      // No search text
      if (cleanQuery.isEmpty) {
        return Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF222222),
          ),
        );
      }
  
      final lowerText = text.toLowerCase();
      final lowerQuery = cleanQuery.toLowerCase();
  
      final startIndex = lowerText.indexOf(lowerQuery);
  
      // Search text not found in this item
      if (startIndex == -1) {
        return Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF222222),
          ),
        );
      }
  
      final endIndex = startIndex + lowerQuery.length;
  
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: text.substring(0, startIndex),
            ),
  
            TextSpan(
              text: text.substring(startIndex, endIndex),
              style: const TextStyle(
                color: Color(0xFFF94449),
                backgroundColor: Color(0xFFFFE0E0),
                fontWeight: FontWeight.w800,
              ),
            ),
  
            TextSpan(
              text: text.substring(endIndex),
            ),
          ],
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF222222),
          ),
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }
  
    @override
    Widget build(BuildContext context) {
  
      final user = FirebaseAuth.instance.currentUser;
  
      final bool isAdmin =
          user?.email?.toLowerCase() == 'nearbyhungry@gmail.com';
      return Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
  
            // =====================================================
            // RESTAURANT HEADER
            // =====================================================
  
            Padding(
              padding: const EdgeInsets.fromLTRB(
                14,
                14,
                8,
                8,
              ),
              child: Row(
                children: [
  
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        widget.post.providerType == 'homeChef'
                            ? "👨‍🍳"
                            : "🍽️",
                        style: const TextStyle(
                          fontSize: 25,
                        ),
                      ),
                    ),
                  ),
  
                  const SizedBox(width: 12),
  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
  
                        // NAME + VERIFIED + RATING
                        Row(
                          children: [
  
                            // Restaurant / Home Chef Name
                            Flexible(
                              child: Text(
                                widget.post.creatorName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF222222),
                                ),
                              ),
                            ),
  
                            const SizedBox(width: 4),
  
                            // Verified
                            const Icon(
                              Icons.verified,
                              color: Color(0xFFF94449),
                              size: 16,
                            ),
  
                            const SizedBox(width: 8),
  
                            // RATING
                            StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(widget.post.creatorId)
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
                                  (data['totalRatings'] ?? 0) as int;
                                }
  
                                return GestureDetector(
                                  onTap: widget.onRatingPressed,
  
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
                                          totalRatings > 0
                                              ? rating.toStringAsFixed(1)
                                              : "New",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
  
                                        if (totalRatings > 0)
                                          Text(
                                            " ($totalRatings)",
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
  
                        // PROVIDER TYPE
                        Wrap(
                          spacing: 6,
                          children: [
  
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
                                widget.isOwnPost
                                    ? "Your Post"
                                    : widget.post.providerType == 'homeChef'
                                    ? "Home Chef"
                                    : widget.post.providerType == 'restaurant'
                                    ? "Restaurant"
                                    : widget.post.providerType == 'cloudKitchen'
                                    ? "Cloud Kitchen"
                                    : widget.post.providerType == 'tiffinService'
                                    ? "Tiffin Service"
                                    : "Food Provider",
  
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

                  if (widget.isOwnPost || isAdmin)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () {
                          debugPrint(
                            'THREE DOT CLICKED | '
                                'isOwnPost=${widget.isOwnPost} | '
                                'isAdmin=$isAdmin',
                          );

                          if (isAdmin && !widget.isOwnPost) {
                            debugPrint('Calling ADMIN options');

                            if (widget.onAdminOptionsPressed != null) {
                              widget.onAdminOptionsPressed!();
                            } else {
                              debugPrint('ERROR: onAdminOptionsPressed is NULL');
                            }
                          } else {
                            debugPrint('Calling OWNER options');

                            if (widget.onOptionsPressed != null) {
                              widget.onOptionsPressed!();
                            } else {
                              debugPrint('ERROR: onOptionsPressed is NULL');
                            }
                          }
                        },
                        icon: const Icon(
                          Icons.more_vert,
                          size: 24,
                        ),
                      ),
                    ),
                ],
              ),
            ),
  
            // =====================================================
            // RESTAURANT DESCRIPTION
            // =====================================================
  
            if (widget.post.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                child: Text(
                  widget.post.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
  
            const SizedBox(height: 8),

            // =====================================================
// FOOD IMAGE CAROUSEL
// =====================================================

            _buildFoodImages(),

            const SizedBox(height: 10),

// =====================================================
// VIEW FULL MENU
// =====================================================

            _buildViewFullMenuButton(context),

            const SizedBox(height: 10),

            const Divider(
              height: 1,
              thickness: 0.8,
            ),
  
            // =====================================================
            // BOTTOM ACTIONS
            // =====================================================
  
            Consumer<CartProvider>(
              builder: (context, cart, child) {
  
                final hasItems = cart.totalItems > 0 &&
                    cart.restaurant?.id == widget.post.id;
  
                return Column(
                  children: [
  
                    // ---------------------------------------------
                    // VIEW CART BUTTON
                    // ---------------------------------------------
  
                    if (hasItems)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          12,
                          8,
                          12,
                          4,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
  
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CartPage(),
                                ),
                              );
  
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF27AE60),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
  
                                const Icon(
                                  Icons.shopping_cart,
                                  size: 20,
                                ),
  
                                const SizedBox(width: 8),
  
                                Expanded(
                                  child: Text(
                                    "${cart.totalItems} ${cart.totalItems == 1 ? 'item' : 'items'}",
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
  
                                const SizedBox(width: 8),
  
                                Text(
                                  "₹${cart.totalAmount.toStringAsFixed(0)}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
  
                              ],
                            ),
                          ),
                        ),
                      ),
  
                    // ---------------------------------------------
  // VIEW RESTAURANT + CHAT
  // ---------------------------------------------
  
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
  
                          // -----------------------------------------
                          // VIEW RESTAURANT
                          // -----------------------------------------
  
                          Expanded(
                            child: TextButton.icon(
                              onPressed: widget.onViewPressed,
                              icon: const Icon(
                                Icons.restaurant_menu,
                                size: 18,
                              ),
                              label: Text(
                                "View Restaurant",
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
  
                          // -----------------------------------------
                          // DIVIDER
                          // -----------------------------------------
  
                          Container(
                            width: 1,
                            height: 28,
                            color: Colors.grey.shade300,
                          ),
  
                          // -----------------------------------------
                          // CHAT
                          // -----------------------------------------
  
                          Expanded(
                            child: TextButton.icon(
                              onPressed: widget.onChatPressed,
                              icon: const Icon(
                                Icons.chat_bubble_outline,
                                size: 18,
                              ),
                              label: Text(
                                "Chat",
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
  
                  ],
                );
              },
            ),
          ],
        ),
      );
    }
  
    Widget _buildLimitedMenu(
        BuildContext context,
        List<MenuItem> menuItems,
        ) {
      const int maxVisibleItems = 3;
  
      final visibleItems = menuItems
          .take(maxVisibleItems)
          .toList();
  
      final remainingItems =
          menuItems.length - visibleItems.length;
  
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...visibleItems.map(
                (item) => _menuItem(
              context,
              item,
            ),
          ),
  
          if (remainingItems > 0)
            Padding(
              padding: const EdgeInsets.only(
                top: 8,
                bottom: 4,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 40,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FullMenuPage(
                          restaurant: widget.post,
                          searchText: widget.searchText,
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF27AE60),
                    side: const BorderSide(
                      color: Color(0xFF27AE60),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    "View Full Menu • $remainingItems more items",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    }
  
    Widget _menuItem(
        BuildContext context,
        MenuItem item,
        ) {
      final hasVariants = item.variants.isNotEmpty;
  
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade200,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // COLORFUL FOOD INDICATOR
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFFF3E0),
                    Color(0xFFFFE0B2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Center(
                child: Icon(
                  Icons.restaurant_menu,
                  size: 17,
                  color: Color(0xFFF57C00),
                ),
              ),
            ),
            const SizedBox(width: 10),
  
            // ITEM NAME
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
  
                  _highlightText(
                    item.name,
                    widget.searchText,
                  ),
  
                  if (item.description != null &&
                      item.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        item.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
  
                  const SizedBox(height: 4),
  
                  // PRICE SHOWN ON CARD
                  if (hasVariants)
                    Text(
                      _getStartingPriceText(item),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    )
                  else
                    Text(
                      "₹${item.price.toStringAsFixed(0)}",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                ],
              ),
            ),
  
            const SizedBox(width: 10),
  
            // ADD BUTTON
            _buildAddButton(
              context,
              item,
              null,
            ),
          ],
        ),
      );
    }
  
    String _getStartingPriceText(MenuItem item) {
      if (item.variants.isEmpty) {
        return "₹${item.price.toStringAsFixed(0)}";
      }
  
      final prices = item.variants
          .map((variant) => variant.price)
          .toList();
  
      prices.sort();
  
      if (prices.isEmpty) {
        return "₹${item.price.toStringAsFixed(0)}";
      }
  
      return "From ₹${prices.first.toStringAsFixed(0)}";
    }
  
    Widget _buildAddButton(
        BuildContext context,
        MenuItem item,
        MenuVariant? variant,
        ) {
      return Consumer<CartProvider>(
        builder: (context, cart, child) {
  
          // =====================================================
          // IF ITEM HAS VARIANTS
          // =====================================================
  
          if (variant == null && item.variants.isNotEmpty) {
  
            // Total quantity of all variants of this item
            int totalQuantity = 0;
  
            for (final v in item.variants) {
              totalQuantity += cart.quantityFor(
                widget.post,
                item,
                variant: v,
              );
            }
  
            // ---------------------------------------------
            // Already added
            // ---------------------------------------------
  
            if (totalQuantity > 0) {
              return Container(
                height: 34,
                width: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFF27AE60),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
  
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        _showVariantPopup(
                          context,
                          item,
                        );
                      },
                      child: const SizedBox(
                        width: 30,
                        height: 34,
                        child: Center(
                          child: Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
  
                    Text(
                      totalQuantity.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
  
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        _showVariantPopup(
                          context,
                          item,
                        );
                      },
                      child: const SizedBox(
                        width: 30,
                        height: 34,
                        child: Center(
                          child: Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 17,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
  
            // ---------------------------------------------
            // First ADD
            // ---------------------------------------------
  
            return GestureDetector(
              onTap: () {
                _showVariantPopup(
                  context,
                  item,
                );
              },
              child: Container(
                height: 34,
                width: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF27AE60),
                  ),
                ),
                child: const Center(
                  child: Text(
                    "ADD",
                    style: TextStyle(
                      color: Color(0xFF27AE60),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          }
  
          // =====================================================
          // NORMAL ITEM WITHOUT VARIANT
          // =====================================================
  
          final quantity = cart.quantityFor(
            widget.post,
            item,
            variant: null,
          );
  
          // ---------------------------------------------
          // ADD
          // ---------------------------------------------
  
          if (quantity == 0) {
            return GestureDetector(
              onTap: () {
                _addToCartWithVariant(
                  context,
                  item,
                  null,
                );
              },
              child: Container(
                height: 34,
                width: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF27AE60),
                  ),
                ),
                child: const Center(
                  child: Text(
                    "ADD",
                    style: TextStyle(
                      color: Color(0xFF27AE60),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          }
  
          // ---------------------------------------------
          // QUANTITY
          // ---------------------------------------------
  
          return Container(
            height: 34,
            width: 90,
            decoration: BoxDecoration(
              color: const Color(0xFF27AE60),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
  
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    cart.removeItem(
                      widget.post,
                      item,
                      variant: null,
                    );
                  },
                  child: const SizedBox(
                    width: 30,
                    height: 34,
                    child: Center(
                      child: Icon(
                        Icons.remove,
                        color: Colors.white,
                        size: 17,
                      ),
                    ),
                  ),
                ),
  
                Text(
                  quantity.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
  
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    cart.addItem(
                      widget.post,
                      item,
                      variant: null,
                    );
                  },
                  child: const SizedBox(
                    width: 30,
                    height: 34,
                    child: Center(
                      child: Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 17,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    void _showVariantPopup(
        BuildContext context,
        MenuItem item,
        ) {
      final cart = context.read<CartProvider>();

      MenuVariant? selectedVariant;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (modalContext, setModalState) {
              return SafeArea(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(
                    18,
                    12,
                    18,
                    20,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ============================================
                      // HANDLE
                      // ============================================

                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ============================================
                      // ITEM NAME
                      // ============================================

                      Text(
                        item.name,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        "Select an option",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ============================================
                      // VARIANTS
                      // ============================================

                      ...item.variants.map(
                            (variant) {
                          final quantity = cart.quantityFor(
                            widget.post,
                            item,
                            variant: variant,
                          );

                          final isSelected =
                              selectedVariant == variant;

                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedVariant = variant;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(
                                bottom: 10,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 13,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFE8F5E9)
                                    : Colors.white,
                                borderRadius:
                                BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF27AE60)
                                      : Colors.grey.shade300,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [

                                  // RADIO
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF27AE60)
                                            : Colors.grey.shade400,
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? Center(
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration:
                                        const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color:
                                          Color(0xFF27AE60),
                                        ),
                                      ),
                                    )
                                        : null,
                                  ),

                                  const SizedBox(width: 12),

                                  // VARIANT NAME
                                  Expanded(
                                    child: Text(
                                      variant.name,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),

                                  // PRICE
                                  Text(
                                    "₹${variant.price.toStringAsFixed(0)}",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),

                                  // EXISTING QUANTITY
                                  if (quantity > 0) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding:
                                      const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                        const Color(0xFF27AE60),
                                        borderRadius:
                                        BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        "×$quantity",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 8),

                      // ============================================
                      // ADD / INCREASE BUTTON
                      // ============================================

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: selectedVariant == null
                              ? null
                              : () {
                            final variant = selectedVariant!;

                            final cart = context.read<CartProvider>();

                            debugPrint(
                              '🛒 VARIANT ADD CLICKED | '
                                  'Restaurant=${widget.post.id} | '
                                  'Chef=${widget.post.creatorName} | '
                                  'Item=${item.name} | '
                                  'Variant=${variant.name} | '
                                  'Price=₹${variant.price}',
                            );

                            // =====================================================
                            // CART EMPTY
                            // =====================================================

                            if (cart.isEmpty) {
                              debugPrint('🛒 CART EMPTY → ADD DIRECTLY');

                              cart.addItem(
                                widget.post,
                                item,
                                variant: variant,
                              );

                              Navigator.pop(sheetContext);
                              return;
                            }

                            // =====================================================
                            // DIFFERENT RESTAURANT / CHEF
                            // =====================================================

                            if (cart.isDifferentRestaurant(widget.post)) {
                              debugPrint(
                                '🚨 DIFFERENT CHEF DETECTED | '
                                    'OLD=${cart.restaurant?.creatorName} | '
                                    'NEW=${widget.post.creatorName}',
                              );

                              // First close the variant popup
                              Navigator.pop(sheetContext);

                              // Then show the restaurant-change alert
                              _showDifferentRestaurantDialogWithVariant(
                                context,
                                item,
                                variant,
                              );

                              return;
                            }

                            // =====================================================
                            // SAME RESTAURANT / CHEF
                            // =====================================================

                            debugPrint(
                              '🛒 SAME CHEF → ADD VARIANT',
                            );

                            cart.addItem(
                              widget.post,
                              item,
                              variant: variant,
                            );

                            Navigator.pop(sheetContext);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            const Color(0xFF27AE60),
                            disabledBackgroundColor:
                            Colors.grey.shade300,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            selectedVariant == null
                                ? "Select an option"
                                : cart.quantityFor(
                              widget.post,
                              item,
                              variant:
                              selectedVariant,
                            ) >
                                0
                                ? "Add Another • ${selectedVariant!.name}"
                                : "Add ${selectedVariant!.name} • ₹${selectedVariant!.price.toStringAsFixed(0)}",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    }
  }