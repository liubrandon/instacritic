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
    return ChangeNotifierProvider(
        create: (_) => InstagramRepository(),
        child: MaterialApp(
          home: Navigator(
            pages: [
              MaterialPage(
                key: ValueKey('Instacritic'),
                child: Instacritic(0)
              ),
            ],
            onPopPage: (route, result) {
              if(!route.didPop(result)) return false;
              return true;
            }
          ),
          theme: ThemeData(
            accentColor: Colors.grey,
          ),
        ),
      );
  }
}