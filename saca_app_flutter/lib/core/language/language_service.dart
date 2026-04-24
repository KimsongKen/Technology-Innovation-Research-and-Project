import '../enums/app_language.dart';
import 'english.dart';
import 'warlpiri.dart';

class LanguageService {
  static String get(AppLanguage language, String key) {
    switch (language) {
      case AppLanguage.english:
        return en[key] ?? key;
      case AppLanguage.warlpiri:
        return warlpiri[key] ?? key;
    }
  }
}
