import 'package:flutter/material.dart';
import '../theme/laxx_theme.dart';
import '../widgets/glass_card.dart';
import 'osint_screens.dart';
import 'payload_screen.dart';
import 'qr_screen.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_ToolItem>[
      _ToolItem('Number Lookup', 'Format, negara & operator', Icons.phone_android,
          Laxx.accent, () => const NumberScreen()),
      _ToolItem('IP Lookup', 'Lokasi, ISP & ASN', Icons.public,
          Laxx.accent2, () => const IpScreen()),
      _ToolItem('Hash Generator', 'MD5, SHA-1, SHA-256, SHA-512', Icons.tag,
          Laxx.ok, () => const HashScreen()),
      _ToolItem('QR Analyzer', 'Baca QR & cek URL', Icons.qr_code_scanner,
          Laxx.warn, () => const QrScreen()),
      _ToolItem('Payload Library', 'Payload latihan XSS, SQLi, dll', Icons.bug_report_outlined,
          Laxx.danger, () => const PayloadScreen()),
      _ToolItem('Crax Scan', 'Batch berikutnya', Icons.radar, Laxx.muted, null),
      _ToolItem('Subdomain', 'Batch berikutnya', Icons.account_tree_outlined, Laxx.muted, null),
      _ToolItem('XSS Detector', 'Batch berikutnya', Icons.code_off, Laxx.muted, null),
      _ToolItem('Crawler', 'Batch berikutnya', Icons.travel_explore, Laxx.muted, null),
      _ToolItem('WiFi Info', 'Batch berikutnya', Icons.wifi, Laxx.muted, null),
    ];

    return GridView.count(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.0,
      children: [for (final it in items) _ToolTile(item: it)],
    );
  }
}

class _ToolItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget Function()? page;

  const _ToolItem(this.title, this.subtitle, this.icon, this.color, this.page);
}

class _ToolTile extends StatelessWidget {
  final _ToolItem item;

  const _ToolTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final soon = item.page == null;
    return GestureDetector(
      onTap: () {
        if (soon) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Menyusul di update berikutnya')),
          );
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => item.page!()),
        );
      },
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, color: item.color),
                ),
                const Spacer(),
                if (soon)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: Laxx.muted),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('SEGERA', style: t.bodySmall?.copyWith(fontSize: 10)),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: t.titleMedium),
                const SizedBox(height: 2),
                Text(item.subtitle, style: t.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
