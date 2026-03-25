import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized theme and UI styling for consistent design across app
class ThemeHelpers {
  // Gradient colors used throughout the app
  static const List<Color> defaultGradientColors = [
    Color(0xFFE3F2FD),
    Color(0xFFBBDEFB),
    Color(0xFF90CAF9),
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin ?? Alignment.topCenter,
          end: end ?? Alignment.bottomCenter,
          colors: colors ?? defaultGradientColors,
        ),
      ),
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
                  tooltip: '׳—׳–׳¨׳”',
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

