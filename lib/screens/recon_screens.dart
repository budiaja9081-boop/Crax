import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../services/recon.dart';
import '../theme/laxx_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/liquid_button.dart';
import '../widgets/tool_page.dart';

class ScanPage extends StatefulWidget {
  final String title;
  final String hint;
  final String buttonLabel;
  final String authText;
  final bool multiline;
  final Future<List<ScanItem>> Function(String target, Log log) run;

  const ScanPage({
    super.key,
    required this.title,
    required this.hint,
    required this.buttonLabel,
    required this.run,
    this.authText = '',
    this.multiline = false,
  });

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final _c = TextEditingController();
  final _logs = <String>[];
  bool _auth = false;
  bool _busy = false;
  List<ScanItem>? _items;
  String? _err;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    final t = _c.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _busy = true;
      _logs.clear();
      _items = null;
      _err = null;
    });
    try {
      final r = await widget.run(t, (m) {
        if (mounted) setState(() => _logs.add(m));
      });
      if (mounted) setState(() => _items = r);
    } catch (e) {
      if (mounted) setState(() => _err = 'Gagal: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _reportText() {
    final b = StringBuffer('=== CRAX REPORT: ${widget.title} ===\n')
      ..writeln('Target: ${_c.text.trim()}')
      ..writeln();
    for (final i in _items!) {
      b.writeln('[${i.level.toUpperCase()}] ${i.label}');
      b.writeln(i.value);
      b.writeln();
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final needAuth = widget.authText.isNotEmpty;
    final blocked = _busy || (needAuth && !_auth);
    final recent = _logs.length > 6 ? _logs.sublist(_logs.length - 6) : _logs;

    return ToolPage(
      title: widget.title,
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _c,
                minLines: widget.multiline ? 2 : 1,
                maxLines: widget.multiline ? 4 : 1,
                decoration: InputDecoration(hintText: widget.hint),
              ),
              if (needAuth)
                CheckboxListTile(
                  value: _auth,
                  onChanged: (v) => setState(() => _auth = v ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: Laxx.accent,
                  title: Text(widget.authText, style: t.bodySmall),
                ),
              const SizedBox(height: 10),
              LiquidButton(
                label: widget.buttonLabel,
                icon: Icons.play_arrow_rounded,
                loading: _busy,
                onPressed: blocked ? null : _go,
              ),
            ],
          ),
        ),
        if (recent.isNotEmpty) ...[
          const SizedBox(height: 14),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LOG', style: t.bodySmall),
                const SizedBox(height: 6),
                for (final l in recent) Text(l, style: t.bodySmall),
              ],
            ),
          ),
        ],
        if (_err != null) ...[
          const SizedBox(height: 14),
          GlassCard(child: Text(_err!, style: const TextStyle(color: Laxx.danger))),
        ],
        if (_items != null) ...[
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => Share.share(_reportText(), subject: 'Laporan Crax - ${widget.title}'),
            icon: const Icon(Icons.ios_share, size: 18),
            label: const Text('Bagikan laporan'),
          ),
          const SizedBox(height: 12),
          for (final i in _items!) _ItemTile(item: i),
        ],
        const SizedBox(height: 120),
      ],
    );
  }
}

class _ItemTile extends StatelessWidget {
  final ScanItem item;

  const _ItemTile({required this.item});

  Color get _color {
    switch (item.level) {
      case 'high':
        return Laxx.danger;
      case 'medium':
        return Laxx.warn;
      case 'low':
        return Laxx.accent2;
      case 'ok':
        return Laxx.ok;
      default:
        return Laxx.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4,
              height: 42,
              decoration: BoxDecoration(
                color: _color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    item.label,
                    style: t.titleMedium?.copyWith(color: _color, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(item.value, style: t.bodyMedium),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Salin',
              icon: const Icon(Icons.copy_rounded, size: 18, color: Laxx.muted),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: '${item.label}\n${item.value}'));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Disalin')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class SubdomainScreen extends StatelessWidget {
  const SubdomainScreen({super.key});

  @override
  Widget build(BuildContext context) => ScanPage(
        title: 'Subdomain',
        hint: 'contoh: example.com',
        buttonLabel: 'MULAI ENUM',
        authText: 'Saya punya izin untuk memindai domain ini',
        run: subdomains,
      );
}

class CrawlerScreen extends StatelessWidget {
  const CrawlerScreen({super.key});

  @override
  Widget build(BuildContext context) => ScanPage(
        title: 'Web Crawler',
        hint: 'contoh: https://example.com',
        buttonLabel: 'MULAI CRAWL',
        authText: 'Saya punya izin untuk memindai website ini',
        run: crawlerReport,
      );
}

class XssScreen extends StatelessWidget {
  const XssScreen({super.key});

  @override
  Widget build(BuildContext context) => ScanPage(
        title: 'XSS Detector',
        hint: 'contoh: https://example.com',
        buttonLabel: 'MULAI DETEKSI',
        authText: 'Saya punya izin tertulis untuk menguji website ini',
        run: xssDetect,
      );
}

class CraxScanScreen extends StatelessWidget {
  const CraxScanScreen({super.key});

  @override
  Widget build(BuildContext context) => ScanPage(
        title: 'Crax Scan',
        hint: 'contoh: https://example.com',
        buttonLabel: 'MULAI SCAN',
        authText: 'Saya punya izin tertulis untuk memindai website ini',
        run: craxScan,
      );
}

class WifiScreen extends StatelessWidget {
  const WifiScreen({super.key});

  @override
  Widget build(BuildContext context) => ScanPage(
        title: 'WiFi Info',
        hint: 'WIFI:T:WPA;S:NamaWiFi;P:password;;',
        buttonLabel: 'ANALISIS',
        authText: 'Ini jaringan WiFi milik saya atau yang sudah saya izinkan',
        multiline: true,
        run: wifiCheck,
      );
}
