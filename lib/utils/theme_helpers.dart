import 'dart:math' show pi;
import 'package:flutter/material.dart';

class ThemeHelpers {
  static Widget buildDefaultBackground() {
    return const _AnimatedGradientBackground();
  }
}

class _AnimatedGradientBackground extends StatefulWidget {
  const _AnimatedGradientBackground();

  @override
  State<_AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState
    extends State<_AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // פלטות חזקות ומיוחדות — ירוק-ים-תכלת-כחול בגוונים עמוקים
  static const _palettes = [
    // לילה — כחול אוקיינוס עמוק + ירקרק-בתולי
    [
      Color(0xFF8EC5D6), // תכלת-ים עמוק
      Color(0xFF6BAED4), // כחול אוקיינוס
      Color(0xFF7DC4B8), // ירוק-ים
      Color(0xFF5B9FBF), // כחול פיורד
    ],
    // זריחה — ירוק בוקר + תכלת-זהב
    [
      Color(0xFF7EC8A4), // ירוק ג׳ייד בהיר
      Color(0xFF6AB8CC), // תכלת בהיר
      Color(0xFF9ECFB0), // ירוק מנטה מיוחד
      Color(0xFF78BDD4), // כחול-תכלת
    ],
    // בוקר — ירקרק-אגם + כחול-אמרלד
    [
      Color(0xFF5BBCB0), // ירוק אמרלד
      Color(0xFF5AA8CC), // כחול ים תיכוני
      Color(0xFF72C4A8), // ירוק-תכלת זך
      Color(0xFF639EC0), // כחול-אינדיגו עדין
    ],
    // צהריים — ירוק טרופי + תכלת יצירתי
    [
      Color(0xFF4DB8A0), // ירוק טרופי
      Color(0xFF4EA8C8), // כחול-שמים מיוחד
      Color(0xFF60C4A4), // ירוק אקווה
      Color(0xFF5294B8), // כחול מיידנייט-ים
    ],
    // שקיעה — ירוק-ים מיסטי + כחול-פורפור
    [
      Color(0xFF6AADBC), // ירוק-כחול מיסטי
      Color(0xFF7898CC), // כחול-לבנדר ים
      Color(0xFF5FBCAC), // ירוק פטרול
      Color(0xFF6A8EC4), // כחול-אינדיגו מיוחד
    ],
    // ערב — כחול נייבי + ירוק מחשוף
    [
      Color(0xFF6898C0), // כחול-נייבי עדין
      Color(0xFF5A9CB0), // ירוק-כחול פטרול
      Color(0xFF7890C8), // כחול מחשוף
      Color(0xFF5490A8), // כחול-פלדה
    ],
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _getPaletteIndex() {
    final hour = DateTime.now().hour;
    if (hour < 6) return 0;
    if (hour < 10) return 1;
    if (hour < 13) return 2;
    if (hour < 17) return 3;
    if (hour < 20) return 4;
    return 5;
  }

  @override
  Widget build(BuildContext context) {
    final paletteIndex = _getPaletteIndex();
    final nextPaletteIndex = (paletteIndex + 1) % _palettes.length;
    final current = _palettes[paletteIndex];
    final next = _palettes[nextPaletteIndex];
    final screenSize = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final colors = List.generate(
          4,
          (i) => Color.lerp(current[i], next[i], t)!,
        );

        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colors[0], colors[1], colors[2], colors[3]],
              stops: const [0.0, 0.38, 0.65, 1.0],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -80,
                right: -60,
                child: _FloatingOrb(
                  size: 320,
                  color: colors[0].withValues(alpha: 0.45),
                  animValue: t,
                  phase: 0.0,
                ),
              ),
              Positioned(
                bottom: -100,
                left: -80,
                child: _FloatingOrb(
                  size: 360,
                  color: colors[3].withValues(alpha: 0.38),
                  animValue: t,
                  phase: 0.5,
                ),
              ),
              Positioned(
                top: screenSize.height * 0.32,
                right: screenSize.width * 0.06,
                child: _FloatingOrb(
                  size: 200,
                  color: colors[1].withValues(alpha: 0.3),
                  animValue: t,
                  phase: 0.25,
                ),
              ),
              Positioned(
                top: screenSize.height * 0.1,
                left: screenSize.width * 0.04,
                child: _FloatingOrb(
                  size: 130,
                  color: colors[2].withValues(alpha: 0.35),
                  animValue: t,
                  phase: 0.75,
                ),
              ),
              Positioned(
                bottom: screenSize.height * 0.1,
                left: screenSize.width * 0.3,
                child: _FloatingOrb(
                  size: 150,
                  color: colors[0].withValues(alpha: 0.25),
                  animValue: t,
                  phase: 0.6,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FloatingOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double animValue;
  final double phase;

  const _FloatingOrb({
    required this.size,
    required this.color,
    required this.animValue,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    final progress = ((animValue + phase) % 1.0) * 2 * pi;
    final dy = (progress - pi).abs() / pi * 22 - 11;
    final dx = dy * 0.45;

    return Transform.translate(
      offset: Offset(dx, dy),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0.0)],
            stops: const [0.0, 1.0],
          ),
        ),
      ),
    );
  }
}
