import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AppleAuthService {
  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';

    final random = Random.secure();

    return List.generate(
      length,
          (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  static String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static Future<UserCredential?> signInWithApple() async {
    try {
      // Generate a random nonce.
      final rawNonce = _generateNonce();

      // Hash the nonce before sending it to Apple.
      final nonce = _sha256ofString(rawNonce);

      final appleCredential =
      await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final identityToken = appleCredential.identityToken;

      if (identityToken == null || identityToken.isEmpty) {
        throw Exception(
          'Apple Sign-In did not return an identity token.',
        );
      }

      // Use the ORIGINAL raw nonce with Firebase.
      final oauthCredential =
      OAuthProvider('apple.com').credential(
        idToken: identityToken,
        rawNonce: rawNonce,
      );

      final userCredential =
      await FirebaseAuth.instance.signInWithCredential(
        oauthCredential,
      );

      final user = userCredential.user;

      if (user != null) {
        final doc = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid);

        final snapshot = await doc.get();

        final fullName = [
          appleCredential.givenName,
          appleCredential.familyName,
        ]
            .where(
              (value) => value != null && value.trim().isNotEmpty,
        )
            .map((value) => value!.trim())
            .join(' ');

        if (!snapshot.exists) {
          await doc.set({
            'name': fullName,
            'username': fullName,
            'displayName': fullName,
            'email': user.email,
            'createdAt': FieldValue.serverTimestamp(),
            'lastLoginAt': FieldValue.serverTimestamp(),
          });
        } else {
          await doc.set({
            'lastLoginAt': FieldValue.serverTimestamp(),
            if (fullName.isNotEmpty) ...{
              'name': fullName,
              'username': fullName,
              'displayName': fullName,
            },
            if (user.email != null)
              'email': user.email,
          }, SetOptions(merge: true));
        }
      }

      print(
        '✅ Apple Login Success: ${userCredential.user?.uid}',
      );

      return userCredential;
    } on SignInWithAppleAuthorizationException catch (e) {
      print('❌ Apple Authorization Error');
      print('Code: ${e.code}');
      print('Message: ${e.message}');

      rethrow;
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Apple Login Error');
      print('Code: ${e.code}');
      print('Message: ${e.message}');

      rethrow;
    } catch (e) {
      print('❌ Apple Login Error: $e');

      rethrow;
    }
  }
}