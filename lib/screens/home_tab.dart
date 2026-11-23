import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/session.dart';
import '../theme/laxx_theme.dart';
import '../widgets/anime_banner.dart';
import '../widgets/glass_card.dart';

class HomeTab extends StatefulWidget {
  final Session session;
  final String user;

  const HomeTab({super.key, required this.session, required this.user});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _cmd = TextEditingController();
  final _out = <String>['CRAX shell. Ketik "help" untuk daftar perintah.'];
  String _name = '';
  String _ip = 'memuat...';

  @override
  void initState() {
    super.initState();
    widget.session.profile(widget.user).then((p) {
      if (mounted) setState(() => _name = p['name'] ?? widget.user);
    });
    _loadIp();
  }

  @override
  void dispose() {
    _cmd.dispose();
    super.dispose();
  }

  Future<void> _loadIp() async {
    setState(() => _ip = 'memuat...');
    try {
      final r = await http
          .get(Uri.parse('https://api.ipify.org'))
          .timeout(const Duration(seconds: 8));
      if (mounted) setState(() => _ip = r.body.trim());
    } catch (_) {
      if (mounted) setState(() => _ip = 'gagal dicek (offline?)');
    }
  }

  void _run(String raw) {
    final c = raw.trim().toLowerCase();
    if (c.isEmpty) return;
    if (c == 'clear') {
      setState(() {
        _out.clear();
        _cmd.clear();
      });
      return;
    }
    final lines = <String>['> $raw'];
    if (c == 'help') {
      lines.add('perintah: help, whoami, ip, date, tools, clear');
    } else if (c == 'whoami') {
      lines.add('${widget.user} ($_name)');
    } else if (c == 'ip') {
      lines.add(_ip);
    } else if (c == 'date') {
      lines.add(DateTime.now().toString());
    } else if (c == 'tools') {
      lines.add('QR, Hash, IP, Number, Payload, Crax Scan, Subdomain, XSS, Crawler, WiFi');
    } else {
      lines.add('perintah tidak dikenal: $raw');
    }
    setState(() {
      _out.addAll(lines);
      _cmd.clear();
    });
  }

  Widget _stat(String label, String value) {
    final t = Theme.of(context).textTheme;
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: t.bodySmall),
            const SizedBox(height: 4),
            Text(
              value,
              style: t.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 130),
      children: [
        AnimeBanner(
          title: 'CRAX',
          subtitle: _name.isEmpty ? 'Selamat datang' : 'Selamat datang, $_name',
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _stat('Tools', '10 modul'),
            const SizedBox(width: 10),
            _stat('Sesi', widget.user),
            const SizedBox(width: 10),
            _stat('Versi', 'v2.0'),
          ],
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Row(
            children: [
              const Icon(Icons.public, color: Laxx.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('IP publik kamu', style: t.bodySmall),
                    SelectableText(_ip, style: t.titleMedium),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Perbarui',
                onPressed: _loadIp,
                icon: const Icon(Icons.refresh, color: Laxx.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 200,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Laxx.border),
                ),
                child: ListView(
                  children: [
                    for (final l in _out)
                      Text(
                        l,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          height: 1.4,
                          color: Laxx.ok,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _cmd,
                onSubmitted: _run,
                style: const TextStyle(fontFamily: 'monospace'),
                decoration: const InputDecoration(
                  hintText: 'ketik perintah...',
                  prefixIcon: Icon(Icons.terminal, color: Laxx.accent),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
