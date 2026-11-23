import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimeBanner extends StatelessWidget {
  final String title;
  final String subtitle;

  const AnimeBanner({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: 170,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _BannerPainter()),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    title,
                    style: t.headlineMedium?.copyWith(
                      fontSize: 34,
                      letterSpacing: 6,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: t.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final rect = Offset.zero & s;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B0F3B), Color(0xFF0B3B4F), Color(0xFF00A88F)],
        ).createShader(rect),
    );

    final c = Offset(s.width * 0.82, s.height * 0.35);
    final ray = Paint()
      ..color = Colors.white.withOpacity(0.07)
      ..strokeWidth = 2;
    for (var i = 0; i < 24; i++) {
      final a = i * math.pi * 2 / 24;
      canvas.drawLine(c, c + Offset(math.cos(a), math.sin(a)) * s.width, ray);
    }
    canvas.drawCircle(c, 60, Paint()..color = const Color(0xFFFFB84D).withOpacity(0.25));
    canvas.drawCircle(c, 46, Paint()..color = const Color(0xFFFF4D6D).withOpacity(0.85));

    final streak = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..strokeWidth = 3;
    for (var i = 0; i < 7; i++) {
      final y = s.height * (0.15 + i * 0.1);
      canvas.drawLine(Offset(s.width * 0.35 + i * 12, y), Offset(s.width, y - 26), streak);
    }

    final rnd = math.Random(7);
    final star = Paint()..color = Colors.white70;
    for (var i = 0; i < 30; i++) {
      canvas.drawCircle(
        Offset(rnd.nextDouble() * s.width, rnd.nextDouble() * s.height * 0.6),
        rnd.nextDouble() * 1.6 + 0.4,
        star,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
