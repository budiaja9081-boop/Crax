import 'package:flutter/material.dart';
import '../services/osint_tools.dart';
import '../theme/laxx_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/liquid_button.dart';
import '../widgets/tool_page.dart';

class NumberScreen extends StatefulWidget {
  const NumberScreen({super.key});

  @override
  State<NumberScreen> createState() => _NumberScreenState();
}

class _NumberScreenState extends State<NumberScreen> {
  final _c = TextEditingController();
  PhoneInfo? _info;
  bool _searched = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _check() {
    setState(() {
      _info = PhoneTool.parse(_c.text);
      _searched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final info = _info;
    return ToolPage(
      title: 'Number Lookup',
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Cek format, negara, dan operator dari prefiks nomor. Tool ini tidak bisa mengetahui nama atau pemilik nomor.',
                style: t.bodySmall,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _c,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: 'contoh: 0812xxxx atau +628...',
                ),
              ),
              const SizedBox(height: 14),
              LiquidButton(label: 'CEK NOMOR', icon: Icons.search, onPressed: _check),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (_searched && info == null)
          const GlassCard(
            child: Text('Format nomor tidak valid.', style: TextStyle(color: Laxx.danger)),
          ),
        if (info != null) ...[
          ResultRow('Nomor internasional', info.number),
          ResultRow('Negara', info.country),
          ResultRow('Operator (dari prefiks)', info.operator),
          ResultRow('Format valid', info.valid ? 'Ya' : 'Tidak'),
          ResultRow('Link WhatsApp', info.waLink),
          if (info.note.isNotEmpty) ResultRow('Catatan', info.note),
        ],
      ],
    );
  }
}

class IpScreen extends StatefulWidget {
  const IpScreen({super.key});

  @override
  State<IpScreen> createState() => _IpScreenState();
}

class _IpScreenState extends State<IpScreen> {
  final _c = TextEditingController();
  bool _busy = false;
  Map<String, String>? _data;
  String? _err;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    setState(() {
      _busy = true;
      _err = null;
      _data = null;
    });
    try {
      final d = await IpTool.lookup(_c.text);
      if (mounted) setState(() => _data = d);
    } catch (e) {
      if (mounted) setState(() => _err = 'Gagal: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ToolPage(
      title: 'IP Lookup',
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Kosongkan kolom untuk melihat IP kamu sendiri.', style: t.bodySmall),
              const SizedBox(height: 12),
              TextField(
                controller: _c,
                decoration: const InputDecoration(
                  hintText: 'contoh: 8.8.8.8 (kosong = IP kamu)',
                ),
              ),
              const SizedBox(height: 14),
              LiquidButton(
                label: 'CEK IP',
                icon: Icons.travel_explore,
                color: Laxx.accent2,
                loading: _busy,
                onPressed: _busy ? null : _go,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (_err != null)
          GlassCard(child: Text(_err!, style: const TextStyle(color: Laxx.danger))),
        if (_data != null)
          for (final e in _data!.entries) ResultRow(e.key, e.value),
      ],
    );
  }
}

class HashScreen extends StatefulWidget {
  const HashScreen({super.key});

  @override
  State<HashScreen> createState() => _HashScreenState();
}

class _HashScreenState extends State<HashScreen> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final text = _c.text;
    return ToolPage(
      title: 'Hash Generator',
      children: [
        GlassCard(
          child: TextField(
            controller: _c,
            minLines: 2,
            maxLines: 5,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Ketik teks atau password untuk di-hash',
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text('Hash dihitung di HP ini, tidak dikirim ke mana pun.', style: t.bodySmall),
        const SizedBox(height: 12),
        if (text.isNotEmpty)
          for (final e in Hashes.of(text).entries) ResultRow(e.key, e.value),
      ],
    );
  }
}
