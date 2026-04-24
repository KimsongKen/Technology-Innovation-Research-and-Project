import 'package:flutter/material.dart';

import 'core/theme/saca_theme.dart';
import 'pages/language_selection_page.dart';
import 'services/speech_input_service.dart';
import 'services/speech_output_service.dart';
import 'services/triage_service.dart';
import 'state/saca_app_state.dart';
import 'state/saca_state_scope.dart';

class SACAApp extends StatefulWidget {
  const SACAApp({super.key});

  @override
  State<SACAApp> createState() => _SACAAppState();
}

class _SACAAppState extends State<SACAApp> {
  final SACAAppState _state = SACAAppState();
  final TriageService _triageService = TriageService();
  final SpeechInputService _speechInputService = SpeechInputService();
  final SpeechOutputService _speechOutputService = SpeechOutputService();

  @override
  void initState() {
    super.initState();
    _speechInputService.initialize();
    _speechOutputService.initialize();
  }

  @override
  void dispose() {
    _speechInputService.cancelListening();
    _speechOutputService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SACAStateScope(
      state: _state,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SACA - Smart Adaptive Clinical Assistant',
        theme: SACATheme.lightTheme,
        home: LanguageSelectionPage(
          triageService: _triageService,
          speechInputService: _speechInputService,
          speechOutputService: _speechOutputService,
        ),
      ),
    );
  }
}
