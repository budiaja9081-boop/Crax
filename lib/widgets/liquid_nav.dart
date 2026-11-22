import 'package:flutter/material.dart';
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
    final n = icons.length;
    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: Laxx.surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: Laxx.border),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedAlign(
              alignment: Alignment(-1 + 2 * index / (n - 1), 0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
              child: FractionallySizedBox(
                widthFactor: 1 / n,
                heightFactor: 0.84,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Laxx.accent, Laxx.accent2],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(color: Laxx.accent.withOpacity(0.35), blurRadius: 18),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < n; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(i),
                    child: _NavItem(
                      icon: icons[i],
                      label: labels[i],
                      active: i == index,
                    ),
                  ),
                ),
            ],
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

  const _NavItem({required this.icon, required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    final c = active ? Colors.white : Laxx.muted;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedScale(
          scale: active ? 1.12 : 1,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
          child: Icon(icon, color: c, size: 22),
        ),
        const SizedBox(height: 2),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: TextStyle(
            fontSize: 11,
            fontWeight: active ? FontWeight.w800 : FontWeight.w500,
            color: c,
          ),
          child: Text(label),
        ),
      ],
    );
  }
}
