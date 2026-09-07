import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/post.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  // ============================================================
  // TOTAL ITEMS
  // ============================================================

  int get totalItems {
    return _items.fold(
      0,
          (total, item) => total + item.quantity,
    );
  }

  // ============================================================
  // TOTAL FOOD AMOUNT
  // ============================================================

  double get totalAmount {
    return _items.fold(
      0,
          (total, item) => total + item.totalPrice,
    );
  }

  // ============================================================
  // DELIVERY
  // ============================================================

  double get deliveryCharge => _items.isEmpty ? 0 : 40.0;

  // ============================================================
  // FINAL AMOUNT
  // ============================================================

  double get finalAmount {
    if (_items.isEmpty) {
      return 0;
    }

    return totalAmount + deliveryCharge;
  }

  // ============================================================
  // RESTAURANT
  // ============================================================

  Post? get restaurant {
    if (_items.isEmpty) {
      return null;
    }

    return _items.first.restaurant;
  }

  bool get isEmpty => _items.isEmpty;

  // ============================================================
  // NORMALIZE TEXT
  // ============================================================

  String _normalize(String? value) {
    return (value ?? '')
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  // ============================================================
  // FIND CART ITEM
  //
  // IMPORTANT:
  //
  // Same restaurant
  // + same menu item
  // + same variant
  //
  // = same cart item
  //
  // Half and Full are therefore completely separate.
  // ============================================================

  int _findItemIndex(
      Post restaurant,
      MenuItem menuItem,
      MenuVariant? variant,
      ) {
    final restaurantId = restaurant.id;
    final menuName = _normalize(menuItem.name);

    final variantName = variant == null
        ? ''
        : _normalize(variant.name);

    debugPrint(
      '🔍 FIND CART ITEM | '
          'Restaurant=$restaurantId | '
          'Menu="$menuName" | '
          'Variant="$variantName"',
    );

    for (int i = 0; i < _items.length; i++) {
      final cartItem = _items[i];

      final cartRestaurantId = cartItem.restaurant.id;
      final cartMenuName = _normalize(cartItem.menuItem.name);

      final cartVariantName = cartItem.variant == null
          ? ''
          : _normalize(cartItem.variant!.name);

      final sameRestaurant =
          cartRestaurantId == restaurantId;

      final sameMenuItem =
          cartMenuName == menuName;

      final sameVariant =
          cartVariantName == variantName;

      debugPrint(
        '🔍 CART[$i] | '
            'Restaurant=$cartRestaurantId '
            '(${sameRestaurant ? "MATCH" : "NO"}) | '
            'Menu="$cartMenuName" '
            '(${sameMenuItem ? "MATCH" : "NO"}) | '
            'Variant="$cartVariantName" '
            '(${sameVariant ? "MATCH" : "NO"})',
      );

      if (sameRestaurant &&
          sameMenuItem &&
          sameVariant) {
        debugPrint(
          '✅ EXISTING CART ITEM FOUND | index=$i',
        );

        return i;
      }
    }

    debugPrint(
      '❌ NO EXISTING CART ITEM FOUND',
    );

    return -1;
  }

  // ============================================================
  // CHECK ITEM
  // ============================================================

  bool containsItem(
      Post restaurant,
      MenuItem menuItem, {
        MenuVariant? variant,
      }) {
    return _findItemIndex(
      restaurant,
      menuItem,
      variant,
    ) != -1;
  }

  // ============================================================
  // GET QUANTITY
  // ============================================================

  int quantityFor(
      Post restaurant,
      MenuItem menuItem, {
        MenuVariant? variant,
      }) {
    final index = _findItemIndex(
      restaurant,
      menuItem,
      variant,
    );

    if (index == -1) {
      return 0;
    }

    return _items[index].quantity;
  }

  // ============================================================
  // ADD ITEM
  // ============================================================

  void addItem(
      Post restaurant,
      MenuItem menuItem, {
        MenuVariant? variant,
      }) {
    debugPrint(
      '🛒 ADD ITEM CALLED | '
          'Restaurant=${restaurant.id} | '
          'Menu="${menuItem.name}" | '
          'Variant="${variant?.name ?? "NONE"}" | '
          'Price=${variant?.price ?? menuItem.price}',
    );

    final index = _findItemIndex(
      restaurant,
      menuItem,
      variant,
    );

    debugPrint(
      '🛒 FIND RESULT | index=$index',
    );

    // Existing item
    if (index != -1) {
      _items[index].quantity++;

      debugPrint(
        '🛒 INCREASE | '
            '${_items[index].displayName} '
            '→ ${_items[index].quantity}',
      );
    }

    // New item
    else {
      final newItem = CartItem(
        restaurant: restaurant,
        menuItem: menuItem,
        variant: variant,
        quantity: 1,
      );

      _items.add(newItem);

      debugPrint(
        '🛒 NEW ITEM | '
            '${newItem.displayName} '
            '→ 1',
      );
    }

    debugPrint(
      '🛒 TOTAL CART ITEMS = ${_items.length}',
    );

    notifyListeners();
  }

  // ============================================================
  // REMOVE ITEM
  // ============================================================

  void removeItem(
      Post restaurant,
      MenuItem menuItem, {
        MenuVariant? variant,
      }) {
    final index = _findItemIndex(
      restaurant,
      menuItem,
      variant,
    );

    if (index == -1) {
      debugPrint(
        '🛒 REMOVE FAILED: item not found',
      );

      return;
    }

    final item = _items[index];

    if (item.quantity > 1) {
      item.quantity--;

      debugPrint(
        '🛒 DECREASE: '
            '${item.displayName} '
            '→ ${item.quantity}',
      );
    } else {
      debugPrint(
        '🛒 REMOVE: '
            '${item.displayName}',
      );

      _items.removeAt(index);
    }

    notifyListeners();
  }

  // ============================================================
  // CLEAR CART
  // ============================================================

  void clearCart() {
    _items.clear();

    debugPrint('🛒 CART CLEARED');

    notifyListeners();
  }

  // ============================================================
  // DIFFERENT RESTAURANT
  // ============================================================

  bool isDifferentRestaurant(Post restaurant) {
    if (_items.isEmpty) {
      return false;
    }

    return _items.first.restaurant.id != restaurant.id;
  }

  // ============================================================
  // DEBUG CART
  // ============================================================

  void printCart() {
    debugPrint('========== CART ==========');

    for (final item in _items) {
      debugPrint(
        '${item.displayName} | '
            '₹${item.unitPrice} | '
            'Qty: ${item.quantity} | '
            'Total: ₹${item.totalPrice}',
      );
    }

    debugPrint(
      'Food Total: ₹$totalAmount',
    );

    debugPrint(
      'Delivery: ₹$deliveryCharge',
    );

    debugPrint(
      'Final: ₹$finalAmount',
    );

    debugPrint('==========================');
  }
}