part of '../main.dart';

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
        return _BaseCard(
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

class ReportModeCard extends StatelessWidget {
  const ReportModeCard({super.key, required this.data, required this.onTap});

  final ReportModeCardData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HoverScaleCard(
      onTap: onTap,
      builder: (bool active) {
        return _BaseCard(
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
                    SACAStrings.tr(
                      context: context,
                      english: 'Recommended',
                      warlpiri: 'Recommended',
                    ),
                    style: TextStyle(
                      color: data.accentColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              if (data.recommended) const SizedBox(height: 12),
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

class HoverScaleCard extends StatefulWidget {
  const HoverScaleCard({super.key, required this.onTap, required this.builder});

  final VoidCallback onTap;
  final Widget Function(bool active) builder;

  @override
  State<HoverScaleCard> createState() => _HoverScaleCardState();
}

class _HoverScaleCardState extends State<HoverScaleCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool active = _isHovered || _isPressed;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: active ? 1.02 : 1,
        duration: const Duration(milliseconds: 170),
        curve: Curves.easeOutCubic,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: widget.onTap,
            onHighlightChanged: (bool pressed) {
              if (_isPressed != pressed) {
                setState(() => _isPressed = pressed);
              }
            },
            child: widget.builder(active),
          ),
        ),
      ),
    );
  }
}

class _BaseCard extends StatelessWidget {
  const _BaseCard({
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
