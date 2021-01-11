import 'dart:ui';

class Constants {
  static const myPurple = Color(0xFF953c71);
}

String processStringForSearch(String term) => term.toLowerCase().replaceAll(RegExp(r"[^\w]"), '');
