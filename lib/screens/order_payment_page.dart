import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'chat_page.dart';

class OrderPaymentPage extends StatelessWidget {
  final String chefId;
  final String customerId;
  final String chefName;

  final List<Map<String, dynamic>> items;

  final double foodTotal;
  final double deliveryCharge;
  final double finalAmount;

  const OrderPaymentPage({
    super.key,
    required this.chefId,
    required this.customerId,
    required this.chefName,
    required this.items,
    required this.foodTotal,
    required this.deliveryCharge,
    required this.finalAmount,
  });

  static const String upiId = "7417211941@ptyes";
  static const String phoneNumber = "7417211941";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),

      appBar: AppBar(
        title: const Text(
          "Confirm Order",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFF57C00),
        foregroundColor: Colors.white,
      ),

      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(14),
              children: [
                // ==========================
                // RESTAURANT
                // ==========================

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            "🍽️",
                            style: TextStyle(fontSize: 25),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Text(
                          chefName,
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

                // ==========================
                // ORDER ITEMS
                // ==========================

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Your Order",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      ...items.map(
                            (item) {
                          final name =
                              item['name']?.toString() ?? '';

                          final quantity =
                              item['quantity'] ?? 1;

                          final price =
                              (item['price'] as num?)?.toDouble() ?? 0;

                          final total =
                              price * quantity;

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 7,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "$name × $quantity",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),

                                Text(
                                  "₹${total.toStringAsFixed(0)}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const Divider(height: 24),

                      _priceRow(
                        "Food Total",
                        foodTotal,
                      ),

                      const SizedBox(height: 8),

                      _priceRow(
                        "Delivery Charge",
                        deliveryCharge,
                      ),

                      const Divider(height: 20),

                      _priceRow(
                        "Total",
                        finalAmount,
                        bold: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ==========================
                // PAYMENT
                // ==========================

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Payment",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        "Pay the exact order amount using UPI or phone number.",
                        style: TextStyle(
                          color: Colors.black54,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // AMOUNT

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              "Amount to Pay",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              "₹${finalAmount.toStringAsFixed(0)}",
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // UPI

                      Card(
                        elevation: 0,
                        color: Colors.grey.shade50,
                        child: ListTile(
                          leading: const Icon(
                            Icons.account_balance_wallet,
                            color: Colors.deepPurple,
                          ),
                          title: const Text(
                            "UPI ID",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: const Text(
                            upiId,
                            style: TextStyle(
                              fontSize: 15,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: () {
                              Clipboard.setData(
                                const ClipboardData(
                                  text: upiId,
                                ),
                              );

                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "UPI ID copied",
                                  ),
                                  backgroundColor:
                                  Colors.green,
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // PHONE

                      Card(
                        elevation: 0,
                        color: Colors.grey.shade50,
                        child: ListTile(
                          leading: const Icon(
                            Icons.phone_android,
                            color: Colors.green,
                          ),
                          title: const Text(
                            "Phone Number",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: const Text(
                            phoneNumber,
                            style: TextStyle(
                              fontSize: 15,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: () {
                              Clipboard.setData(
                                const ClipboardData(
                                  text: phoneNumber,
                                ),
                              );

                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Phone number copied",
                                  ),
                                  backgroundColor:
                                  Colors.green,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),

          // ==========================
          // I HAVE PAID
          // ==========================

          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(14),
              color: Colors.white,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    _openChat(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27AE60),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    "I Have Paid",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(
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
            fontSize: bold ? 17 : 14,
            fontWeight:
            bold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
        Text(
          "₹${amount.toStringAsFixed(0)}",
          style: TextStyle(
            fontSize: bold ? 20 : 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _openChat(BuildContext context) {
    final orderText = StringBuffer();

    orderText.writeln("🍽️ NEW ORDER");
    orderText.writeln();
    orderText.writeln("Restaurant: $chefName");
    orderText.writeln();
    orderText.writeln("ORDER ITEMS:");

    for (final item in items) {
      final name = item['name']?.toString() ?? '';
      final quantity = item['quantity'] ?? 1;
      final price =
          (item['price'] as num?)?.toDouble() ?? 0;

      final total = price * quantity;

      orderText.writeln(
        "• $name × $quantity = ₹${total.toStringAsFixed(0)}",
      );
    }

    orderText.writeln();
    orderText.writeln(
      "Food Total: ₹${foodTotal.toStringAsFixed(0)}",
    );

    orderText.writeln(
      "Delivery Charge: ₹${deliveryCharge.toStringAsFixed(0)}",
    );

    orderText.writeln(
      "TOTAL: ₹${finalAmount.toStringAsFixed(0)}",
    );

    orderText.writeln();
    orderText.writeln("💰 Payment marked as paid.");
    orderText.writeln(
      "Please verify the payment and confirm the order.",
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          chefId: chefId,
          customerId: customerId,
          chefName: chefName,
          isAdmin: false,
          initialOrderMessage: orderText.toString(),
        ),
      ),
    );
  }
}