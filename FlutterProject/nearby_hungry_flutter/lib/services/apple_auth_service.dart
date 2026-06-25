import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppleAuthService {
  static Future<UserCredential?> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // ✅ IMPORTANT: Use ONLY idToken (NO accessToken)
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
      );

      final userCredential =
      await FirebaseAuth.instance.signInWithCredential(oauthCredential);

      final user = userCredential.user;

      if (user != null) {
        final doc =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

        final snapshot = await doc.get();

        if (!snapshot.exists) {
          await doc.set({
            "name":
            "${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}"
                .trim(),
            "email": user.email,
            "createdAt": FieldValue.serverTimestamp(),
          });
        }
      }

      return userCredential;
    } catch (e) {
      print("❌ Apple Login Error: $e");
      return null;
    }
  }
}