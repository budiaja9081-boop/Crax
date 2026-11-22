import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/laxx_theme.dart';

class LiquidButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color color;
  final bool loading;

  const LiquidButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.color = Laxx.accent,
    this.loading = false,
  });

  @override
  State<LiquidButton> createState() => _LiquidButtonState();
}

class _LiquidButtonState extends State<LiquidButton> with TickerProviderStateMixin {
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();
  late final AnimationController _fill = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  late final Animation<double> _fillCurve = CurvedAnimation(
    parent: _fill,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );
  bool _down = false;

  @override
  void dispose() {
    _wave.dispose();
    _fill.dispose();
    super.dispose();
  }

  void _press(bool v) {
    setState(() => _down = v);
    if (v) {
      _fill.forward();
    } else {
      _fill.reverse();
    }
  }

  void _handleUp(TapUpDetails _) {
    _press(false);
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    final c = widget.color;
    final textColor = enabled ? Laxx.text : Laxx.muted;

    return GestureDetector(
      onTapDown: enabled ? (_) => _press(true) : null,
      onTapUp: enabled ? _handleUp : null,
      onTapCancel: enabled ? () => _press(false) : null,
      child: AnimatedScale(
        scale: _down ? 0.96 : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.withOpacity(enabled ? 0.55 : 0.2)),
            boxShadow: enabled
                ? [BoxShadow(color: c.withOpacity(0.25), blurRadius: 20, spreadRadius: -4)]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Positioned.fill(child: ColoredBox(color: Laxx.surfaceHi)),
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_wave, _fillCurve]),
                    builder: (_, __) => CustomPaint(
                      painter: _LiquidPainter(
                        phase: _wave.value * 2 * math.pi,
                        level: _fillCurve.value,
                        color: c,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.loading)
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: c),
                        )
                      else if (widget.icon != null)
                        Icon(widget.icon, color: textColor, size: 20),
                      if (widget.loading || widget.icon != null) const SizedBox(width: 8),
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LiquidPainter extends CustomPainter {
  final double phase;
  final double level;
  final Color color;

  _LiquidPainter({required this.phase, required this.level, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (level <= 0) return;
    final top = size.height * (1 - level);
    final path = Path()..moveTo(0, size.height);
    path.lineTo(0, top);
    for (double x = 0; x <= size.width; x += 4) {
      final y = top + math.sin((x / size.width) * 2 * math.pi + phase) * 6 * level;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.close();

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.9), color.withOpacity(0.45)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LiquidPainter old) =>
      old.phase != phase || old.level != level || old.color != color;
}
