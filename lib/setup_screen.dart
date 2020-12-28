import 'package:flutter/material.dart';
// import 'package:url_launcher/link.dart';
import 'dart:js' as js; // ignore: avoid_web_libraries_in_flutter

class SetupScreen extends StatefulWidget {
  @override
  _SetupScreenState createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  Uri uri;
  @override
  Widget build(BuildContext context) {
    uri = Uri.tryParse(js.context['location']['href']);
    if(uri != null) {
      print(uri);
      print(uri.queryParameters);
    }
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: FlatButton(
              child: Text('Connect Instagram', style: TextStyle(color: Colors.white),),
              color: Colors.purple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              onPressed: () {
                js.context.callMethod('open', ['https://api.instagram.com/oauth/authorize?client_id=220573006257941&redirect_uri=https://localhost:58531/setup/&scope=user_profile,user_media&response_type=code', '_self']);
              }
            ),
          ),
        ],
      ),
    );
  }
}
