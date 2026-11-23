import 'dart:io';
import 'dart:ui' as ui;
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
  final String kind;
  final List<String> notes;
  String status;
  _Found(this.value, this.kind, this.notes, this.status);
}

/// Perbesar gambar dan beri border putih supaya QR kecil lebih mudah dibaca.
Future<String> _padded(String path) async {
  final bytes = await File(path).readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes, targetWidth: 1000);
  final frame = await codec.getNextFrame();
  final img = frame.image;
  const pad = 90.0;
  final w = img.width + pad * 2;
  final h = img.height + pad * 2;
  final rec = ui.PictureRecorder();
  final canvas = ui.Canvas(rec, ui.Rect.fromLTWH(0, 0, w, h));
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, w, h),
    ui.Paint()..color = const ui.Color(0xFFFFFFFF),
  );
  canvas.drawImage(img, const ui.Offset(pad, pad), ui.Paint());
  final out = await rec.endRecording().toImage(w.toInt(), h.toInt());
  final data = await out.toByteData(format: ui.ImageByteFormat.png);
  final f = File('${path}_pad.png');
  await f.writeAsBytes(data!.buffer.asUint8List());
  return f.path;
}

/// Ambil satu tag dari data QRIS (format EMVCo: 2 digit tag, 2 digit panjang, nilai).
String? _emvTag(String s, String tag) {
  var i = 0;
  while (i + 4 <= s.length) {
    final t = s.substring(i, i + 2);
    final len = int.tryParse(s.substring(i + 2, i + 4));
    if (len == null) return null;
    final start = i + 4;
    if (start + len > s.length) return null;
    if (t == tag) return s.substring(start, start + len);
    i = start + len;
  }
  return null;
}

_Found _classify(String v) {
  final l = v.toLowerCase();
  if (v.startsWith('000201')) {
    final merchant = _emvTag(v, '59');
    final city = _emvTag(v, '60');
    return _Found(v, 'QRIS / pembayaran', [
      if (merchant != null) 'Nama merchant: $merchant',
      if (city != null) 'Kota: $city',
      'Ini kode pembayaran. Pastikan penerimanya benar sebelum transfer.',
    ], 'Data QRIS');
  }
  if (l.startsWith('http://') || l.startsWith('https://')) {
    return _Found(v, 'URL', [], 'mengecek...');
  }
  if (l.startsWith('wifi:')) {
    return _Found(v, 'WiFi', ['Buka menu WiFi Info untuk analisis'], '-');
  }
  if (l.startsWith('begin:vcard')) return _Found(v, 'Kontak vCard', [], '-');
  if (l.startsWith('geo:')) return _Found(v, 'Lokasi', [], '-');
  if (l.startsWith('mailto:')) return _Found(v, 'Email', [], '-');
  if (l.startsWith('tel:')) return _Found(v, 'Telepon', [], '-');
  return _Found(v, 'Teks', [], '-');
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

  Future<List<String>> _decode(String path) async {
    final scanner = BarcodeScanner();
    try {
      final codes = await scanner.processImage(InputImage.fromFilePath(path));
      return [
        for (final c in codes)
          if ((c.rawValue ?? '').isNotEmpty) c.rawValue!,
      ];
    } finally {
      await scanner.close();
    }
  }

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

    try {
      var values = await _decode(await _padded(file.path));
      if (values.isEmpty) values = await _decode(file.path);

      if (values.isEmpty) {
        setState(() => _msg =
            'Tidak ada QR terbaca. Coba screenshot yang lebih tajam, tanpa blur, dan QR-nya penuh di frame.');
      } else {
        final items = [for (final v in values) _classify(v)];
        setState(() => _found.addAll(items));
        for (final it in items.where((i) => i.kind == 'URL')) {
          it.status = await _checkUrl(it.value);
          if (mounted) setState(() {});
        }
        setState(() => _msg = '${values.length} QR terbaca.');
      }
    } catch (e) {
      setState(() => _msg = 'Gagal membaca gambar: $e');
    } finally {
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
                  Text(it.kind, style: t.bodySmall),
                  const SizedBox(height: 4),
                  SelectableText(it.value, style: t.bodyMedium),
                  for (final n in it.notes) ...[
                    const SizedBox(height: 6),
                    Text(n, style: t.bodySmall),
                  ],
                  if (it.status != '-') ...[
                    const SizedBox(height: 8),
                    Text(
                      'Status: ${it.status}',
                      style: const TextStyle(color: Laxx.accent, fontWeight: FontWeight.w700),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}
