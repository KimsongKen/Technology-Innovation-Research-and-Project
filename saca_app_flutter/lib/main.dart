import 'dart:io' as io;
import 'dart:convert';
import 'dart:async';
import 'dart:isolate';
import 'dart:math' show pi;
import 'dart:typed_data';
import 'dart:ui' show ImageFilter;

import 'package:app_settings/app_settings.dart';
import 'package:body_part_selector/body_part_selector.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:archive/archive.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart' as webview_windows;

import 'widgets/body_part_bridge.dart';

part 'models/app_models.dart';
part 'services/triage_service.dart';
part 'services/disease_library.dart';
part 'services/asset_server.dart';
part 'services/kokoro_tts_service.dart';
part 'screens/language_and_method_pages.dart';
part 'screens/settings_page.dart';
part 'screens/workspace_and_result_pages.dart';
part 'widgets/app_tokens.dart';
part 'widgets/body_part.dart';
part 'widgets/cards.dart';
part 'widgets/clinical_input_card.dart';
part 'widgets/result_widgets.dart';
part 'widgets/windows_model_viewer.dart';

void main() {
  runApp(const SACAApp());
}

// ── Global app state ───────────────────────────────────────────────────────
class SACAAppState extends ChangeNotifier {
  AppLanguage _selectedLanguage    = AppLanguage.english;
  bool        _isDarkMode          = false;
  bool        _isVoiceoverEnabled  = true;
  /// 0.0 = 🐢 Very Slow, 0.25 = Slow, 0.5 = Normal, 0.75 = Fast, 1.0 = 🐇 Very Fast
  double      _voiceoverSpeed      = 0.5;

  AppLanguage get selectedLanguage   => _selectedLanguage;
  bool        get isDarkMode         => _isDarkMode;
  bool        get isVoiceoverEnabled => _isVoiceoverEnabled;
  double      get voiceoverSpeed     => _voiceoverSpeed;

  void setLanguage(AppLanguage language) {
    if (_selectedLanguage == language) return;
    _selectedLanguage = language;
    notifyListeners();
  }

  void setDarkMode(bool value) {
    if (_isDarkMode == value) return;
    _isDarkMode = value;
    notifyListeners();
  }

  void setVoiceoverEnabled(bool value) {
    if (_isVoiceoverEnabled == value) return;
    _isVoiceoverEnabled = value;
    notifyListeners();
  }

  void setVoiceoverSpeed(double value) {
    final double clamped = value.clamp(0.0, 1.0);
    if (_voiceoverSpeed == clamped) return;
    _voiceoverSpeed = clamped;
    KokoroTtsService.speed = clamped;  // keep static service in sync
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
    final SACAStateScope? scope =
        context.dependOnInheritedWidgetOfExactType<SACAStateScope>();
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
  void initState() {
    super.initState();
    // Rebuild MaterialApp whenever isDarkMode changes.
    _state.addListener(_onAppStateChanged);
    // Start Kokoro TTS — initialises from disk if model is already downloaded.
    KokoroTtsService.checkAndInit();
  }

  @override
  void dispose() {
    _state.removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return SACAStateScope(
      state: _state,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SACA - Smart Adaptive Clinical Assistant',
        theme:     SACAColorScheme.buildTheme(isDark: false),
        darkTheme: SACAColorScheme.buildTheme(isDark: true),
        themeMode: _state.isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: LanguageSelectionPage(triageService: _triageService),
      ),
    );
  }
}
