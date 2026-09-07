import 'package:nearby_hungry_flutter/models/post.dart';

class CartItem {
  final Post restaurant;
  final MenuItem menuItem;

  // Selected variant, for example:
  // Half - ₹180
  // Full - ₹280
  final MenuVariant? variant;

  int quantity;

  CartItem({
    required this.restaurant,
    required this.menuItem,
    this.variant,
    this.quantity = 1,
  });

  // Use variant price when a variant is selected.
  double get unitPrice {
    return variant?.price ?? menuItem.price;
  }

  double get totalPrice {
    return unitPrice * quantity;
  }

  // Useful for displaying:
  // Mutter Paneer - Half
  // Mutter Paneer - Full
  String get displayName {
    if (variant == null || variant!.name.isEmpty) {
      return menuItem.name;
    }

    return '${menuItem.name} - ${variant!.name}';
  }
}