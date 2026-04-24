import 'package:flutter/material.dart';

import '../core/theme/saca_colors.dart';

class BaseCard extends StatelessWidget {
  const BaseCard({
    super.key,
    required this.active,
    required this.accentColor,
    required this.child,
  });

  final bool active;
  final Color accentColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: SACAColors.cardBackground,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: active ? accentColor : SACAColors.subtleBorder,
          width: active ? 2 : 1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: active ? 0.12 : 0.08),
            blurRadius: active ? 24 : 15,
            offset: Offset(0, active ? 10 : 7),
          ),
        ],
      ),
      child: child,
    );
  }
}
