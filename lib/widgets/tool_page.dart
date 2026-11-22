import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/laxx_theme.dart';
import 'app_background.dart';
import 'glass_card.dart';

class ToolPage extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const ToolPage({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(title)),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: children,
          ),
        ),
      ),
    );
  }
}

class ResultRow extends StatelessWidget {
  final String label;
  final String value;

  const ResultRow(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: t.bodySmall),
                  const SizedBox(height: 2),
                  SelectableText(value, style: t.bodyMedium),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Salin',
              icon: const Icon(Icons.copy_rounded, size: 18, color: Laxx.muted),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
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
