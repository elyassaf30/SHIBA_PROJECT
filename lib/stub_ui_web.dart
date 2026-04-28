// stub_ui_web.dart
// קובץ ריק שמשמש כ-fallback למובייל/דסקטופ.
// ב-Flutter Web, ה-conditional import משתמש ב-dart:ui_web האמיתי.

// ignore_for_file: unused_element
class _FakePlatformViewRegistry {
  void registerViewFactory(String viewTypeId, dynamic viewFactory) {}
}

final platformViewRegistry = _FakePlatformViewRegistry();

dynamic createHTMLElement(String tag) => null;
