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
      _ToolItem('Payload Library', 'Payload latihan XSS, SQLi, dll',
          Icons.bug_report_outlined, Laxx.danger, () => const PayloadScreen()),
      _ToolItem('Crax Scan', 'Segera hadir', Icons.radar, Laxx.muted, null),
      _ToolItem('Subdomain', 'Segera hadir', Icons.account_tree_outlined,
          Laxx.muted, null),
      _ToolItem('XSS Detector', 'Segera hadir', Icons.code_off, Laxx.muted, null),
      _ToolItem('Crawler', 'Segera hadir', Icons.travel_explore, Laxx.muted, null),
      _ToolItem('WiFi Info', 'Segera hadir', Icons.wifi, Laxx.muted, null),
    ];

    return GridView.count(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 130),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.95,
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
      child: Opacity(
        opacity: soon ? 0.55 : 1,
        child: GlassCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          item.color.withOpacity(0.35),
                          item.color.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: item.color.withOpacity(0.5)),
                    ),
                    child: Icon(item.icon, color: item.color, size: 24),
                  ),
                  const Spacer(),
                  if (soon)
                    Text(
                      'SEGERA',
                      style: t.bodySmall?.copyWith(fontSize: 10, letterSpacing: 1.5),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: t.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    style: t.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
