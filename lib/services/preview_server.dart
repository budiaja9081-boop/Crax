import 'dart:io';
import 'package:path/path.dart' as p;

/// Server HTTP kecil di localhost untuk preview hasil coding di browser.
class PreviewServer {
  static HttpServer? _server;
  static String? _root;

  static Future<int> start(String rootPath) async {
    await stop();
    _root = p.normalize(rootPath);
    for (var port = 8080; port < 8090; port++) {
      try {
        _server = await HttpServer.bind(InternetAddress.loopback, port);
        _server!.listen(_handle);
        return port;
      } catch (_) {}
    }
    throw Exception('Port 8080-8089 sedang dipakai');
  }

  static Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  static Future<void> _handle(HttpRequest req) async {
    try {
      var rel = Uri.decodeComponent(req.uri.path);
      if (rel == '/' || rel.isEmpty) rel = '/index.html';
      final full = p.normalize(p.join(_root!, rel.substring(1)));
      final file = File(full);
      if (!p.isWithin(_root!, full) || !await file.exists()) {
        req.response.statusCode = HttpStatus.notFound;
        req.response.write('404 - File tidak ditemukan di workspace Crax');
      } else {
        req.response.headers.contentType = ContentType.parse(_mime(full));
        await req.response.addStream(file.openRead());
      }
    } catch (_) {
      req.response.statusCode = HttpStatus.internalServerError;
    } finally {
      await req.response.close();
    }
  }

  static String _mime(String path) {
    switch (p.extension(path).toLowerCase()) {
      case '.html':
      case '.htm':
        return 'text/html; charset=utf-8';
      case '.css':
        return 'text/css; charset=utf-8';
      case '.js':
        return 'application/javascript; charset=utf-8';
      case '.json':
        return 'application/json; charset=utf-8';
      case '.png':
        return 'image/png';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.svg':
        return 'image/svg+xml';
      case '.md':
      case '.txt':
        return 'text/plain; charset=utf-8';
      default:
        return 'application/octet-stream';
    }
  }
}
