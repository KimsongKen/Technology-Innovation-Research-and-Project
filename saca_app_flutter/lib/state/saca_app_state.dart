import 'package:flutter/material.dart';

import '../core/enums/app_language.dart';

class SACAAppState extends ChangeNotifier {
  AppLanguage _selectedLanguage = AppLanguage.english;

  AppLanguage get selectedLanguage => _selectedLanguage;

  void setLanguage(AppLanguage language) {
    if (_selectedLanguage == language) {
      return;
    }
    _selectedLanguage = language;
    notifyListeners();
  }
}
