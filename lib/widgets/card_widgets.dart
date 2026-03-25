import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Reusable card for displaying prayer times
class PrayerTimeCard extends StatelessWidget {
  final String title;
  final String time;
  final IconData icon;
  final Color backgroundColor;
  final String? subtitle;
  final VoidCallback? onTap;

  const PrayerTimeCard({
    super.key,
    required this.title,
    required this.time,
    required this.icon,
    required this.backgroundColor,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: backgroundColor.withValues(alpha: 0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.alef(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: backgroundColor,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      subtitle!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
              ],
            ),
            Row(
              children: [
                Text(
                  time,
                  style: GoogleFonts.alef(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(width: 12),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: backgroundColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: backgroundColor, size: 24),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable bubble button widget with animation
class AnimatedBubbleButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;
  final Duration delay;

  const AnimatedBubbleButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
    this.delay = Duration.zero,
  });

  @override
  State<AnimatedBubbleButton> createState() => _AnimatedBubbleButtonState();
}

class _AnimatedBubbleButtonState extends State<AnimatedBubbleButton>
    with SingleTickerProviderStateMixin {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedOpacity(
        duration: Duration(milliseconds: 400),
        opacity: _visible ? 1.0 : 0.0,
        child: AnimatedScale(
          scale: _visible ? 1.0 : 0.85,
          duration: Duration(milliseconds: 450),
          curve: Curves.easeOutBack,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.color.withValues(alpha: 0.8),
                    widget.color.withValues(alpha: 0.6),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 4,
                    offset: Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              padding: EdgeInsets.all(8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, size: 28, color: Colors.white),
                    SizedBox(height: 6),
                    Text(
                      widget.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                        shadows: [
                          Shadow(
                            blurRadius: 3,
                            offset: Offset(1, 1),
                            color: Colors.black,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

