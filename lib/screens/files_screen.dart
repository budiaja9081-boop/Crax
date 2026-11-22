import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import '../services/workspace.dart';
import '../theme/laxx_theme.dart';
import '../widgets/glass_card.dart';
import 'codex_screen.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  String _rel = '';
  List<FileSystemEntity> _items = [];
  String? _err;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await Workspace.list(_rel);
      if (mounted) {
        setState(() {
          _items = items;
          _err = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _err = '$e');
    }
  }

  void _go(String rel) {
    setState(() => _rel = rel);
    _load();
  }

  void _up() => _go(p.dirname(_rel) == '.' ? '' : p.dirname(_rel));

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<String?> _ask(String title, {String initial = ''}) {
    final c = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Laxx.surface,
        title: Text(title),
        content: TextField(controller: c, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, c.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirm(String msg) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Laxx.surface,
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Laxx.danger)),
          ),
        ],
      ),
    );
    return r ?? false;
  }

  Future<void> _open(String rel) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditorScreen(rel: rel)),
    );
    _load();
  }

  Future<void> _newFile() async {
    final name = await _ask('Nama file (contoh: index.html)');
    if (name == null || name.isEmpty) return;
    final rel = _rel.isEmpty ? name : '$_rel/$name';
    try {
      await Workspace.createFile(rel, '');
    } catch (e) {
      _snack('$e');
      return;
    }
    await _open(rel);
  }

  Future<void> _newFolder() async {
    final name = await _ask('Nama folder');
    if (name == null || name.isEmpty) return;
    try {
      await Workspace.createFolder(_rel.isEmpty ? name : '$_rel/$name');
      await _load();
    } catch (e) {
      _snack('$e');
    }
  }

  Future<void> _action(String v, String rel, String name) async {
    try {
      if (v == 'open') {
        await _open(rel);
        return;
      } else if (v == 'share') {
        final full = await Workspace.resolve(rel);
        await Share.shareXFiles([XFile(full)]);
      } else if (v == 'rename') {
        final n = await _ask('Nama baru', initial: name);
        if (n != null && n.isNotEmpty) await Workspace.rename(rel, n);
      } else if (v == 'delete') {
        if (await _confirm('Hapus "$name"?')) await Workspace.delete(rel);
      }
      await _load();
    } catch (e) {
      _snack('$e');
    }
  }

  IconData _iconFor(String name) {
    final ext = p.extension(name).toLowerCase();
    if (['.png', '.jpg', '.jpeg', '.gif', '.webp'].contains(ext)) {
      return Icons.image_outlined;
    }
    if (['.html', '.css', '.js', '.dart', '.py', '.php', '.java', '.cpp', '.go', '.rs', '.json', '.md']
        .contains(ext)) {
      return Icons.code_rounded;
    }
    return Icons.description_outlined;
  }

  Widget _tile(FileSystemEntity e, TextTheme t) {
    final isDir = e is Directory;
    final name = p.basename(e.path);
    final rel = Workspace.relOf(e);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(12, 4, 0, 4),
        child: Row(
          children: [
            Icon(
              isDir ? Icons.folder_rounded : _iconFor(name),
              color: isDir ? Laxx.warn : Laxx.accent,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () => isDir ? _go(rel) : _open(rel),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(name, style: t.bodyMedium, overflow: TextOverflow.ellipsis),
                ),
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Laxx.muted),
              color: Laxx.surfaceHi,
              onSelected: (v) => _action(v, rel, name),
              itemBuilder: (_) => <PopupMenuEntry<String>>[
                if (!isDir)
                  const PopupMenuItem(value: 'open', child: Text('Buka di editor')),
                if (!isDir)
                  const PopupMenuItem(value: 'share', child: Text('Unduh / bagikan')),
                const PopupMenuItem(value: 'rename', child: Text('Ganti nama')),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Hapus', style: TextStyle(color: Laxx.danger)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
        child: Column(
          children: [
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _rel.isEmpty ? null : _up,
                    icon: const Icon(Icons.arrow_upward),
                  ),
                  Expanded(
                    child: Text(
                      _rel.isEmpty ? '/workspace' : '/workspace/$_rel',
                      style: t.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    tooltip: 'File baru',
                    onPressed: _newFile,
                    icon: const Icon(Icons.note_add_outlined),
                  ),
                  IconButton(
                    tooltip: 'Folder baru',
                    onPressed: _newFolder,
                    icon: const Icon(Icons.create_new_folder_outlined),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_err != null)
              GlassCard(child: Text(_err!, style: const TextStyle(color: Laxx.danger))),
            Expanded(
              child: _items.isEmpty
                  ? Center(child: Text('Folder kosong', style: t.bodySmall))
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 120),
                      children: [for (final e in _items) _tile(e, t)],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
