import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/preview_server.dart';
import '../services/workspace.dart';
import '../theme/laxx_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/liquid_button.dart';

class Lang {
  final String name;
  final String ext;
  final String template;
  const Lang(this.name, this.ext, this.template);
}

const langs = <Lang>[
  Lang('HTML', 'html',
      '<!DOCTYPE html>\n<html lang="id">\n<head>\n  <meta charset="UTF-8">\n  <meta name="viewport" content="width=device-width, initial-scale=1">\n  <title>Crax</title>\n</head>\n<body>\n  <h1>Halo dari Crax</h1>\n</body>\n</html>\n'),
  Lang('CSS', 'css', 'body {\n  font-family: sans-serif;\n}\n'),
  Lang('JavaScript', 'js', 'console.log("Halo dari Crax");\n'),
  Lang('Python', 'py', 'print("Halo dari Crax")\n'),
  Lang('PHP', 'php', '<?php\necho "Halo dari Crax";\n'),
  Lang('Dart', 'dart', 'void main() {\n  print("Halo dari Crax");\n}\n'),
  Lang('Java', 'java',
      'public class Main {\n  public static void main(String[] args) {\n    System.out.println("Halo dari Crax");\n  }\n}\n'),
  Lang('C++', 'cpp',
      '#include <iostream>\n\nint main() {\n  std::cout << "Halo dari Crax" << std::endl;\n  return 0;\n}\n'),
  Lang('Go', 'go',
      'package main\n\nimport "fmt"\n\nfunc main() {\n  fmt.Println("Halo dari Crax")\n}\n'),
  Lang('Rust', 'rs', 'fn main() {\n    println!("Halo dari Crax");\n}\n'),
  Lang('JSON', 'json', '{\n  "nama": "Crax"\n}\n'),
  Lang('Markdown', 'md', '# Judul\n\nIsi catatan.\n'),
  Lang('Teks', 'txt', ''),
];

class CodexScreen extends StatefulWidget {
  const CodexScreen({super.key});

  @override
  State<CodexScreen> createState() => _CodexScreenState();
}

class _CodexScreenState extends State<CodexScreen> {
  final _nameC = TextEditingController(text: 'index');
  Lang _lang = langs.first;
  late Future<List<File>> _files;

  @override
  void initState() {
    super.initState();
    _files = Workspace.codeFiles();
  }

  @override
  void dispose() {
    _nameC.dispose();
    super.dispose();
  }

  void _refresh() => setState(() => _files = Workspace.codeFiles());

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _create() async {
    final base = _nameC.text.trim();
    if (base.isEmpty) return;
    final rel = '$base.${_lang.ext}';
    try {
      final full = await Workspace.resolve(rel);
      if (await File(full).exists()) {
        _snack('File $rel sudah ada');
        return;
      }
      await Workspace.createFile(rel, _lang.template);
    } catch (e) {
      _snack('$e');
      return;
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditorScreen(rel: rel)),
    );
    _refresh();
  }

  Widget _fileTile(File f, TextTheme t) {
    final rel = Workspace.relOf(f);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.code, color: Laxx.accent),
          title: Text(rel, style: t.bodyMedium),
          trailing: const Icon(Icons.chevron_right, color: Laxx.muted),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EditorScreen(rel: rel)),
            );
            _refresh();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Buat file / proyek baru', style: t.titleMedium),
                const SizedBox(height: 12),
                DropdownButton<Lang>(
                  value: _lang,
                  isExpanded: true,
                  dropdownColor: Laxx.surfaceHi,
                  items: [
                    for (final l in langs)
                      DropdownMenuItem(value: l, child: Text(l.name)),
                  ],
                  onChanged: (v) => setState(() => _lang = v ?? _lang),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _nameC,
                  decoration: const InputDecoration(
                    hintText: 'Nama file (tanpa ekstensi)',
                    prefixIcon: Icon(Icons.edit_note),
                  ),
                ),
                const SizedBox(height: 14),
                LiquidButton(
                  label: 'BUAT & BUKA EDITOR',
                  icon: Icons.add,
                  color: Laxx.accent,
                  onPressed: _create,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('File di workspace', style: t.titleMedium),
          const SizedBox(height: 10),
          FutureBuilder<List<File>>(
            future: _files,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final list = snap.data ?? [];
              if (list.isEmpty) {
                return GlassCard(
                  child: Text('Belum ada file. Buat file baru di atas.', style: t.bodySmall),
                );
              }
              return Column(children: [for (final f in list) _fileTile(f, t)]);
            },
          ),
        ],
      ),
    );
  }
}

class EditorScreen extends StatefulWidget {
  final String rel;

  const EditorScreen({super.key, required this.rel});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final _c = TextEditingController();
  bool _loading = true;
  bool _dirty = false;
  int? _port;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      _c.text = await Workspace.readText(widget.rel);
    } catch (_) {
      _c.text = '';
    }
    if (mounted) setState(() => _loading = false);
  }

  String get _ext => p.extension(widget.rel).replaceFirst('.', '').toLowerCase();

  bool get _previewable => const ['html', 'htm', 'css', 'js', 'svg'].contains(_ext);

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _save() async {
    try {
      await Workspace.writeText(widget.rel, _c.text);
      if (mounted) setState(() => _dirty = false);
      _snack('Tersimpan');
    } catch (e) {
      _snack('Gagal menyimpan: $e');
    }
  }

  Future<void> _preview() async {
    await _save();
    try {
      final root = (await Workspace.root()).path;
      final port = await PreviewServer.start(root);
      if (mounted) setState(() => _port = port);
      final url = 'http://localhost:$port/${Uri.encodeFull(widget.rel)}';
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      _snack('Preview gagal: $e');
    }
  }

  Future<void> _stopPreview() async {
    await PreviewServer.stop();
    if (mounted) setState(() => _port = null);
    _snack('Preview dihentikan');
  }

  Future<void> _download() async {
    try {
      final full = await Workspace.resolve(widget.rel);
      await Share.shareXFiles([XFile(full)]);
    } catch (e) {
      _snack('$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      wallKey: 'editor',
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            p.basename(widget.rel) + (_dirty ? ' •' : ''),
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            IconButton(
              tooltip: 'Simpan',
              icon: const Icon(Icons.save_outlined),
              onPressed: _save,
            ),
            if (_previewable)
              IconButton(
                tooltip: 'Preview di browser',
                icon: const Icon(Icons.play_circle_outline, color: Laxx.ok),
                onPressed: _preview,
              ),
            if (_port != null)
              IconButton(
                tooltip: 'Stop preview',
                icon: const Icon(Icons.stop_circle_outlined, color: Laxx.danger),
                onPressed: _stopPreview,
              ),
            IconButton(
              tooltip: 'Unduh',
              icon: const Icon(Icons.download_outlined),
              onPressed: _download,
            ),
            IconButton(
              tooltip: 'Ganti wallpaper editor',
              icon: const Icon(Icons.wallpaper),
              onPressed: () => pickWallpaper('editor'),
            ),
          ],
        ),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _c,
                    expands: true,
                    maxLines: null,
                    minLines: null,
                    textAlignVertical: TextAlignVertical.top,
                    onChanged: (_) {
                      if (!_dirty) setState(() => _dirty = true);
                    },
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      height: 1.4,
                      color: Laxx.text,
                    ),
                    decoration: InputDecoration(
                      fillColor: Laxx.surface.withOpacity(0.88),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
