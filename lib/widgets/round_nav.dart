import 'package:flutter/material.dart';
import '../theme/laxx_theme.dart';

class RoundNav extends StatelessWidget {
  final List<IconData> icons;
  final List<String> labels;
  final int index;
  final ValueChanged<int> onTap;

  const RoundNav({
    super.key,
    required this.icons,
    required this.labels,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Laxx.surface.withOpacity(0.94),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Laxx.border),
        boxShadow: const [
          BoxShadow(color: Colors.black87, blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (var i = 0; i < icons.length; i++)
            _Bubble(
              icon: icons[i],
              label: labels[i],
              active: i == index,
              onTap: () => onTap(i),
            ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _Bubble({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = active ? 58.0 : 46.0;
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutBack,
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? null : Laxx.surfaceHi,
            gradient: active
                ? const LinearGradient(colors: [Laxx.accent, Laxx.accent2])
                : null,
            boxShadow: active
                ? [BoxShadow(color: Laxx.accent.withOpacity(0.4), blurRadius: 18)]
                : null,
          ),
          child: Icon(icon, color: active ? Laxx.bg : Laxx.muted, size: 22),
        ),
      ),
    );
  }
}
