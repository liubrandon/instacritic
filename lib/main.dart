import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:instacritic/list_screen.dart';
import 'package:instacritic/map_screen.dart';
import 'configure_web.dart';
import 'package:provider/provider.dart';
import 'instagram_repository.dart';
import 'instacritic.dart';
Future<void> main() async {
  configureApp();
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
    // final Instacritic icList = Instacritic(0);
    // final Instacritic icMap = Instacritic(1);
    return WillPopScope(
      onWillPop: () async => false,
      child: ChangeNotifierProvider(
        create: (_) => InstagramRepository(),
        child: MaterialApp(
          home: Instacritic(0),
          theme: ThemeData(
            accentColor: Colors.grey,
          ),
          // initialRoute: '/',
          // routes: {
          //   '/': (context) => icList,
          //   // MapScreen.route: (context) => icMap,
          // }
        ),
      ),
    );
  }
}