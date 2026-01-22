import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/HomeActivity.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const NearbyHungryApp());
}

class NearbyHungryApp extends StatelessWidget {
  const NearbyHungryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}