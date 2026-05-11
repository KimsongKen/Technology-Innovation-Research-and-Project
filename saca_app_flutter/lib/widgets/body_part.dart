part of '../main.dart';

class InteractiveBodyWidget extends StatefulWidget {
  const InteractiveBodyWidget({
    super.key,
    required this.session,
    required this.onSelectionChanged,
  });

  final TriageSession session;
  final VoidCallback onSelectionChanged;

  @override
  State<InteractiveBodyWidget> createState() => _InteractiveBodyWidgetState();
}

enum _BodyView { front, back }

class _InteractiveBodyWidgetState extends State<InteractiveBodyWidget> {
  static const String _frontImage = 'assets/images/body_front.jpg';
  static const String _backImage = 'assets/images/body_back.jpg';

  _BodyView _view = _BodyView.front;
  late Set<String> _selectedParts;

  @override
  void initState() {
    super.initState();
    _loadSelectedParts();
  }

  @override
  void didUpdateWidget(covariant InteractiveBodyWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.session, widget.session)) {
      _loadSelectedParts();
    }
  }

  void _loadSelectedParts() {
    _selectedParts = widget.session.painLocation
        .where(
          (String part) =>
              part == 'Head' ||
              part == 'Body' ||
              part == 'Arm' ||
              part == 'Leg' ||
              part == 'Back',
        )
        .toSet();
  }

  void _togglePart(String part) {
    setState(() {
      if (_selectedParts.contains(part)) {
        _selectedParts.remove(part);
      } else {
        _selectedParts.add(part);
      }
      widget.session.painLocation
        ..clear()
        ..addAll(<String>['Head', 'Body', 'Arm', 'Leg', 'Back']
            .where(_selectedParts.contains));
    });
    widget.onSelectionChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SegmentedButton<_BodyView>(
          segments: const <ButtonSegment<_BodyView>>[
            ButtonSegment<_BodyView>(
              value: _BodyView.front,
              icon: Icon(Icons.accessibility_new_rounded),
              label: Text('Front'),
            ),
            ButtonSegment<_BodyView>(
              value: _BodyView.back,
              icon: Icon(Icons.airline_seat_recline_normal_rounded),
              label: Text('Back'),
            ),
          ],
          selected: <_BodyView>{_view},
          onSelectionChanged: (Set<_BodyView> selected) {
            setState(() {
              _view = selected.first;
            });
          },
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1.25,
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final Size size = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );

                  return Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      Center(
                        child: FractionallySizedBox(
                          widthFactor: 0.58,
                          heightFactor: 1,
                          child: Image.asset(
                            _view == _BodyView.front ? _frontImage : _backImage,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      ..._zonesForView().map(
                        (_BodyZone zone) => _buildZone(zone, size),
                      ),
                      IgnorePointer(
                        child: CustomPaint(
                          painter: _BodyCalloutPainter(
                            callouts: _calloutsForView(),
                            color: SACAColors.deepClinicalGreen,
                          ),
                        ),
                      ),
                      ..._calloutsForView().map(
                        (_BodyCallout callout) =>
                            _buildCalloutLabel(callout, size),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<_BodyZone> _zonesForView() {
    if (_view == _BodyView.back) {
      return const <_BodyZone>[
        _BodyZone('Head', Rect.fromLTWH(0.44, 0.04, 0.12, 0.13)),
        _BodyZone('Back', Rect.fromLTWH(0.41, 0.20, 0.18, 0.34)),
        _BodyZone('Arm', Rect.fromLTWH(0.32, 0.25, 0.07, 0.25)),
        _BodyZone('Arm', Rect.fromLTWH(0.29, 0.47, 0.07, 0.18)),
        _BodyZone('Arm', Rect.fromLTWH(0.61, 0.25, 0.07, 0.25)),
        _BodyZone('Arm', Rect.fromLTWH(0.64, 0.47, 0.07, 0.18)),
        _BodyZone('Leg', Rect.fromLTWH(0.42, 0.56, 0.07, 0.38)),
        _BodyZone('Leg', Rect.fromLTWH(0.51, 0.56, 0.07, 0.38)),
      ];
    }

    return const <_BodyZone>[
      _BodyZone('Head', Rect.fromLTWH(0.44, 0.04, 0.12, 0.13)),
      _BodyZone('Body', Rect.fromLTWH(0.41, 0.20, 0.18, 0.34)),
      _BodyZone('Arm', Rect.fromLTWH(0.32, 0.25, 0.07, 0.25)),
      _BodyZone('Arm', Rect.fromLTWH(0.29, 0.47, 0.07, 0.18)),
      _BodyZone('Arm', Rect.fromLTWH(0.61, 0.25, 0.07, 0.25)),
      _BodyZone('Arm', Rect.fromLTWH(0.64, 0.47, 0.07, 0.18)),
      _BodyZone('Leg', Rect.fromLTWH(0.42, 0.56, 0.07, 0.38)),
      _BodyZone('Leg', Rect.fromLTWH(0.51, 0.56, 0.07, 0.38)),
    ];
  }

  Widget _buildZone(_BodyZone zone, Size size) {
    return Positioned(
      left: zone.bounds.left * size.width,
      top: zone.bounds.top * size.height,
      width: zone.bounds.width * size.width,
      height: zone.bounds.height * size.height,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => _togglePart(zone.part),
        child: const SizedBox.expand(),
      ),
    );
  }

  List<_BodyCallout> _calloutsForView() {
    final List<_BodyCallout> callouts = <_BodyCallout>[];
    final List<_BodyCallout> options = _view == _BodyView.front
        ? const <_BodyCallout>[
            _BodyCallout(
              label: 'Head',
              anchor: Offset(0.50, 0.10),
              box: Rect.fromLTWH(0.02, 0.06, 0.22, 0.08),
            ),
            _BodyCallout(
              label: 'Body',
              anchor: Offset(0.50, 0.36),
              box: Rect.fromLTWH(0.76, 0.32, 0.22, 0.08),
            ),
            _BodyCallout(
              label: 'Arm',
              displayLabel: 'Arms',
              anchor: Offset(0.36, 0.42),
              box: Rect.fromLTWH(0.02, 0.42, 0.22, 0.08),
            ),
            _BodyCallout(
              label: 'Leg',
              displayLabel: 'Legs',
              anchor: Offset(0.44, 0.72),
              box: Rect.fromLTWH(0.76, 0.72, 0.22, 0.08),
            ),
          ]
        : const <_BodyCallout>[
            _BodyCallout(
              label: 'Back',
              anchor: Offset(0.50, 0.36),
              box: Rect.fromLTWH(0.76, 0.30, 0.22, 0.08),
            ),
            _BodyCallout(
              label: 'Head',
              anchor: Offset(0.50, 0.10),
              box: Rect.fromLTWH(0.02, 0.06, 0.22, 0.08),
            ),
            _BodyCallout(
              label: 'Arm',
              displayLabel: 'Arms',
              anchor: Offset(0.36, 0.42),
              box: Rect.fromLTWH(0.02, 0.42, 0.22, 0.08),
            ),
            _BodyCallout(
              label: 'Leg',
              displayLabel: 'Legs',
              anchor: Offset(0.44, 0.72),
              box: Rect.fromLTWH(0.76, 0.72, 0.22, 0.08),
            ),
          ];

    for (final _BodyCallout callout in options) {
      if (_selectedParts.contains(callout.label)) {
        callouts.add(callout);
      }
    }
    return callouts;
  }

  Widget _buildCalloutLabel(_BodyCallout callout, Size size) {
    return Positioned(
      left: callout.box.left * size.width,
      top: callout.box.top * size.height,
      width: callout.box.width * size.width,
      height: callout.box.height * size.height,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: SACAColors.deepClinicalGreen,
              width: 1.6,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              callout.displayLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: SACAColors.deepClinicalGreen,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BodyZone {
  const _BodyZone(this.part, this.bounds);

  final String part;
  final Rect bounds;
}

class _BodyCallout {
  const _BodyCallout({
    required this.label,
    required this.anchor,
    required this.box,
    String? displayLabel,
  }) : displayLabel = displayLabel ?? label;

  final String label;
  final String displayLabel;
  final Offset anchor;
  final Rect box;
}

class _BodyCalloutPainter extends CustomPainter {
  const _BodyCalloutPainter({
    required this.callouts,
    required this.color,
  });

  final List<_BodyCallout> callouts;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (final _BodyCallout callout in callouts) {
      final Offset anchor = Offset(
        callout.anchor.dx * size.width,
        callout.anchor.dy * size.height,
      );
      final Rect box = Rect.fromLTWH(
        callout.box.left * size.width,
        callout.box.top * size.height,
        callout.box.width * size.width,
        callout.box.height * size.height,
      );
      final Offset boxPoint = Offset(
        anchor.dx < box.center.dx ? box.left : box.right,
        box.center.dy,
      );

      canvas.drawLine(anchor, boxPoint, linePaint);
      canvas.drawCircle(anchor, 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BodyCalloutPainter oldDelegate) {
    return oldDelegate.callouts != callouts || oldDelegate.color != color;
  }
}
