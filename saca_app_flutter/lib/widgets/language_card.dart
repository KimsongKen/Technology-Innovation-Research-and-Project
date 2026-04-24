import 'package:flutter/material.dart';

import '../core/theme/saca_colors.dart';
import 'base_card.dart';
import 'hover_scale_card.dart';

class LanguageCard extends StatelessWidget {
  const LanguageCard({
    super.key,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final Color accentColor;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HoverScaleCard(
      onTap: onTap,
      builder: (bool active) {
        return BaseCard(
          active: active,
          accentColor: accentColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withValues(alpha: 0.16),
                ),
                child: Icon(icon, color: accentColor, size: 32),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  color: SACAColors.charcoal,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  color: accentColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
