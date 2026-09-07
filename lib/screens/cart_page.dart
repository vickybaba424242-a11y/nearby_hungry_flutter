import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../providers/cart_provider.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import 'chat_page.dart';

class CartPage extends StatelessWidget {
  const CartPage({
    super.key,
  });

  void _showOrderConfirmation(
      BuildContext context,
      CartProvider cart,
      ) {
    final foodTotal = cart.totalAmount;
    final deliveryCharge = cart.deliveryCharge;
    final finalTotal = cart.finalAmount;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.receipt_long,
                color: Colors.orange,
              ),
              SizedBox(width: 8),
              Text(
                'Confirm Your Order',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please review your order before proceeding.',
                style: TextStyle(fontSize: 14),
              ),

              const SizedBox(height: 16),

              _dialogPriceRow(
                'Food Total',
                foodTotal,
              ),

              const SizedBox(height: 6),

              _dialogPriceRow(
                'Delivery Charge',
                deliveryCharge,
              ),

              const Divider(height: 20),

              _dialogPriceRow(
                'Total Amount',
                finalTotal,
                bold: true,
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.shade200,
                  ),
                ),
                child: const Text(
                  '⚠️ Before the chef starts preparing your order, '
                      'please complete the payment.\n\n'
                      'After making the payment, return to the order '
                      'and tap "I Have Paid".',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),

            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                await _proceedWithOrder(
                  context,
                  cart,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF27AE60),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Continue',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _dialogPriceRow(
      String title,
      double amount, {
        bool bold = false,
      }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: bold ? 16 : 14,
            fontWeight:
            bold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: bold ? 18 : 14,
            fontWeight:
            bold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Future<void> _proceedWithOrder(
      BuildContext context,
      CartProvider cart,
      ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please login before placing an order.',
            ),
          ),
        );
        return;
      }

      final restaurant = cart.restaurant;

      if (restaurant == null) {
        return;
      }

      final chefId = restaurant.creatorId;
      final customerId = user.uid;
      final finalTotal = cart.finalAmount;

      if (chefId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to identify the chef.',
            ),
          ),
        );
        return;
      }

      // Get customer information
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(customerId)
          .get();

      final userData = userDoc.data() ?? {};

      final customerPhone =
      (userData['phone'] ??
          userData['phoneNumber'] ??
          '')
          .toString();

      final address =
      (userData['address'] ??
          userData['fullAddress'] ??
          '')
          .toString();

      // Create OrderItems from cart
      final orderItems = cart.items.map((cartItem) {
        return OrderItem(
          postId: restaurant.id,
          foodName: cartItem.menuItem.name,
          quantity: cartItem.quantity,
          price: cartItem.menuItem.price,
        );
      }).toList();

      // Create Chat ID
      final chatId = chefId.compareTo(customerId) < 0
          ? '${chefId}_$customerId'
          : '${customerId}_$chefId';

      // Create Order
      final order = OrderModel(
        id: '',
        chatId: chatId,
        customerId: customerId,
        chefId: chefId,
        items: orderItems,
        subtotal: cart.totalAmount,
        deliveryCharge: cart.deliveryCharge,
        total: cart.finalAmount,
        status: OrderStatus.pending,
        paymentStatus: PaymentStatus.pending,
        address: address,
        customerPhone: customerPhone,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save order
      final orderId = await OrderService.createOrder(order: order);

// Create / Update chat first
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .set({
        'chefId': chefId,
        'customerId': customerId,
        'participants': [chefId, customerId],
        'lastMessage': '🍽️ New order received',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount_$chefId': FieldValue.increment(1),
      }, SetOptions(merge: true));

// Order card message
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'type': 'order',
        'orderId': orderId,
        'senderId': customerId,
        'senderRole': 'customer',
        'sentByAdmin': false,
        'timestamp': FieldValue.serverTimestamp(),
        'seen': false,
      });

      if (!context.mounted) return;

      // Clear cart
      cart.clearCart();

      // Go to chat
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatPage(
            chefId: chefId,
            customerId: customerId,
          ),
        ),
      );
    } catch (e) {
      debugPrint(
        'Order creation failed: $e',
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to place order: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),

      appBar: AppBar(
        title: const Text(
          "Your Cart",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.isEmpty) {
            return const Center(
              child: Text(
                "Your cart is empty",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }

          final foodTotal = cart.totalAmount;
          final deliveryCharge = cart.deliveryCharge;
          final finalTotal = cart.finalAmount;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(14),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius:
                              BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                "🍽️",
                                style: TextStyle(
                                  fontSize: 23,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Text(
                              cart.restaurant?.creatorName ??
                                  "Restaurant",
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: cart.items.map((cartItem) {
                          return Padding(
                            padding:
                            const EdgeInsets.symmetric(
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cartItem.displayName,
                                        style: const TextStyle(
                                          fontWeight:
                                          FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        cartItem.variant != null
                                            ? "${cartItem.variant!.name} • ₹${cartItem.unitPrice.toStringAsFixed(0)}"
                                            : "₹${cartItem.unitPrice.toStringAsFixed(0)}",
                                        style: TextStyle(
                                          color: Colors
                                              .grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Container(
                                  height: 34,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(
                                        0xFF27AE60,
                                      ),
                                    ),
                                    borderRadius:
                                    BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        padding:
                                        EdgeInsets.zero,
                                        constraints:
                                        const BoxConstraints(
                                          minWidth: 32,
                                        ),
                                        onPressed: () {
                                          cart.removeItem(
                                            cartItem.restaurant,
                                            cartItem.menuItem,
                                            variant: cartItem.variant,
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.remove,
                                          size: 16,
                                        ),
                                      ),

                                      Text(
                                        cartItem.quantity
                                            .toString(),
                                        style:
                                        const TextStyle(
                                          fontWeight:
                                          FontWeight.bold,
                                        ),
                                      ),

                                      IconButton(
                                        padding:
                                        EdgeInsets.zero,
                                        constraints:
                                        const BoxConstraints(
                                          minWidth: 32,
                                        ),
                                        onPressed: () {
                                          cart.addItem(
                                            cartItem.restaurant,
                                            cartItem.menuItem,
                                            variant: cartItem.variant,
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.add,
                                          size: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 12),

                                SizedBox(
                                  width: 65,
                                  child: Text(
                                    "₹${cartItem.totalPrice.toStringAsFixed(0)}",
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // ==============================
              // BOTTOM TOTAL
              // ==============================

              SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Food Total",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            "₹${foodTotal.toStringAsFixed(0)}",
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Delivery Charge",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            "₹${deliveryCharge.toStringAsFixed(0)}",
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      const Divider(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Total",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "₹${finalTotal.toStringAsFixed(0)}",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            _showOrderConfirmation(
                              context,
                              cart,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            const Color(0xFF27AE60),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            "Proceed to Order",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}