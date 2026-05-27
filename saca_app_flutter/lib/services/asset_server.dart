part of '../main.dart';

/// Serves Flutter bundled assets over localhost HTTP so that [webview_windows]
/// can load files like HumanModel.glb that cannot be accessed via file:// URLs.
class AssetServer {
  AssetServer._();

  static io.HttpServer? _server;
  static int _port = 0;

  static int get port => _port;

  static Future<void> start() async {
    if (_server != null) return;

    // Copy the GLB asset from the bundle into a temp directory.
    final dir = await getTemporaryDirectory();
    const assetPath = 'assets/models/HumanModel.glb';
    final bytes = await rootBundle.load(assetPath);
    final file = io.File('${dir.path}/HumanModel.glb');
    await file.writeAsBytes(bytes.buffer.asUint8List());

    _server = await io.HttpServer.bind(io.InternetAddress.loopbackIPv4, 0);
    _port = _server!.port;

    _server!.listen((req) async {
      final path = req.uri.path.replaceFirst('/', '');
      final f = io.File('${dir.path}/$path');
      if (await f.exists()) {
        req.response
          ..headers.contentType =
              io.ContentType('model', 'gltf-binary')
          ..headers.set('Access-Control-Allow-Origin', '*')
          ..add(await f.readAsBytes())
          ..close();
      } else {
        req.response
          ..statusCode = 404
          ..close();
      }
    });
  }

  static Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _port = 0;
  }
}
