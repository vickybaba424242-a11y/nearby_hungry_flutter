import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';

class ReferEarnPage extends StatefulWidget {
  const ReferEarnPage({super.key});

  @override
  State<ReferEarnPage> createState() => _ReferEarnPageState();
}

class _ReferEarnPageState extends State<ReferEarnPage> {
  String referralCode = '';
  int referralCount = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadReferralData();
  }

  Future<void> _loadReferralData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid);

    final userDoc = await userRef.get();

    String code =
        userDoc.data()?['referralCode'] ?? '';

    if (code.isEmpty) {

      final email =
      (userDoc.data()?['email'] ?? '')
          .toString()
          .toLowerCase();

      if (email.isNotEmpty) {

        final referralDoc =
        await FirebaseFirestore.instance
            .collection('referral_codes')
            .doc(email)
            .get();

        if (referralDoc.exists) {

          code = referralDoc['referralCode'];

        } else {

          code = await createUniqueReferralCode();

          await FirebaseFirestore.instance
              .collection('referral_codes')
              .doc(email)
              .set({
            'email': email,
            'referralCode': code,
          });
        }

        await userRef.set({
          'referralCode': code,
        }, SetOptions(merge: true));
      }
    }

    final referralsSnapshot = await FirebaseFirestore
        .instance
        .collection('referrals')
        .where('referrerCode', isEqualTo: code)
        .get();

    if (!mounted) return;

    setState(() {
      referralCode = code;
      referralCount = referralsSnapshot.docs.length;
      loading = false;
    });
  }

  String generateReferralCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();

    return List.generate(
      6,
          (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  Future<String> createUniqueReferralCode() async {
    while (true) {
      final code = generateReferralCode();

      final existing = await FirebaseFirestore.instance
          .collection('users')
          .where('referralCode', isEqualTo: code)
          .limit(1)
          .get();

      if (existing.docs.isEmpty) {
        return code;
      }
    }
  }

  void _copyCode() {
    Clipboard.setData(
      ClipboardData(text: referralCode),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Referral code copied"),
      ),
    );
  }

  void _shareCode() {
    Share.share(
      "🍲 Join Nearby Hungry using my referral code: $referralCode\n\nDownload Nearby Hungry and support local chefs!",
    );
  }

  Future<void> _claimReward() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'nearbyhungry@gmail.com',
      queryParameters: {
        'subject': 'Reward Claim Request',
        'body':
        'Hello Nearby Hungry Team,\n\nI have completed $referralCount referrals.\n\nMy Referral Code: $referralCode\n\nPlease verify and process my reward.\n\nThank you.'
      },
    );

    await launchUrl(emailUri);
  }

  @override
  Widget build(BuildContext context) {
    final progress = (referralCount / 5).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF94449),
        title: const Text(
          "Refer & Earn",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: loading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// Referral Code Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      "Your Referral Code",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      referralCode,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF94449),
                        letterSpacing: 2,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _copyCode,
                          icon: const Icon(Icons.copy),
                          label: const Text("Copy"),
                        ),

                        const SizedBox(width: 12),

                        ElevatedButton.icon(
                          onPressed: _shareCode,
                          icon: const Icon(Icons.share),
                          label: const Text("Share"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// Reward Progress
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      "🎁 Reward Progress",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 12,
                      borderRadius:
                      BorderRadius.circular(20),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      "$referralCount / 5 Referrals Completed",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// Referral Count Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.workspace_premium,
                  color: Color(0xFFF94449),
                  size: 35,
                ),
                title: const Text(
                  "Successful Referrals",
                ),
                trailing: Text(
                  referralCount.toString(),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// Reward Rules
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      "Reward Program",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 15),

                    Text(
                      "🎯 Complete 5 successful referrals.\n\n"
                          "📧 Once you reach 5 referrals, send us an email for verification.\n\n"
                          "🎁 After verification, you will receive your reward.\n\n"
                          "🚀 More referrals means more future rewards.",
                      style: TextStyle(
                        height: 1.5,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// Claim Reward Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed:
                referralCount >= 5 ? _claimReward : null,
                icon: const Icon(Icons.card_giftcard),
                label: const Text(
                  "Claim Reward",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  const Color(0xFFF94449),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}