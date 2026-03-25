import 'package:flutter/material.dart';
import 'package:rabbi_shiba/utils/animation_helpers.dart';
import 'package:rabbi_shiba/utils/theme_helpers.dart';
import 'package:rabbi_shiba/widgets/state_widgets.dart';

/// Base class for screens that fetch and display data with loading/error states
abstract class BaseDataScreenWidget extends StatefulWidget {
  const BaseDataScreenWidget({super.key});
}

/// Base state class for data screens
abstract class BaseDataScreenState<T extends BaseDataScreenWidget>
    extends State<T>
    with SingleTickerProviderStateMixin {
  bool isLoading = false;
  bool hasError = false;
  bool isOffline = false;
  String? errorMessage;
  late AnimationController animationController;
  late Animation<double> fadeAnimation;

  @override
  void initState() {
    super.initState();
    setupAnimation();
  }

  void setupAnimation() {
    animationController = AnimationHelpers.createFadeController(
      this,
      durationMs: 800,
    );
    fadeAnimation = AnimationHelpers.createFadeAnimation(animationController);
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  /// Subclasses override this to fetch their specific data
  Future<void> fetchData();

  /// Initialize the screen by fetching data and animating in
  Future<void> initializeAndAnimate() async {
    try {
      setState(() {
        isLoading = true;
        hasError = false;
        errorMessage = null;
      });

      await fetchData();

      if (mounted) {
        setState(() => isLoading = false);
        animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = e.toString();
        });
      }
    }
  }

  /// Retry fetching data
  Future<void> retryFetch() => initializeAndAnimate();

  /// Build the app bar - override if you need custom title/subtitle
  PreferredSize buildAppBar({
    required String title,
    String subtitle = '',
    VoidCallback? onBackPressed,
  }) {
    return ThemeHelpers.buildDefaultAppBar(
      title: title,
      subtitle: subtitle,
      onBackPressed: onBackPressed ?? () => Navigator.pop(context),
      context: context,
    );
  }

  /// Build the main content - override in subclasses
  Widget buildContent();

  /// Full scaffold build with standard UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(
        title: 'מסך דת',
        onBackPressed: () => Navigator.pop(context),
      ),
      body: Stack(
        children: [
          ThemeHelpers.buildDefaultBackground(),
          FadeTransition(
            opacity: fadeAnimation,
            child: StateBuilder(
              isLoading: isLoading,
              hasError: hasError,
              isOffline: isOffline,
              errorMessage: errorMessage,
              onRetry: retryFetch,
              contentBuilder: (_) => buildContent(),
            ),
          ),
        ],
      ),
    );
  }
}
