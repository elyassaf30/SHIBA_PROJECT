import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:rabbi_shiba/screens/entrance_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _logoController;
  late AnimationController _contentController;
  late AnimationController _progressController;
  late AnimationController _ringController;
  late AnimationController _particleController;
  late AnimationController _floatController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoRotation;
  late Animation<double> _glowAnimation;
  late Animation<double> _titleOpacity;
  late Animation<Offset> _titleSlide;
  late Animation<double> _subtitleOpacity;
  late Animation<double> _pillsOpacity;
  late Animation<double> _progressValue;
  late Animation<double> _progressOpacity;
  late Animation<double> _ring1Scale;
  late Animation<double> _ring1Opacity;
  late Animation<double> _ring2Scale;
  late Animation<double> _ring2Opacity;
  late Animation<double> _ring3Scale;
  late Animation<double> _ring3Opacity;
  late Animation<double> _floatOffset;

  final List<_Particle> _particles = [];
  final List<_Star> _stars = [];
  final Random _rand = Random();

  @override
  void initState() {
    super.initState();
    _generateParticles();
    _generateStars();
    _initControllers();
    _startSequence();
  }

  void _generateParticles() {
    for (int i = 0; i < 18; i++) {
      _particles.add(
        _Particle(
          x: _rand.nextDouble(),
          size: 3.0 + _rand.nextDouble() * 5.0,
          duration: Duration(milliseconds: 4000 + _rand.nextInt(4000)),
          delay: Duration(milliseconds: _rand.nextInt(6000)),
          drift: (_rand.nextDouble() - 0.5) * 80,
          colorIndex: _rand.nextInt(4),
        ),
      );
    }
  }

  void _generateStars() {
    for (int i = 0; i < 50; i++) {
      _stars.add(
        _Star(
          x: _rand.nextDouble(),
          y: _rand.nextDouble(),
          size: 1.0 + _rand.nextDouble() * 2.0,
          opacity: 0.15 + _rand.nextDouble() * 0.5,
          duration: Duration(milliseconds: 1500 + _rand.nextInt(3000)),
          delay: Duration(milliseconds: _rand.nextInt(4000)),
        ),
      );
    }
  }

  void _initControllers() {
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.08,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 70,
      ),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 0.96), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 0.96, end: 1.0), weight: 15),
    ]).animate(_logoController);

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _logoRotation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: -0.2, end: 0.05), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 0.05, end: -0.02), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -0.02, end: 0.0), weight: 15),
    ]).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOut));

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _bgController, curve: Curves.easeInOut));

    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.0, 0.7),
      ),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
    );

    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.25, 0.85),
      ),
    );
    _pillsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.5, 1.0),
      ),
    );

    _progressValue = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.15), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.15, end: 0.45), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.45, end: 0.8), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.0), weight: 20),
    ]).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _progressOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.6, 1.0),
      ),
    );

    _ring1Scale = Tween<double>(
      begin: 0.6,
      end: 2.2,
    ).animate(CurvedAnimation(parent: _ringController, curve: Curves.easeOut));
    _ring1Opacity = Tween<double>(
      begin: 0.7,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _ringController, curve: Curves.easeOut));

    final ring2Curve = CurvedAnimation(
      parent: _ringController,
      curve: const Interval(0.32, 1.0, curve: Curves.easeOut),
    );
    _ring2Scale = Tween<double>(begin: 0.6, end: 2.2).animate(ring2Curve);
    _ring2Opacity = Tween<double>(begin: 0.7, end: 0.0).animate(ring2Curve);

    final ring3Curve = CurvedAnimation(
      parent: _ringController,
      curve: const Interval(0.64, 1.0, curve: Curves.easeOut),
    );
    _ring3Scale = Tween<double>(begin: 0.6, end: 2.2).animate(ring3Curve);
    _ring3Opacity = Tween<double>(begin: 0.7, end: 0.0).animate(ring3Curve);

    _floatOffset = Tween<double>(begin: 0.0, end: -8.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    _floatController.forward();

    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _contentController.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _progressController.forward();

    await Future.delayed(const Duration(milliseconds: 3200));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 1400),
        reverseTransitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => const EntranceScreen(),
        transitionsBuilder: (_, animation, __, child) {
          final fadeAnimation = CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 0.9, curve: Curves.easeOutCubic),
          );
          final slideAnimation = Tween<Offset>(
            begin: const Offset(0.0, 0.12),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          );
          final scaleAnimation = Tween<double>(begin: 0.985, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutQuart),
          );

          return FadeTransition(
            opacity: fadeAnimation,
            child: SlideTransition(
              position: slideAnimation,
              child: ScaleTransition(scale: scaleAnimation, child: child),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _bgController.dispose();
    _logoController.dispose();
    _contentController.dispose();
    _progressController.dispose();
    _ringController.dispose();
    _particleController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFEAF6FB),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _bgController,
          _logoController,
          _contentController,
          _progressController,
          _ringController,
          _particleController,
          _floatController,
        ]),
        builder: (context, _) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFEAF6FB),
                  Color.lerp(
                    const Color(0xFFBFE3EF),
                    const Color(0xFFA7D6E8),
                    _bgController.value,
                  )!,
                  const Color(0xFFE2F3F9),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: Stack(
              children: [
                ..._stars.map((s) => _buildStar(s, size)),
                Center(child: _buildRings()),
                ..._particles.map((p) => _buildParticle(p, size)),
                SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 2),
                      _buildLogo(),
                      const SizedBox(height: 32),
                      _buildContent(),
                      const Spacer(flex: 2),
                      _buildProgress(),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStar(_Star s, Size size) {
    final sinVal = sin(
      _bgController.value * pi * 2 + s.delay.inMilliseconds * 0.001,
    );
    final opacity = s.opacity * (0.4 + 0.6 * ((sinVal + 1) / 2));
    return Positioned(
      left: s.x * size.width,
      top: s.y * size.height,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Container(
          width: s.size,
          height: s.size,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildRings() {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildRing(_ring1Scale.value, _ring1Opacity.value),
          _buildRing(_ring2Scale.value, _ring2Opacity.value),
          _buildRing(_ring3Scale.value, _ring3Opacity.value),
        ],
      ),
    );
  }

  Widget _buildRing(double scale, double opacity) {
    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF8CC4D9).withOpacity(0.32),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  static const _particleColors = [
    Color(0x668CC4D9),
    Color(0x668FD3B8),
    Color(0x66A9D9E8),
    Color(0x66D1EAF4),
  ];

  Widget _buildParticle(_Particle p, Size size) {
    final t =
        (_particleController.value + p.delay.inMilliseconds / 8000.0) % 1.0;
    if (t < 0.05) return const SizedBox.shrink();

    final progress = (t - 0.05) / 0.95;
    final y = size.height * (1 - progress) - 10;
    final x = p.x * size.width + p.drift * progress;
    final opacity =
        progress < 0.1
            ? progress / 0.1
            : progress > 0.9
            ? (1.0 - progress) / 0.1
            : 0.7;

    return Positioned(
      left: x,
      top: y,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Container(
          width: p.size,
          height: p.size,
          decoration: BoxDecoration(
            color: _particleColors[p.colorIndex],
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Transform.translate(
      offset: Offset(0, _floatOffset.value),
      child: Transform.rotate(
        angle: _logoRotation.value,
        child: Transform.scale(
          scale: _logoScale.value,
          child: Opacity(
            opacity: _logoOpacity.value,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(
                          0xFF8CC4D9,
                        ).withOpacity(_glowAnimation.value * 0.35),
                        blurRadius: 34,
                        spreadRadius: 6,
                      ),
                      BoxShadow(
                        color: const Color(
                          0xFF8CC4D9,
                        ).withOpacity(_glowAnimation.value * 0.14),
                        blurRadius: 60,
                        spreadRadius: 14,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFC6E6F2), Color(0xFFAEDAE9)],
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Image.asset('assets/icon.jpeg', fit: BoxFit.cover),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        FadeTransition(
          opacity: _titleOpacity,
          child: SlideTransition(
            position: _titleSlide,
            child: Text(
              'שיבא - כשרות דת והלכה',
              style: GoogleFonts.alef(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
                shadows: [
                  Shadow(
                    color: const Color(0xFF8CC4D9).withOpacity(0.22),
                    blurRadius: 14,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 10),
        FadeTransition(
          opacity: _subtitleOpacity,
          child: Text(
            'מחלקת כשרות דת והלכה',
            style: GoogleFonts.alef(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF475569),
              letterSpacing: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        FadeTransition(
          opacity: _pillsOpacity,
          child: Container(
            width: 48,
            height: 2,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Color(0xFF8CC4D9),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        FadeTransition(
          opacity: _pillsOpacity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPill('זמני תפילה'),
              const SizedBox(width: 10),
              _buildPill('כשרות'),
              const SizedBox(width: 10),
              _buildPill('הלכה'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF8CC4D9).withOpacity(0.34)),
        color: const Color(0xFF8CC4D9).withOpacity(0.1),
      ),
      child: Text(
        label,
        style: GoogleFonts.alef(
          fontSize: 12,
          color: const Color(0xFF334155),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildProgress() {
    return FadeTransition(
      opacity: _progressOpacity,
      child: Column(
        children: [
          SizedBox(
            width: 220,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: _progressValue.value,
                minHeight: 3,
                backgroundColor: const Color(0xFF8CC4D9).withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF7FBFD6),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '...טוען',
            style: GoogleFonts.alef(
              fontSize: 14,
              color: const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }
}

class _Particle {
  final double x;
  final double size;
  final Duration duration;
  final Duration delay;
  final double drift;
  final int colorIndex;

  const _Particle({
    required this.x,
    required this.size,
    required this.duration,
    required this.delay,
    required this.drift,
    required this.colorIndex,
  });
}

class _Star {
  final double x, y, size, opacity;
  final Duration duration, delay;

  const _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.duration,
    required this.delay,
  });
}
