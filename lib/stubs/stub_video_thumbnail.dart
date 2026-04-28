// stub_video_thumbnail.dart
// Fallback for web builds. Mobile/desktop builds use the real video_thumbnail package.
// ignore_for_file: constant_identifier_names
import 'dart:typed_data';

enum ImageFormat { JPEG, PNG, WEBP }

class VideoThumbnail {
  static Future<Uint8List?> thumbnailData({
    required String video,
    String? thumbnailPath,
    ImageFormat imageFormat = ImageFormat.PNG,
    int maxHeight = 0,
    int maxWidth = 0,
    int timeMs = 0,
    int quality = 10,
  }) async => null;
}
