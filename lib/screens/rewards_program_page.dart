import 'package:flutter/material.dart';

class RewardsProgramPage extends StatelessWidget {
  const RewardsProgramPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0), // Off White
      appBar: AppBar(
        backgroundColor: const Color(0xFFF94449),
        elevation: 0,
        title: const Text(
          'Rewards Program',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _sectionTitle("🎉 Nearby Hungry Rewards Program"),

            const SizedBox(height: 20),

            _card(
              title: "🍽️ For Customers",
              children: const [
                "Earn ₹30 Reward Points on every order.",
                "Only orders with a minimum value of ₹300 or above are eligible.",
                "Rewards can be redeemed after completing 5 different eligible orders.",
                "Total reward after 5 eligible orders: ₹150.",
              ],
            ),

            const SizedBox(height: 16),

            _card(
              title: "👨‍🍳👩‍🍳 For Chefs",
              children: const [
                "Earn ₹30 Reward Points on every successful order sold.",
                "Only orders worth ₹300 or above are eligible.",
                "Rewards can be redeemed after completing 5 different eligible orders.",
                "Total reward after 5 eligible orders: ₹150.",
              ],
            ),

            const SizedBox(height: 16),

            _card(
              title: "📧 Redemption Process",
              children: const [
                "After completing 5 eligible orders, send an email to nearbyhungry@gmail.com with:",
                "• Full Name",
                "• Registered Mobile Number",
                "• User Name / Chef Name",
                "• Screenshots or Order IDs of the 5 eligible orders",
                "",
                "Subject Line:",
                "Reward Redemption Request – Nearby Hungry",
                "",
                "Our team will verify the details and process the reward.",
              ],
            ),

            const SizedBox(height: 16),

            _card(
              title: "📜 Terms & Conditions",
              children: const [
                "Only completed orders of ₹300 or more qualify.",
                "Orders must be genuine and successfully completed.",
                "Cancelled or refunded orders will not be considered.",
                "Nearby Hungry reserves the right to verify all submissions before approving rewards.",
                "Reward program terms may be modified or discontinued at any time.",
              ],
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Color(0xFFF94449),
      ),
    );
  }

  Widget _card({
    required String title,
    required List<String> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF94449),
            ),
          ),
          const SizedBox(height: 10),
          ...children.map(
                (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                e,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}