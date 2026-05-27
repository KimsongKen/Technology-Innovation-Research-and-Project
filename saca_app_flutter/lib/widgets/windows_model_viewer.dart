part of '../main.dart';

/// A 3-D body model viewer for Windows desktop using [webview_windows].
///
/// Hosts a local model-viewer web component via [AssetServer] and communicates
/// mesh-tap events back to Flutter through a postMessage channel.
/// Selected regions are highlighted red; deselected regions revert to their
/// original GLB material color.
///
/// On Android / iOS the body_part.dart build method uses [_buildModelViewer]
/// (model_viewer_plus) instead — this widget is never instantiated there.
class WindowsModelViewer extends StatefulWidget {
  const WindowsModelViewer({
    super.key,
    required this.isFrontView,
    required this.isLocked,
    required this.selectedMeshNames,
    required this.onMeshTapped,
  });

  final bool isFrontView;

  /// When true the model is not draggable (camera-controls disabled).
  final bool isLocked;

  /// Lowercase GLB mesh names that are currently selected, e.g. ['head','leg'].
  /// The widget syncs these to red highlights via JS whenever the list changes.
  final List<String> selectedMeshNames;

  final ValueChanged<String> onMeshTapped;

  @override
  State<WindowsModelViewer> createState() => _WindowsModelViewerState();
}

class _WindowsModelViewerState extends State<WindowsModelViewer> {
  webview_windows.WebviewController? _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await AssetServer.start();
    final port = AssetServer.port;

    final ctrl = webview_windows.WebviewController();
    await ctrl.initialize();

    // Forward postMessage("meshName") back to Flutter.
    ctrl.webMessage.listen((msg) {
      final text = msg is String ? msg : msg.toString();
      widget.onMeshTapped(text);
    });

    final orbit = widget.isFrontView ? '0deg 75deg auto' : '180deg 75deg auto';
    final html = _buildHtml(
      port,
      orbit,
      isBackView: !widget.isFrontView,
      isLocked: widget.isLocked,
    );

    await ctrl.loadStringContent(html);

    if (mounted) setState(() { _controller = ctrl; _ready = true; });
  }

  @override
  void didUpdateWidget(covariant WindowsModelViewer old) {
    super.didUpdateWidget(old);
    if (_controller == null) return;

    if (old.isFrontView != widget.isFrontView) {
      final orbit    = widget.isFrontView ? '0deg 75deg auto' : '180deg 75deg auto';
      final isBackJs = widget.isFrontView ? 'false' : 'true';
      _controller!.executeScript(
        'window._isBackView = $isBackJs;'
        'var mv=document.querySelector("model-viewer");'
        'if(mv)mv.setAttribute("camera-orbit","$orbit");',
      );
    }

    if (old.isLocked != widget.isLocked) {
      final js = widget.isLocked
          ? 'var mv=document.querySelector("model-viewer");'
            'if(mv)mv.removeAttribute("camera-controls");'
          : 'var mv=document.querySelector("model-viewer");'
            'if(mv)mv.setAttribute("camera-controls","");';
      _controller!.executeScript(js);
    }

    // Push updated selection highlights whenever the list changes.
    final oldNames = old.selectedMeshNames;
    final newNames = widget.selectedMeshNames;
    final changed = oldNames.length != newNames.length ||
        !oldNames.toSet().containsAll(newNames);
    if (changed) {
      _syncSelection(newNames);
    }
  }

  void _syncSelection(List<String> selected) {
    if (_controller == null) return;
    final json = '[${selected.map((s) => '"$s"').join(',')}]';
    _controller!.executeScript("if(window.syncSelection)syncSelection('$json');");
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  static String _buildHtml(
    int port,
    String orbit, {
    required bool isBackView,
    required bool isLocked,
  }) => '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
  html, body { margin:0; padding:0; background:#F5F0E8; width:100%; height:100%; overflow:hidden; }
  model-viewer { width:100%; height:100%; cursor:pointer; }
</style>
<script type="module"
  src="https://ajax.googleapis.com/ajax/libs/model-viewer/3.3.0/model-viewer.min.js">
</script>
</head>
<body>
<model-viewer
  id="mv"
  src="http://127.0.0.1:$port/HumanModel.glb"
  camera-orbit="$orbit"
  ${isLocked ? '' : 'camera-controls'}
  shadow-intensity="0.6"
  environment-image="neutral"
  style="width:100%;height:100vh">
</model-viewer>
<script>
  window._isBackView = ${isBackView ? 'true' : 'false'};
(function(){
  var mv      = document.getElementById("mv");
  var RED     = [1, 0.15, 0.15, 1];
  var REGIONS = ["head", "body", "left arm", "right arm", "leg"];
  var origColors = {};

  // Build a lowercase-name → material map directly from the model.
  function matByName() {
    var map = {};
    var mats = mv.model.materials;
    for (var i = 0; i < mats.length; i++) {
      map[mats[i].name.toLowerCase().trim()] = mats[i];
    }
    return map;
  }

  // Snapshot original colors on first load so we can restore them.
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

  // Position-based click region (fallback when surfaceFromPoint misses).
  function regionFromPos(cx, cy) {
    var r    = mv.getBoundingClientRect();
    var rx   = (cx - r.left) / r.width;
    var ry   = (cy - r.top)  / r.height;
    var back = window._isBackView === true;
    if (ry < 0.22)               return "Head";
    if (ry < 0.52 && rx < 0.38) return back ? "Left Arm"  : "Right Arm";
    if (ry < 0.52 && rx > 0.62) return back ? "Right Arm" : "Left Arm";
    if (ry < 0.52)               return "Body";
    return "Leg";
  }

  // Called from Dart after every selection change.
  window.syncSelection = function(json) {
    var selected = [];
    try { selected = JSON.parse(json); } catch(e) {}
    var map = matByName();
    REGIONS.forEach(function(region) {
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
    mv.addEventListener("click", function(e) {
      try {
        var hit  = mv.surfaceFromPoint(e.clientX, e.clientY);
        var name = (hit && hit.meshName) ? hit.meshName.toLowerCase().trim() : "";
        if (!name || REGIONS.indexOf(name) < 0) {
          name = regionFromPos(e.clientX, e.clientY);
        }
        window.chrome.webview.postMessage(name);
      } catch(err) {
        window.chrome.webview.postMessage(regionFromPos(e.clientX, e.clientY));
      }
    });
  }

  if(mv.loaded){ attach(); } else { mv.addEventListener("load", attach, {once:true}); }
})();
</script>
</body>
</html>
''';

  @override
  Widget build(BuildContext context) {
    if (!_ready || _controller == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Loading 3D model…'),
          ],
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: webview_windows.Webview(_controller!),
    );
  }
}
