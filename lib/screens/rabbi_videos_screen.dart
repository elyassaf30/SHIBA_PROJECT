import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rabbi_shiba/widgets/platform_video_player.dart';
import 'package:rabbi_shiba/utils/theme_helpers.dart';
// On web: use the stub (no native thumbnail support).
// On mobile/desktop: use the real video_thumbnail package.
// ignore: uri_does_not_exist
import '../stubs/stub_video_thumbnail.dart'
    if (dart.library.io) 'package:video_thumbnail/video_thumbnail.dart';

class RabbiVideosScreen extends StatefulWidget {
  const RabbiVideosScreen({super.key});

  @override
  State<RabbiVideosScreen> createState() => _RabbiVideosScreenState();
}

class _RabbiVideosScreenState extends State<RabbiVideosScreen> {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _videos = [];
  bool _loading = true;
  String? _error;
  String? _selectedVideoUrl;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    if (mounted) setState(() { _loading = true; _error = null; });

    try {
      final files = await _supabase.storage.from('videos').list();

      final videos = files
          .where((f) => !f.name.startsWith('.') && f.name != 'emptyFolderPlaceholder')
          .map((f) => {
                'name': f.name,
                'url': _supabase.storage.from('videos').getPublicUrl(f.name),
                'created_at': f.createdAt,
              })
          .toList();

      // Sort oldest-first so index 0 = video #1
      videos.sort((a, b) {
        final aDate = a['created_at']?.toString() ?? '';
        final bDate = b['created_at']?.toString() ?? '';
        return aDate.compareTo(bDate);
      });

      if (mounted) setState(() { _videos = videos; _loading = false; });
    } catch (e) {
      debugPrint('Error loading videos from storage: $e');
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _closePlayer() {
    if (mounted) setState(() => _selectedVideoUrl = null);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          iconTheme: IconThemeData(
            color: const Color(0xFF0C2D5E).withValues(alpha: 0.85),
          ),
          title: Text(
            'סרטוני הרב',
            style: GoogleFonts.alef(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0C2D5E),
              letterSpacing: 0.5,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: const Color(0xFF0C2D5E).withValues(alpha: 0.85),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Stack(
          children: [
            Positioned.fill(child: ThemeHelpers.buildDefaultBackground()),
            SafeArea(
              child: Column(
                children: [
                  if (_selectedVideoUrl != null) _buildPlayerSection(),
                  Expanded(child: _buildBody()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerSection() {
    return Container(
      color: Colors.black,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A0A0A), Color(0xFF111111)],
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _closePlayer,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                      size: 18,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A9EFF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF4A9EFF).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4A9EFF),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'מופעל',
                        style: GoogleFonts.alef(
                          fontSize: 11,
                          color: const Color(0xFF4A9EFF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 240,
            child: PlatformVideoPlayer(
              key: ValueKey(_selectedVideoUrl),
              url: _selectedVideoUrl!,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0C2D5E).withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    color: Color(0xFF1A5FB4),
                    strokeWidth: 2.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'טוען סרטונים...',
              style: GoogleFonts.alef(
                fontSize: 14,
                color: const Color(0xFF0C2D5E).withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0C2D5E).withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 32,
                  color: Color(0xFFB45309),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'שגיאה בטעינת הסרטונים',
                style: GoogleFonts.alef(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0D1B33),
                ),
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: _loadVideos,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.45),
                  foregroundColor: const Color(0xFF1A5FB4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text('נסה שוב', style: GoogleFonts.alef(fontSize: 14)),
              ),
            ],
          ),
        ),
      );
    }

    if (_videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0C2D5E).withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.video_library_outlined,
                size: 40,
                color: Color(0xFF1A5FB4),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'לא נמצאו סרטונים',
              style: GoogleFonts.alef(
                fontSize: 16,
                color: const Color(0xFF0D1B33).withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadVideos,
      color: const Color(0xFF1A5FB4),
      backgroundColor: Colors.white,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.0,
        ),
        itemCount: _videos.length,
        itemBuilder: (context, index) {
          final video = _videos[index];
          final isSelected = video['url'] == _selectedVideoUrl;
          // index 0 = oldest = #1, last index = newest = #N
          final displayNumber = index + 1;
          return VideoItemWidget(
            url: video['url'] as String,
            name: video['name'] as String,
            isSelected: isSelected,
            displayNumber: displayNumber,
            onTap: () => setState(() => _selectedVideoUrl = video['url'] as String),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// VideoItemWidget
// ─────────────────────────────────────────────
class VideoItemWidget extends StatefulWidget {
  final String url;
  final String name;
  final bool isSelected;
  final int displayNumber;
  final VoidCallback onTap;

  const VideoItemWidget({
    super.key,
    required this.url,
    required this.name,
    required this.isSelected,
    required this.displayNumber,
    required this.onTap,
  });

  @override
  State<VideoItemWidget> createState() => _VideoItemWidgetState();
}

class _VideoItemWidgetState extends State<VideoItemWidget> {
  // Shared across all instances for the session — avoids re-generating on rebuild
  static final Map<String, Uint8List?> _cache = {};

  Uint8List? _thumbnail;
  bool _thumbnailLoading = true;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    // Return cached result immediately
    if (_cache.containsKey(widget.url)) {
      if (mounted) {
        setState(() {
          _thumbnail = _cache[widget.url];
          _thumbnailLoading = false;
        });
      }
      return;
    }

    // Web: no native video decoding available
    if (kIsWeb) {
      _cache[widget.url] = null;
      if (mounted) setState(() => _thumbnailLoading = false);
      return;
    }

    try {
      final bytes = await VideoThumbnail.thumbnailData(
        video: widget.url,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 320,
        quality: 75,
        timeMs: 0, // first frame
      );
      _cache[widget.url] = bytes;
      if (mounted) {
        setState(() {
          _thumbnail = bytes;
          _thumbnailLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Thumbnail error for ${widget.url}: $e');
      _cache[widget.url] = null;
      if (mounted) setState(() => _thumbnailLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? Colors.white.withValues(alpha: 0.62)
              : Colors.white.withValues(alpha: 0.48),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isSelected
                ? primary.withValues(alpha: 0.55)
                : Colors.white.withValues(alpha: 0.65),
            width: widget.isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.isSelected
                  ? primary.withValues(alpha: 0.22)
                  : const Color(0xFF0C2D5E).withValues(alpha: 0.10),
              blurRadius: widget.isSelected ? 18 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Thumbnail / placeholder ──────────────────────
              if (_thumbnailLoading)
                _ThumbnailPlaceholder(primary: primary, showSpinner: true)
              else if (_thumbnail != null)
                Image.memory(_thumbnail!, fit: BoxFit.cover)
              else
                _ThumbnailPlaceholder(primary: primary, showSpinner: false),

              // ── Bottom gradient for text readability ─────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.62),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Centered play / pause button ─────────────────
              Center(
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.isSelected
                        ? primary
                        : Colors.white.withValues(alpha: 0.9),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.isSelected
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: widget.isSelected ? Colors.white : primary,
                    size: 30,
                  ),
                ),
              ),

              // ── Number badge (top-right) ──────────────────────
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.32),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${widget.displayNumber}',
                    style: GoogleFonts.alef(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ),

              // ── Video name at bottom ──────────────────────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Text(
                    widget.name.replaceAll(RegExp(r'\.[^.]+$'), ''),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.alef(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.55),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// _ThumbnailPlaceholder
// ─────────────────────────────────────────────
class _ThumbnailPlaceholder extends StatelessWidget {
  final Color primary;
  final bool showSpinner;

  const _ThumbnailPlaceholder({
    required this.primary,
    required this.showSpinner,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary.withValues(alpha: 0.30),
            primary.withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: showSpinner
          ? Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: primary.withValues(alpha: 0.6),
                ),
              ),
            )
          : null,
    );
  }
}
