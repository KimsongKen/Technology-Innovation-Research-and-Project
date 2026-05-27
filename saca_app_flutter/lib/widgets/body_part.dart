part of '../main.dart';

// ── Body label overlay ────────────────────────────────────────────────────

class _BodyLabelDef {
  const _BodyLabelDef({
    required this.display,
    required this.warlpiri,
    required this.meshName,
    required this.bodyAnchor,
    required this.onLeft,
    required this.labelY,
  });
  final String display;
  final String warlpiri;
  final String meshName;
  // Normalised [0–1] position of the body part within the viewer container.
  final Offset bodyAnchor;
  // true → label box sits on the left edge; false → right edge.
  final bool onLeft;
  // Normalised [0–1] vertical centre of the label box.
  final double labelY;

  /// Returns the label text for the active app language.
  String label(AppLanguage lang) =>
      lang == AppLanguage.warlpiri ? warlpiri : display;
}

// Five labels – one per GLB mesh.
// bodyAnchor values are tuned for a standing A-pose / T-pose human model
// filling roughly the centre 60 % of the viewer widget.

// ── Front view labels ────────────────────────────────────────────────────
const _kBodyLabels = <_BodyLabelDef>[
  _BodyLabelDef(display: 'Head',      warlpiri: 'Ngurlukurlu',    meshName: 'head',      bodyAnchor: Offset(0.50, 0.13), onLeft: true,  labelY: 0.10),
  _BodyLabelDef(display: 'Body',      warlpiri: 'Yuurrpu',        meshName: 'body',      bodyAnchor: Offset(0.50, 0.36), onLeft: false, labelY: 0.30),
  _BodyLabelDef(display: 'Right Arm', warlpiri: 'Pama-Kurlarda',  meshName: 'right arm', bodyAnchor: Offset(0.34, 0.41), onLeft: true,  labelY: 0.43),
  _BodyLabelDef(display: 'Left Arm',  warlpiri: 'Pama-Yirdi',     meshName: 'left arm',  bodyAnchor: Offset(0.66, 0.44), onLeft: false, labelY: 0.50),
  _BodyLabelDef(display: 'Leg',       warlpiri: 'Yankirri',       meshName: 'leg',       bodyAnchor: Offset(0.50, 0.77), onLeft: true,  labelY: 0.76),
];

// ── Back view labels ─────────────────────────────────────────────────────
// When the model rotates 180° the arms visually swap sides:
//   model's Right Arm → viewer's RIGHT  (anchor.dx flips from 0.34 → 0.66)
//   model's Left Arm  → viewer's LEFT   (anchor.dx flips from 0.66 → 0.34)
// All onLeft values are inverted and labels are renamed to indicate the back.
const _kBodyLabelsBack = <_BodyLabelDef>[
  _BodyLabelDef(display: 'Back of Head', warlpiri: 'Ngurlukurlu-Karna', meshName: 'head',      bodyAnchor: Offset(0.50, 0.13), onLeft: false, labelY: 0.10),
  _BodyLabelDef(display: 'Back of Body', warlpiri: 'Yuurrpu-Karna',     meshName: 'body',      bodyAnchor: Offset(0.50, 0.36), onLeft: true,  labelY: 0.30),
  _BodyLabelDef(display: 'Right Arm',    warlpiri: 'Pama-Kurlarda',     meshName: 'right arm', bodyAnchor: Offset(0.66, 0.41), onLeft: false, labelY: 0.43),
  _BodyLabelDef(display: 'Left Arm',     warlpiri: 'Pama-Yirdi',        meshName: 'left arm',  bodyAnchor: Offset(0.34, 0.44), onLeft: true,  labelY: 0.50),
  _BodyLabelDef(display: 'Back of Legs', warlpiri: 'Yankirri-Karna',    meshName: 'leg',       bodyAnchor: Offset(0.50, 0.77), onLeft: false, labelY: 0.76),
];

const double _kLabelW   = 100.0;
const double _kLabelH   = 28.0;
const double _kLabelPad = 8.0;

