import 'package:flutter/material.dart';

import '../core/enums/report_mode.dart';
import '../core/theme/saca_colors.dart';
import 'base_card.dart';
import 'hover_scale_card.dart';

class ReportModeCardData {
  const ReportModeCardData({
    required this.mode,
    required this.heroTag,
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.description,
    this.recommended = false,
  });

  final ReportMode mode;
  final String heroTag;
  final IconData icon;
  final Color accentColor;
  final String title;
  final String description;
  final bool recommended;
}

class ReportModeCard extends StatelessWidget {
  const ReportModeCard({
    super.key,
    required this.data,
    required this.recommendedLabel,
    required this.onTap,
  });

  final ReportModeCardData data;
  final String recommendedLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HoverScaleCard(
      onTap: onTap,
      builder: (bool active) {
        return BaseCard(
          active: active,
          accentColor: data.accentColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (data.recommended)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: data.accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    recommendedLabel,
                    style: TextStyle(
                      color: data.accentColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              if (data.recommended)
                const SizedBox(height: 12),
              Hero(
                tag: data.heroTag,
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: data.accentColor.withValues(alpha: 0.14),
                  ),
                  child: Icon(data.icon, color: data.accentColor, size: 31),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                data.title,
                style: const TextStyle(
                  color: SACAColors.charcoal,
                  fontSize: 25,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                data.description,
                style: const TextStyle(
                  color: SACAColors.secondaryText,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const Spacer(),
              Container(
                height: 3,
                decoration: BoxDecoration(
                  color: data.accentColor,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
