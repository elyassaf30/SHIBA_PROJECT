import 'package:flutter/material.dart';

/// Centralized animation setup and helpers
class AnimationHelpers {
  /// Creates a standard fade-in animation controller
  static AnimationController createFadeController(
    TickerProvider vsync, {
    int durationMs = 800,
  }) {
    return AnimationController(
      vsync: vsync,
      duration: Duration(milliseconds: durationMs),
    );
  }

  /// Creates a fade animation from the controller
  static Animation<double> createFadeAnimation(
    AnimationController controller, {
    Curve curve = Curves.easeInOut,
  }) {
    return Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: controller, curve: curve));
  }

  /// Creates both controller and animation together
  static Map<String, dynamic> createFadeAnimationPair(
    TickerProvider vsync, {
    int durationMs = 800,
    Curve curve = Curves.easeInOut,
  }) {
    final controller = createFadeController(vsync, durationMs: durationMs);
    final animation = createFadeAnimation(controller, curve: curve);
    return {'controller': controller, 'animation': animation};
  }

  /// Creates a scale animation controller
  static AnimationController createScaleController(
    TickerProvider vsync, {
    int durationMs = 600,
  }) {
    return AnimationController(
      vsync: vsync,
      duration: Duration(milliseconds: durationMs),
    );
  }

  /// Creates a slide animation from left
  static Animation<Offset> createSlideAnimation(
    AnimationController controller, {
    Offset begin = const Offset(-1, 0),
    Offset end = Offset.zero,
    Curve curve = Curves.easeInOut,
  }) {
    return Tween<Offset>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(parent: controller, curve: curve));
  }
}
