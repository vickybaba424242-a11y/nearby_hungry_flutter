import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/post.dart';
import '../providers/cart_provider.dart';
import 'cart_page.dart';
import 'inbox_page.dart';

class FullMenuPage extends StatefulWidget {
  final Post restaurant;
  final String searchText;

  const FullMenuPage({
    super.key,
    required this.restaurant,
    this.searchText = '',
  });

  @override
  State<FullMenuPage> createState() => _FullMenuPageState();
}

class _FullMenuPageState extends State<FullMenuPage> {
  late TextEditingController _searchController;

  String _searchText = '';

  @override
  void initState() {
    super.initState();

    _searchController = TextEditingController(
      text: widget.searchText,
    );

    _searchText = widget.searchText;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSingleItemCartControl(
      BuildContext context,
      MenuItem item,
      ) {
    return Consumer<CartProvider>(
      builder: (
          context,
          cart,
          child,
          ) {
        final quantity = cart.quantityFor(
          widget.restaurant,
          item,
        );

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "₹${item.price.toStringAsFixed(0)}",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),

            if (quantity == 0)
              GestureDetector(
                onTap: () {
                  _addToCart(
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
              )
            else
              _buildQuantityControl(
                context: context,
                item: item,
                quantity: quantity,
                variant: null,
              ),
          ],
        );
      },
    );
  }

  Widget _buildVariantCartControl(
      BuildContext context,
      MenuItem item,
      MenuVariant variant,
      ) {
    return Consumer<CartProvider>(
      builder: (
          context,
          cart,
          child,
          ) {
        final quantity = cart.quantityFor(
          widget.restaurant,
          item,
          variant: variant,
        );

        return Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(
                    variant.name,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),

                  const SizedBox(width: 8),

                  Text(
                    "₹${variant.price.toStringAsFixed(0)}",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            if (quantity == 0)
              GestureDetector(
                onTap: () {
                  _addVariantToCart(
                    context,
                    item,
                    variant,
                  );
                },
                child: Container(
                  height: 32,
                  width: 62,
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
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              )
            else
              _buildQuantityControl(
                context: context,
                item: item,
                quantity: quantity,
                variant: variant,
              ),
          ],
        );
      },
    );
  }

