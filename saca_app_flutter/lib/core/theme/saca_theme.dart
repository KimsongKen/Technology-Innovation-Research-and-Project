import 'package:flutter/material.dart';

import 'saca_colors.dart';

class SACATheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: SACAColors.pageBackground,
    colorScheme: ColorScheme.fromSeed(
      seedColor: SACAColors.deepClinicalGreen,
      brightness: Brightness.light,
    ),
  );
}
