import 'package:flutter/material.dart';

class HoverScaleCard extends StatefulWidget {
  const HoverScaleCard({
    super.key,
    required this.onTap,
    required this.builder,
  });

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
