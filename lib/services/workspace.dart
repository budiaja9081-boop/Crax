import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class Workspace {
  static Directory? _root;

  static Future<Directory> root() async {
    if (_root != null) return _root!;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'crax_workspace'));
    if (!await dir.exists()) await dir.create(recursive: true);
    _root = dir;
    return dir;
  }

  static String relOf(FileSystemEntity e) =>
      p.relative(e.path, from: _root!.path);

  static Future<String> resolve(String rel) async {
    final r = (await root()).path;
    final full = p.normalize(p.join(r, rel));
    if (full != r && !p.isWithin(r, full)) {
      throw Exception('Path di luar workspace');
    }
    return full;
  }

  static Future<List<FileSystemEntity>> list(String rel) async {
    final dir = Directory(await resolve(rel));
    final items = await dir.list().toList();
    items.sort((a, b) {
      final da = a is Directory;
      final db = b is Directory;
      if (da != db) return da ? -1 : 1;
      return p
          .basename(a.path)
          .toLowerCase()
          .compareTo(p.basename(b.path).toLowerCase());
    });
    return items;
  }

  static Future<List<File>> codeFiles() async {
    final r = await root();
    final out = <File>[];
    await for (final e in r.list(recursive: true)) {
      if (e is File) out.add(e);
    }
    out.sort((a, b) => a.path.compareTo(b.path));
    return out;
  }

  static Future<String> readText(String rel) async =>
      File(await resolve(rel)).readAsString();

  static Future<void> writeText(String rel, String text) async =>
      File(await resolve(rel)).writeAsString(text);

  static Future<void> createFile(String rel, String text) async {
    final f = File(await resolve(rel));
    await f.parent.create(recursive: true);
    await f.writeAsString(text);
  }

  static Future<void> createFolder(String rel) async =>
      Directory(await resolve(rel)).create(recursive: true);

  static Future<void> delete(String rel) async {
    final full = await resolve(rel);
    if (await Directory(full).exists()) {
      await Directory(full).delete(recursive: true);
    } else {
      await File(full).delete();
    }
  }

  static Future<void> rename(String rel, String newName) async {
    final src = await resolve(rel);
    final dst = p.join(p.dirname(src), newName);
    if (await Directory(src).exists()) {
      await Directory(src).rename(dst);
    } else {
      await File(src).rename(dst);
    }
  }
}
