import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../theme/laxx_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/liquid_button.dart';
import '../widgets/tool_page.dart';

class _Found {
  final String value;
  String status;
  _Found(this.value, this.status);
}

class QrScreen extends StatefulWidget {
  const QrScreen({super.key});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  final _picker = ImagePicker();
  final _found = <_Found>[];
  bool _busy = false;
  String _msg = 'Pilih gambar QR dari galeri.';

  Future<String> _checkUrl(String url) async {
    try {
      final r = await http
          .get(Uri.parse(url), headers: {'User-Agent': 'Crax/2.0'})
          .timeout(const Duration(seconds: 10));
      return 'HTTP ${r.statusCode}';
    } catch (e) {
      return 'Gagal dicek: ${e.toString().split('\n').first}';
    }
  }

  Future<void> _pick() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() {
      _busy = true;
      _msg = 'Membaca QR...';
      _found.clear();
    });

    final scanner = BarcodeScanner();
    try {
      final codes = await scanner.processImage(InputImage.fromFilePath(file.path));
      final values = [
        for (final c in codes)
          if ((c.rawValue ?? '').isNotEmpty) c.rawValue!,
      ];
      if (values.isEmpty) {
        setState(() => _msg = 'Tidak ada QR terbaca di gambar ini.');
      } else {
        for (final v in values) {
          final isUrl = v.startsWith('http://') || v.startsWith('https://');
          final item = _Found(v, isUrl ? 'mengecek...' : 'Data teks');
          setState(() => _found.add(item));
          if (isUrl) {
            item.status = await _checkUrl(v);
            if (mounted) setState(() {});
          }
        }
        setState(() => _msg = '${values.length} QR terbaca.');
      }
    } catch (e) {
      setState(() => _msg = 'Gagal membaca gambar: $e');
    } finally {
      await scanner.close();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ToolPage(
      title: 'QR Analyzer',
      children: [
        LiquidButton(
          label: 'PILIH GAMBAR QR',
          icon: Icons.image_search,
          color: Laxx.warn,
          loading: _busy,
          onPressed: _busy ? null : _pick,
        ),
        const SizedBox(height: 14),
        GlassCard(child: Text(_msg, style: t.bodyMedium)),
        const SizedBox(height: 14),
        for (final it in _found)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(it.value.startsWith('http') ? 'URL' : 'TEKS', style: t.bodySmall),
                  const SizedBox(height: 4),
                  SelectableText(it.value, style: t.bodyMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Status: ${it.status}',
                    style: const TextStyle(color: Laxx.accent, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
