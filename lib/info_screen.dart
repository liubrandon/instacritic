import 'package:flutter/material.dart';
import 'package:flutter_gradient_colors/flutter_gradient_colors.dart';

class InfoScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
                // height: MediaQuery.of(context).size.height-150,
                // width: MediaQuery.of(context).size.width,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [Text('Brandon Liu\nBuild ${const String.fromEnvironment('APP_VERSION')}',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  )]
                ),
              );
  }
}