  void _addVariantToCart(
      BuildContext context,
      MenuItem item,
      MenuVariant variant,
      ) {
    final cart = context.read<CartProvider>();

    if (cart.isEmpty) {
      cart.addItem(
        widget.restaurant,
        item,
        variant: variant,
      );
      return;
    }

    if (!cart.isDifferentRestaurant(widget.restaurant)) {
      cart.addItem(
        widget.restaurant,
        item,
        variant: variant,
      );
      return;
    }

    _showDifferentRestaurantVariantDialog(
      context,
      item,
      variant,
    );
  }
  Widget _buildQuantityControl({
    required BuildContext context,
    required MenuItem item,
    required int quantity,
    required MenuVariant? variant,
  }) {
    final cart = context.read<CartProvider>();

    return Container(
      height: 32,
      width: 88,
      decoration: BoxDecoration(
        color: const Color(0xFF27AE60),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          InkWell(
            onTap: () {
              cart.removeItem(
                widget.restaurant,
                item,
                variant: variant,
              );
            },
            child: const SizedBox(
              width: 28,
              height: 32,
              child: Center(
                child: Icon(
                  Icons.remove,
                  color: Colors.white,
                  size: 16,
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
            onTap: () {
              cart.addItem(
                widget.restaurant,
                item,
                variant: variant,
              );
            },
            child: const SizedBox(
              width: 28,
              height: 32,
              child: Center(
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDifferentRestaurantVariantDialog(
      BuildContext context,
      MenuItem item,
      MenuVariant variant,
      ) {
    final cart = context.read<CartProvider>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            "Start a new cart?",
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            "Your cart contains items from "
                "${cart.restaurant?.creatorName ?? 'another restaurant'}.\n\n"
                "Your current cart will be cleared and "
                "${item.name} - ${variant.name} will be added instead.",
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                "Cancel",
              ),
            ),
            ElevatedButton(
              onPressed: () {
                cart.clearCart();

                cart.addItem(
                  widget.restaurant,
                  item,
                  variant: variant,
                );

                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF27AE60),
                foregroundColor: Colors.white,
              ),
              child: const Text(
                "Clear & Add",
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

    if (cart.isEmpty) {
      cart.addItem(widget.restaurant, item);
      return;
    }

    if (!cart.isDifferentRestaurant(widget.restaurant)) {
      cart.addItem(widget.restaurant, item);
      return;
    }

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
                  widget.restaurant,
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

  bool _isItemHighlighted(MenuItem item) {
    final query = _searchText.trim().toLowerCase();

    if (query.isEmpty) {
      return false;
    }

    return item.name.toLowerCase().contains(query);
  }

  Widget _highlightText(
      String text,
      String query,
      ) {
    final cleanQuery = query.trim();

    if (cleanQuery.isEmpty) {
      return Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      );
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = cleanQuery.toLowerCase();

    final startIndex = lowerText.indexOf(lowerQuery);

    if (startIndex == -1) {
      return Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
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
          color: Colors.black87,
        ),
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF57C00),
        foregroundColor: Colors.white,
        elevation: 0,

        title: Text(
          widget.restaurant.creatorName,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
          ),
        ),

        actions: [
          // ==============================
          // MESSAGE / INBOX
          // ==============================
          IconButton(
            tooltip: "Messages",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const InboxPage(),
                ),
              );
            },
            icon: const Icon(
              Icons.chat_bubble_outline,
              size: 23,
            ),
          ),

          // ==============================
          // CART
          // ==============================
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              return Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  IconButton(
                    tooltip: "Cart",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CartPage(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.shopping_cart_outlined,
                      size: 25,
                    ),
                  ),

                  if (cart.totalItems > 0)
                    Positioned(
                      right: 3,
                      top: 3,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF27AE60),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFF57C00),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          cart.totalItems > 99
                              ? "99+"
                              : cart.totalItems.toString(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          const SizedBox(width: 6),
        ],
      ),

      body: Column(
        children: [
          // Restaurant information
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text(
                      "🍽️",
                      style: TextStyle(
                        fontSize: 28,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.restaurant.creatorName,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        "${widget.restaurant.menuItems.length} menu items",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
            ),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchText = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: "Search menu...",
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFFF57C00),
                    size: 22,
                  ),
                  suffixIcon: _searchText.isNotEmpty
                      ? IconButton(
                    icon: const Icon(
                      Icons.clear,
                      size: 20,
                    ),
                    onPressed: () {
                      _searchController.clear();

                      setState(() {
                        _searchText = '';
                      });
                    },
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 13,
                    horizontal: 8,
                  ),
                ),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: _buildFilteredMenu(),
          ),
        ],
      ),

      bottomNavigationBar:
      Consumer<CartProvider>(
        builder: (context, cart, child) {
          final hasItems =
              cart.totalItems > 0 &&
                  cart.restaurant?.id ==
                      widget.restaurant.id;

          if (!hasItems) {
            return const SizedBox.shrink();
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                        const CartPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(0xFF27AE60),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.shopping_cart,
                      ),

                      const SizedBox(width: 8),

                      Text(
                        "${cart.totalItems} items",
                        style:
                        GoogleFonts.poppins(
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Text(
                        "₹${cart.totalAmount.toStringAsFixed(0)}",
                        style:
                        GoogleFonts.poppins(
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilteredMenu() {
    final query = _searchText.trim().toLowerCase();

    final filteredItems = widget.restaurant.menuItems.where((item) {
      if (query.isEmpty) {
        return true;
      }

      final name = item.name.toLowerCase();

      final description =
          item.description?.toLowerCase() ?? '';

      final category =
      item.category.toLowerCase();

      return name.contains(query) ||
          description.contains(query) ||
          category.contains(query);
    }).toList();

    if (filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 50,
              color: Colors.grey.shade400,
            ),

            const SizedBox(height: 12),

            Text(
              "No menu items found",
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              "Try searching for another dish",
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 8,
      ),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];

        return _menuItem(
          context,
          item,
        );
      },
    );
  }

  Widget _menuItem(
      BuildContext context,
      MenuItem item,
      ) {
    final isHighlighted = _isItemHighlighted(item);

    final hasVariants = item.variants.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isHighlighted
            ? const Color(0xFFFFF3E0)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isHighlighted
            ? Border.all(
          color: const Color(0xFFF57C00),
          width: 1.5,
        )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==============================
          // VEG INDICATOR
          // ==============================

          // ==============================
// COLORFUL FOOD INDICATOR
// ==============================

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

          const SizedBox(width: 12),

          // ==============================
          // FOOD INFORMATION
          // ==============================

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _highlightText(
                  item.name,
                  _searchText,
                ),

                if (item.description != null &&
                    item.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      item.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                // ==================================================
                // NO VARIANT
                // ==================================================

                if (!hasVariants)
                  _buildSingleItemCartControl(
                    context,
                    item,
                  )

                // ==================================================
                // VARIANTS
                // ==================================================

                else
                  Column(
                    children: item.variants.map((variant) {
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: 8,
                        ),
                        child: _buildVariantCartControl(
                          context,
                          item,
                          variant,
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}