/// Draws the thin lines + anchor dots connecting each label to its body part.
class _BodyLinePainter extends CustomPainter {
  const _BodyLinePainter({required this.labels, required this.selected});
  final List<_BodyLabelDef> labels;
  final Set<String> selected;

  static const _kRed   = Color(0xFFD32F2F);
  static const _kGreen = SACAColors.triageSafeGreen;

  @override
  void paint(Canvas canvas, Size size) {
    for (final def in labels) {
      final isOn = selected.contains(def.meshName);
      final color = isOn ? _kRed : _kGreen;
      final linePaint = Paint()
        ..color       = color
        ..strokeWidth = 1.5
        ..style       = PaintingStyle.stroke;

      final anchor = Offset(
        def.bodyAnchor.dx * size.width,
        def.bodyAnchor.dy * size.height,
      );

      final labelCenterY = def.labelY * size.height;
      final lineStart = def.onLeft
          ? Offset(_kLabelPad + _kLabelW, labelCenterY)
          : Offset(size.width - _kLabelPad - _kLabelW, labelCenterY);

      canvas.drawLine(lineStart, anchor, linePaint);
      canvas.drawCircle(anchor, 3.5, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_BodyLinePainter old) =>
      old.labels != labels ||
      old.selected.difference(selected).isNotEmpty ||
      selected.difference(old.selected).isNotEmpty;
}


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

class _InteractiveBodyWidgetState extends State<InteractiveBodyWidget> {
  BodyParts _bodyParts = const BodyParts();
  bool _isFrontView  = true;
  bool _isModelLocked = true; // locked by default; unlock to drag/spin

  // Populated on Android/iOS by model_viewer_plus.
  WebViewController? _webViewController;

  // kIsWeb must come first — dart:io Platform throws on web.
  // Android & iOS: model_viewer_plus (webview_flutter).
  // Windows:       webview_windows + local HTTP asset server.
  // Web:           static body images (model-viewer is web-native but
  //                model_viewer_plus Flutter package doesn't support web yet).
  static bool get _use3D => !kIsWeb &&
      (io.Platform.isAndroid || io.Platform.isIOS || io.Platform.isWindows);

  static const String _modelAsset = 'assets/models/HumanModel.glb';

  // Injected via relatedJs.
  // • Probes the loaded model at 5 body positions to build a mesh→material map.
  // • Falls back to click-position heuristic when the model is a single mesh.
  // • Exposes window.syncSelection(json) so Dart can push red highlights in.
  static const String _clickJs = r'''
(function () {
  var mv = document.querySelector("model-viewer");
  if (!mv) return;

  var RED     = [1, 0.15, 0.15, 1];
  var REGIONS = ['head', 'body', 'left arm', 'right arm', 'leg'];
  var origColors = {};

  // Build a lowercase-name → material map directly from the loaded model.
  function matByName() {
    var map = {};
    var mats = mv.model.materials;
    for (var i = 0; i < mats.length; i++) {
      map[mats[i].name.toLowerCase().trim()] = mats[i];
    }
    return map;
  }

  // Snapshot original colors once on load so we can restore them.
  function storeOriginals() {
    var map = matByName();
    REGIONS.forEach(function(r) {
      var mat = map[r];
      if (!mat) return;
      try {
        var f = mat.pbrMetallicRoughness.baseColorFactor;
        origColors[r] = f ? [f[0],f[1],f[2],f[3]] : [0.78,0.78,0.78,1];
      } catch(e) { origColors[r] = [0.78,0.78,0.78,1]; }
    });
  }

  // Position-based fallback for click detection.
  // window._isBackView is set by Dart when the camera rotates 180°.
  // In back view the model's right arm is visually on the RIGHT side of
  // the screen (opposite of front view), so arm sides must be swapped.
  function regionFromPos(cx, cy) {
    var r    = mv.getBoundingClientRect();
    var rx   = (cx - r.left) / r.width;
    var ry   = (cy - r.top)  / r.height;
    var back = window._isBackView === true;
    if (ry < 0.22)               return 'Head';
    if (ry < 0.52 && rx < 0.38) return back ? 'Left Arm'  : 'Right Arm';
    if (ry < 0.52 && rx > 0.62) return back ? 'Right Arm' : 'Left Arm';
    if (ry < 0.52)               return 'Body';
    return 'Leg';
  }

  // Called from Dart after every selection change.
  window.syncSelection = function (json) {
    var selected = [];
    try { selected = JSON.parse(json); } catch (e) {}
    var map = matByName();
    REGIONS.forEach(function (region) {
      var mat = map[region];
      if (!mat) return;
      var isOn = selected.indexOf(region) >= 0;
      try {
        mat.pbrMetallicRoughness.setBaseColorFactor(
          isOn ? RED : (origColors[region] || [0.78,0.78,0.78,1])
        );
      } catch(e) {}
    });
  };

  function attach() {
    storeOriginals();
    mv.addEventListener('click', function (e) {
      try {
        var hit  = mv.surfaceFromPoint(e.clientX, e.clientY);
        var name = (hit && hit.meshName) ? hit.meshName.toLowerCase().trim() : '';
        if (!name || REGIONS.indexOf(name) < 0) {
          name = regionFromPos(e.clientX, e.clientY);
        }
        BodyPartChannel.postMessage(name);
      } catch (err) {
        BodyPartChannel.postMessage(regionFromPos(e.clientX, e.clientY));
      }
    });
  }

  if (mv.loaded) { attach(); } else { mv.addEventListener('load', attach, { once: true }); }
})();
''';

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
    setState(() {
      _bodyParts = painLocationToBodyParts(widget.session.painLocation);
    });
  }

  // ── Camera (Android / iOS 3-D only) ─────────────────────────────────────

  void _showFront() {
    if (_isFrontView) return;
    setState(() => _isFrontView = true);
    // Android / iOS
    _webViewController?.runJavaScript(
      'window._isBackView = false;'
      'var mv=document.querySelector("model-viewer");'
      'if(mv)mv.setAttribute("camera-orbit","0deg 75deg auto");',
    );
    // Windows — handled by WindowsModelViewer.didUpdateWidget
  }

  void _showBack() {
    if (!_isFrontView) return;
    setState(() => _isFrontView = false);
    // Android / iOS
    _webViewController?.runJavaScript(
      'window._isBackView = true;'
      'var mv=document.querySelector("model-viewer");'
      'if(mv)mv.setAttribute("camera-orbit","180deg 75deg auto");',
    );
    // Windows — handled by WindowsModelViewer.didUpdateWidget
  }

  // ── Model lock / unlock ──────────────────────────────────────────────────

  void _toggleModelLock() {
    setState(() => _isModelLocked = !_isModelLocked);
    // Android / iOS — inject JS to add/remove the camera-controls attribute.
    final String js = _isModelLocked
        ? 'var mv=document.querySelector("model-viewer");'
          'if(mv)mv.removeAttribute("camera-controls");'
        : 'var mv=document.querySelector("model-viewer");'
          'if(mv)mv.setAttribute("camera-controls","");';
    _webViewController?.runJavaScript(js);
    // Windows — handled by WindowsModelViewer.didUpdateWidget via isLocked.
  }

  // ── Mesh tap (Android / iOS 3-D only) ───────────────────────────────────

  void _onMeshTapped(String meshName) {
    final updated = togglePartByMeshName(_bodyParts, meshName);
    if (updated == _bodyParts) return;
    _applyUpdate(updated);
  }

  // ── Selection helpers ────────────────────────────────────────────────────

  void _applyUpdate(BodyParts updated) {
    setState(() => _bodyParts = updated);
    widget.session.painLocation
      ..clear()
      ..addAll(bodyPartsToPainLocation(updated));
    widget.onSelectionChanged();
    _syncHighlights(updated);
  }

  /// Maps [BodyParts] fields to the exact lowercase mesh names in HumanModel.glb.
  static List<String> _selectedMeshNames(BodyParts bp) {
    final meshes = <String>[];
    if (bp.head || bp.neck || bp.vestibular) { meshes.add('head'); }
    if (bp.upperBody || bp.abdomen || bp.lowerBody) { meshes.add('body'); }
    if (bp.leftShoulder  || bp.leftUpperArm  || bp.leftElbow  ||
        bp.leftLowerArm  || bp.leftHand) { meshes.add('left arm'); }
    if (bp.rightShoulder || bp.rightUpperArm || bp.rightElbow ||
        bp.rightLowerArm || bp.rightHand) { meshes.add('right arm'); }
    if (bp.leftUpperLeg  || bp.rightUpperLeg  ||
        bp.leftKnee      || bp.rightKnee      ||
        bp.leftLowerLeg  || bp.rightLowerLeg  ||
        bp.leftFoot      || bp.rightFoot) { meshes.add('leg'); }
    return meshes;
  }

  /// Pushes the current selection into the model viewer as red highlights.
  /// Android/iOS: calls window.syncSelection() via the webview_flutter controller.
  /// Windows:     handled by WindowsModelViewer.didUpdateWidget reacting to
  ///              the updated selectedMeshNames parameter.
  void _syncHighlights(BodyParts bp) {
    final selected = _selectedMeshNames(bp);
    final json = '[${selected.map((s) => '"$s"').join(',')}]';
    _webViewController?.runJavaScript(
      "if(window.syncSelection)syncSelection('$json');",
    );
    // Windows viewer receives selectedMeshNames via build() → didUpdateWidget.
  }


  // ── Label overlay ────────────────────────────────────────────────────────

  /// Toggles all [BodyParts] fields that belong to [meshName].
  /// If any field is currently on, all are turned off (deselect).
  /// If all fields are off, all are turned on (select).
  BodyParts _toggleMeshName(BodyParts bp, String meshName) {
    final n = meshName.toLowerCase();
    final isOn = _selectedMeshNames(bp).contains(n);
    switch (n) {
      case 'head':
        return bp.copyWith(head: !isOn, neck: !isOn);
      case 'body':
        return bp.copyWith(upperBody: !isOn, abdomen: !isOn, lowerBody: !isOn);
      case 'left arm':
        return bp.copyWith(
          leftShoulder: !isOn, leftUpperArm: !isOn,
          leftElbow:    !isOn, leftLowerArm: !isOn, leftHand: !isOn,
        );
      case 'right arm':
        return bp.copyWith(
          rightShoulder: !isOn, rightUpperArm: !isOn,
          rightElbow:    !isOn, rightLowerArm: !isOn, rightHand: !isOn,
        );
      case 'leg':
        return bp.copyWith(
          leftUpperLeg:  !isOn, rightUpperLeg: !isOn,
          leftKnee:      !isOn, rightKnee:     !isOn,
          leftLowerLeg:  !isOn, rightLowerLeg: !isOn,
          leftFoot:      !isOn, rightFoot:     !isOn,
        );
      default:
        return bp;
    }
  }

  void _onLabelTapped(String meshName) {
    final updated = _toggleMeshName(_bodyParts, meshName);
    if (updated == _bodyParts) return;
    _applyUpdate(updated);
  }

  /// Wraps [child] in a Stack that overlays clickable label boxes and
  /// their connecting lines on top of the model viewer.
  Widget _buildLabelOverlay(Widget child) {
    final selected = _selectedMeshNames(_bodyParts).toSet();
    // Switch the label set based on which face of the model is visible.
    final labels = _isFrontView ? _kBodyLabels : _kBodyLabelsBack;
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final AppLanguage lang = SACAStateScope.of(ctx).selectedLanguage;
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return Stack(
          children: [
            Positioned.fill(child: child),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _BodyLinePainter(labels: labels, selected: selected),
                ),
              ),
            ),
            for (final def in labels)
              _buildSingleLabel(def, selected.contains(def.meshName), w, h,
                  displayText: def.label(lang)),
          ],
        );
      },
    );
  }

  Widget _buildSingleLabel(
      _BodyLabelDef def, bool isOn, double w, double h,
      {required String displayText}) {
    const kRed   = Color(0xFFD32F2F);
    const kGreen = SACAColors.triageSafeGreen;
    final borderColor = isOn ? kRed : kGreen;
    final bgColor     = isOn
        ? const Color(0xFFFFEBEE)
        : const Color(0xFFEFF7F2);

    final top  = def.labelY * h - _kLabelH / 2;
    final left = def.onLeft ? _kLabelPad : w - _kLabelPad - _kLabelW;

    return Positioned(
      left:   left,
      top:    top,
      width:  _kLabelW,
      height: _kLabelH,
      child: GestureDetector(
        onTap: () => _onLabelTapped(def.meshName),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            displayText,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: borderColor,
            ),
          ),
        ),
      ),
    );
  }

  // ── View toggle ──────────────────────────────────────────────────────────

  Widget _buildViewToggle(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        SegmentedButton<bool>(
          segments: <ButtonSegment<bool>>[
            ButtonSegment<bool>(
              value: true,
              icon: const Icon(Icons.accessibility_new_rounded),
              label: Text(SACAStrings.tr(
                context: context,
                english: 'Front',
                warlpiri: 'Nyampu',
              )),
            ),
            ButtonSegment<bool>(
              value: false,
              icon: const Icon(Icons.airline_seat_recline_normal_rounded),
              label: Text(SACAStrings.tr(
                context: context,
                english: 'Back',
                warlpiri: 'Karna',
              )),
            ),
          ],
          selected: <bool>{_isFrontView},
          onSelectionChanged: (Set<bool> s) =>
              s.first ? _showFront() : _showBack(),
        ),
        const SizedBox(width: 10),
        Tooltip(
          message: _isModelLocked
              ? SACAStrings.tr(
                  context: context,
                  english: 'Unlock model — drag to spin',
                  warlpiri: 'Jukurrpa-wantija — drag-kurra',
                )
              : SACAStrings.tr(
                  context: context,
                  english: 'Lock model — disable spinning',
                  warlpiri: 'Jukurrpa-jarri — stop spinning',
                ),
          child: IconButton.filledTonal(
            icon: Icon(
              _isModelLocked
                  ? Icons.lock_outline_rounded
                  : Icons.lock_open_rounded,
            ),
            onPressed: _toggleModelLock,
          ),
        ),
      ],
    );
  }

  // ── 3-D model viewer (Android / iOS via model_viewer_plus) ─────────────

  Widget _buildModelViewer() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: ModelViewer(
        src: _modelAsset,
        alt: '3D human body model',
        backgroundColor: const Color(0xFFF5F0E8),
        cameraControls: false,
        autoRotate: false,
        disableZoom: true,
        cameraOrbit: '0deg 75deg auto',
        shadowIntensity: 0.6,
        environmentImage: 'neutral',
        debugLogging: false,
        relatedJs: _clickJs,
        onWebViewCreated: (controller) {
          _webViewController = controller;
        },
        javascriptChannels: <JavascriptChannel>{
          JavascriptChannel(
            'BodyPartChannel',
            onMessageReceived: (msg) => _onMeshTapped(msg.message),
          ),
        },
      ),
    );
  }

  // ── 3-D model viewer (Windows via webview_windows) ───────────────────────

  Widget _buildWindowsModelViewer() {
    return WindowsModelViewer(
      isFrontView: _isFrontView,
      isLocked: _isModelLocked,
      selectedMeshNames: _selectedMeshNames(_bodyParts),
      onMeshTapped: _onMeshTapped,
    );
  }

  // ── Fallback for platforms without WebView (Web only) ───────────────────

  Widget _buildBodyImage() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.accessibility_new_rounded,
              size: 120, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            '3D model not supported on Web.\nUse the region buttons below.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _buildViewToggle(context),
        const SizedBox(height: 8),

        Expanded(
          flex: 3,
          child: _buildLabelOverlay(
            !_use3D
                ? _buildBodyImage()
                : (!kIsWeb && io.Platform.isWindows)
                    ? _buildWindowsModelViewer()
                    : _buildModelViewer(),
          ),
        ),

        const SizedBox(height: 8),
      ],
    );
  }
}
