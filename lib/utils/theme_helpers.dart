import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized theme and UI styling for consistent design across app
class ThemeHelpers {
  // Gradient colors used throughout the app
  static const List<Color> defaultGradientColors = [
    Color(0xFF56CCF2),
    Color(0xFF7DD3FC),
    Color(0xFFDDEAFB),
  ];

  static const List<Color> alternateGradientColors = [
    Color(0xFF67D4F7),
    Color(0xFF9EDCFB),
    Color(0xFFEAF3FF),
  ];

  // Primary color
  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color secondaryColor = Color(0xFF6C63FF);

  /// Builds the standard gradient background used across all screens
  static Widget buildDefaultBackground({
    List<Color>? colors,
    Alignment? begin,
    Alignment? end,
  }) {
    return _AnimatedGradientBackground(
      primaryColors: colors ?? defaultGradientColors,
      secondaryColors: alternateGradientColors,
      begin: begin ?? Alignment.topCenter,
      end: end ?? Alignment.bottomCenter,
    );
  }

  /// Builds the standard app bar used across screens
  static PreferredSize buildDefaultAppBar({
    required String title,
    required String subtitle,
    VoidCallback? onBackPressed,
    BuildContext? context,
  }) {
    final isRtl =
        context != null && Directionality.of(context) == TextDirection.rtl;

    return PreferredSize(
      preferredSize: Size.fromHeight(80),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryColor.withValues(alpha: 0.9),
              secondaryColor.withValues(alpha: 0.7),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    isRtl ? Icons.arrow_forward : Icons.arrow_back,
                    color: Colors.white,
                  ),
                  iconSize: 30,
                  tooltip: 'חזרה',
                  onPressed:
                      onBackPressed ??
                      () {
                        if (context != null) {
                          Navigator.pop(context);
                        }
                      },
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.alef(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 4,
                            color: Colors.black45,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: GoogleFonts.rubikDirt(
                          fontSize: 12,
                          color: Colors.white70,
                          shadows: [
                            Shadow(
                              blurRadius: 2,
                              color: Colors.black45,
                              offset: Offset(0.5, 0.5),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                SizedBox(width: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Common text styles

  static TextStyle get titleStyle => GoogleFonts.alef(
    fontWeight: FontWeight.bold,
    fontSize: 28,
    color: Colors.black,
    shadows: [
      Shadow(blurRadius: 5, color: Colors.black45, offset: Offset(1, 1)),
    ],
  );

  static TextStyle get subtitleStyle => GoogleFonts.rubikDirt(
    fontSize: 16,
    color: Colors.black,
    shadows: [
      Shadow(blurRadius: 3, color: Colors.black45, offset: Offset(1, 1)),
    ],
  );

  static TextStyle get cardTitleStyle => GoogleFonts.alef(
    fontWeight: FontWeight.bold,
    fontSize: 16,
    color: Colors.white,
  );

  static TextStyle get cardSubtitleStyle =>
      TextStyle(fontSize: 14, color: Colors.white70);

  /// Box shadow for cards
  static final cardBoxShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  /// Border radius for cards
  static const BorderRadius cardBorderRadius = BorderRadius.all(
    Radius.circular(16),
  );
}

class _AnimatedGradientBackground extends StatefulWidget {
  const _AnimatedGradientBackground({
    required this.primaryColors,
    required this.secondaryColors,
    required this.begin,
    required this.end,
  });

  final List<Color> primaryColors;
  final List<Color> secondaryColors;
  final Alignment begin;
  final Alignment end;

  @override
  State<_AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState
    extends State<_AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        final colors = List<Color>.generate(widget.primaryColors.length, (
          index,
        ) {
          final fallback = widget.primaryColors[index];
          final to =
              index < widget.secondaryColors.length
                  ? widget.secondaryColors[index]
                  : fallback;
          return Color.lerp(fallback, to, t) ?? fallback;
        });

        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: widget.begin,
              end: widget.end,
              colors: colors,
            ),
          ),
        );
      },
    );
  }
}
