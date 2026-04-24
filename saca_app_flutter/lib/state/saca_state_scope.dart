import 'package:flutter/material.dart';

import 'saca_app_state.dart';

class SACAStateScope extends InheritedNotifier<SACAAppState> {
  const SACAStateScope({
    super.key,
    required SACAAppState state,
    required Widget child,
  }) : super(notifier: state, child: child);

  static SACAAppState of(BuildContext context) {
    final SACAStateScope? scope =
        context.dependOnInheritedWidgetOfExactType<SACAStateScope>();
    assert(scope != null, 'SACAStateScope not found in context');
    return scope!.notifier!;
  }
}
