import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rabbi_shiba/utils/app_colors.dart';
// ignore: uri_does_not_exist
import '../stubs/stub_ui_web.dart' if (dart.library.ui_web) 'dart:ui_web' as ui_web;
// ignore: uri_does_not_exist
import '../stubs/stub_ui_html.dart' if (dart.library.html) 'dart:html' as html;

/// נגן וידאו חוצה-פלטפורמות: web → HtmlElementView, mobile → Chewie.
class PlatformVideoPlayer extends StatefulWidget {
  final String url;

  const PlatformVideoPlayer({super.key, required this.url});

  @override
  State<PlatformVideoPlayer> createState() => _PlatformVideoPlayerState();
}

class _PlatformVideoPlayerState extends State<PlatformVideoPlayer> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  String? _webViewId;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(PlatformVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _disposeControllers().then((_) => _init());
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  Future<void> _disposeControllers() async {
    _chewieController?.dispose();
    _chewieController = null;
    await _videoController?.dispose();
    _videoController = null;
    _webViewId = null;
  }

  Future<void> _init() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = false;
    });

    if (kIsWeb) {
      try {
        final viewId = 'pv-${DateTime.now().millisecondsSinceEpoch}';
        ui_web.platformViewRegistry.registerViewFactory(viewId, (int id) {
          final video = html.VideoElement();
          video.src = widget.url;
          video.controls = true;
          video.autoplay = true;
          video.style.width = '100%';
          video.style.height = '100%';
          video.style.objectFit = 'contain';
          video.style.background = '#000';
          video.crossOrigin = 'anonymous';
          return video;
        });
        if (mounted) setState(() { _webViewId = viewId; _loading = false; });
      } catch (e) {
        debugPrint('Web video error: $e');
        if (mounted) setState(() { _loading = false; _error = true; });
      }
      return;
    }

    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await _videoController!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.blue,
          handleColor: AppColors.navy,
          backgroundColor: Colors.white24,
          bufferedColor: Colors.white38,
        ),
      );
      if (mounted) setState(() { _loading = false; });
    } catch (e) {
      debugPrint('Mobile video error: $e');
      if (mounted) setState(() { _loading = false; _error = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: Color(0xFF4A9EFF),
                strokeWidth: 2,
              ),
              const SizedBox(height: 12),
              Text(
                'טוען סרטון...',
                style: GoogleFonts.alef(color: Colors.white38, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (_error) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.white38,
                size: 36,
              ),
              const SizedBox(height: 10),
              Text(
                'לא ניתן לטעון את הסרטון',
                style: GoogleFonts.alef(color: Colors.white38, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (kIsWeb && _webViewId != null) {
      return HtmlElementView(viewType: _webViewId!);
    }

    if (_chewieController != null) {
      return Chewie(controller: _chewieController!);
    }

    return const SizedBox.shrink();
  }
}
