import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'instagram_repository.dart';
import 'instacritic.dart';
Future<void> main() async {
  await initializeFlutterFire();
  runApp(MyApp());
}

Future<void> initializeFlutterFire() async {
  try {
    await Firebase.initializeApp();
  } catch(e) {
    print(e);
    print("Firebase initialization failed.");
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InstagramRepository(),
      child: MaterialApp(home: Instacritic()),
      );
  }
}