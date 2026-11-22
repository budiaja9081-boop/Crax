import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/laxx_theme.dart';

class LiquidNav extends StatelessWidget {
  final List<IconData> icons;
  final List<String> labels;
  final int index;
  final ValueChanged<int> onTap;

  const LiquidNav({
    super.key,
    required this.icons,
    required this.labels,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Laxx.surface.withOpacity(0.94),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: Laxx.border),
        boxShadow: const [
          BoxShadow(color: Colors.black87, blurRadius: 28, offset: Offset(0, 10)),
        ],
      ),
      child: Row(
        children: [
          for (var i = 0; i < icons.length; i++)
            Expanded(
              child: _NavItem(
                icon: icons[i],
                label: labels[i],
                active: i == index,
                onTap: () => onTap(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = active ? Laxx.bg : Laxx.muted;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(colors: [Laxx.accent, Laxx.accent2])
              : null,
          borderRadius: BorderRadius.circular(30),
          boxShadow: active
              ? [BoxShadow(color: Laxx.accent.withOpacity(0.35), blurRadius: 16)]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: active ? 1.1 : 1,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutBack,
              child: Icon(icon, size: 22, color: fg),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.sairaStencilOne(
                fontSize: 12,
                letterSpacing: 0.8,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
