import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryWhite = Color.fromRGBO(241, 241, 241, 1.0);
  static const Color secondaryWhite = Color.fromRGBO(175, 175, 175, 1.0);
  static const Color grayBorder = Color.fromRGBO(19, 19, 19, 1.0);
  static const Color primaryBackground = Color.fromRGBO(4, 4, 4, 1.0);
  static const Color secondaryBackground = Color.fromRGBO(32, 32, 32, 1.0);
  static const Color primaryPink = Color.fromRGBO(208, 54, 150, 1.0);
  static const Color primaryRed = Color.fromRGBO(215, 59, 84, 1.0);
  static const Color textGrey = Color.fromRGBO(124, 124, 124, 1);
  static const Color whiteBorder = Color.fromRGBO(211, 211, 211, 1.0);
  static const Color errorRed = Color.fromRGBO(112, 0, 0, 1.0);
  static const LinearGradient mainGradient = LinearGradient(
    colors: [
      Color.fromRGBO(208, 54, 150, 1.0),
      Color.fromRGBO(215, 59, 84, 1.0)
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
