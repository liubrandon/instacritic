import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';

// https://medium.com/icnh/a-star-rating-widget-for-flutter-41560f82c8cb
class StarDisplay extends StatelessWidget {
  final int value;
  const StarDisplay({Key key, this.value = 0})
      : assert(value != null),
        super(key: key);
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: (value == 0) ? [Icon(FontAwesomeIcons.skull, size: 20, color: Colors.grey[400])] : List.generate(value, (index) {
        return Icon( Icons.star, color: Colors.amber[500], size: 25);
      }),
    );
  }
}