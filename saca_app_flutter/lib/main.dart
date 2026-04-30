import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

part 'models/app_models.dart';
part 'services/triage_service.dart';
part 'screens/language_and_method_pages.dart';
part 'screens/workspace_and_result_pages.dart';
part 'widgets/app_tokens.dart';
part 'widgets/cards.dart';
part 'widgets/clinical_input_card.dart';
part 'widgets/result_widgets.dart';

void main() {
  runApp(const SACAApp());
}

class SACAAppState extends ChangeNotifier {
  AppLanguage _selectedLanguage = AppLanguage.english;

  AppLanguage get selectedLanguage => _selectedLanguage;

  void setLanguage(AppLanguage language) {
    if (_selectedLanguage == language) return;
    _selectedLanguage = language;
    notifyListeners();
  }
}

class SACAStateScope extends InheritedNotifier<SACAAppState> {
  const SACAStateScope({
    super.key,
    required SACAAppState state,
    required super.child,
  }) : super(notifier: state);

  static SACAAppState of(BuildContext context) {
    final SACAStateScope? scope = context
        .dependOnInheritedWidgetOfExactType<SACAStateScope>();
    assert(scope != null, 'SACAStateScope not found in context');
    return scope!.notifier!;
  }
}

class SACAApp extends StatefulWidget {
  const SACAApp({super.key});

  @override
  State<SACAApp> createState() => _SACAAppState();
}

class _SACAAppState extends State<SACAApp> {
  final SACAAppState _state = SACAAppState();
  final TriageService _triageService = TriageService();

  @override
  Widget build(BuildContext context) {
    return SACAStateScope(
      state: _state,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SACA - Smart Adaptive Clinical Assistant',
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Inter',
          scaffoldBackgroundColor: SACAColors.pageBackground,
          colorScheme: ColorScheme.fromSeed(
            seedColor: SACAColors.deepClinicalGreen,
            brightness: Brightness.light,
          ),
        ),
        home: LanguageSelectionPage(triageService: _triageService),
      ),
    );
  }
}



