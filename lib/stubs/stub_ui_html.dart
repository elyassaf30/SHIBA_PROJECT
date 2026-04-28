// stub_ui_html.dart
// Fallback for non-web builds. The web build uses dart:html instead.

class VideoElement {
  String? src;
  bool? controls;
  bool? autoplay;
  final style = _StubStyle();
  String? crossOrigin;
}

class _StubStyle {
  String? width;
  String? height;
  String? objectFit;
  String? background;
  String? borderRadius;
}
