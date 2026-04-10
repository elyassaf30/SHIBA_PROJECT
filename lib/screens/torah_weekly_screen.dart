import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:rabbi_shiba/utils/theme_helpers.dart';

class TorahWeeklyScreen extends StatefulWidget {
  const TorahWeeklyScreen({super.key});

  @override
  State<TorahWeeklyScreen> createState() => _TorahWeeklyScreenState();
}

class _TorahWeeklyScreenState extends State<TorahWeeklyScreen> {
  List<Map<String, dynamic>> videos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadVideos();
  }

  Future<void> loadVideos() async {
    try {
      final response = await Supabase.instance.client
          .from('סרטוני_רב')
          .select()
          .order('שבוע_של', ascending: false);

      setState(() {
        videos = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('שגיאה בטעינת סרטונים: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: ThemeHelpers.buildDefaultBackground(),
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: Text(
          'סרטוני הרב',
          style: GoogleFonts.alef(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: ThemeHelpers.buildDefaultBackground()),
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF378ADD),
                  strokeWidth: 2.5,
                ),
              )
              : videos.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.video_library_rounded,
                      size: 48,
                      color: const Color(0xFF94A3B8),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'אין סרטונים עדיין',
                      style: GoogleFonts.alef(
                        fontSize: 17,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.only(
                  top: 100,
                  left: 16,
                  right: 16,
                  bottom: 24,
                ),
                itemCount: videos.length,
                itemBuilder: (context, index) {
                  final video = videos[index];
                  return _VideoCard(
                    title: video['כותרת'] ?? 'סרטון',
                    description: video['תיאור'] ?? '',
                    googleDriveUrl: video['קישור_גוגל_דרייב'] ?? '',
                    week: video['שבוע_של'] ?? '',
                    thumbnailUrl: video['תמונה_thumbnail'],
                  );
                },
              ),
        ],
      ),
    );
  }
}

class _VideoCard extends StatefulWidget {
  final String title;
  final String description;
  final String googleDriveUrl;
  final String week;
  final String? thumbnailUrl;

  const _VideoCard({
    required this.title,
    required this.description,
    required this.googleDriveUrl,
    required this.week,
    this.thumbnailUrl,
  });

  @override
  State<_VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<_VideoCard> {
  bool _showPlayer = false;
  late WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    // המרת קישור Google Drive לקישור embed
    final embedUrl = _convertGoogleDriveUrlToEmbed(widget.googleDriveUrl);

    _webViewController =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadRequest(Uri.parse(embedUrl));
  }

  String _convertGoogleDriveUrlToEmbed(String url) {
    // חילוץ ה-ID מקישור Google Drive
    String fileId = '';

    if (url.contains('/d/')) {
      // פורמט: https://drive.google.com/file/d/FILE_ID/view
      final parts = url.split('/d/');
      if (parts.length > 1) {
        fileId = parts[1].split('/')[0];
      }
    } else if (url.contains('id=')) {
      // פורמט: https://drive.google.com/file?id=FILE_ID
      final parts = url.split('id=');
      if (parts.length > 1) {
        fileId = parts[1].split('&')[0];
      }
    }

    // החזרת קישור embed
    return 'https://drive.google.com/file/d/$fileId/preview';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.06),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_showPlayer)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Container(
                height: 250,
                color: Colors.black,
                child: WebViewWidget(controller: _webViewController),
              ),
            )
          else
            GestureDetector(
              onTap: () => setState(() => _showPlayer = true),
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFF1D4ED8).withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  image:
                      widget.thumbnailUrl != null &&
                              widget.thumbnailUrl!.isNotEmpty
                          ? DecorationImage(
                            image: NetworkImage(widget.thumbnailUrl!),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                              Colors.black.withValues(alpha: 0.3),
                              BlendMode.darken,
                            ),
                          )
                          : null,
                ),
                child: const Center(
                  child: Icon(
                    Icons.play_circle_outline_rounded,
                    size: 60,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  widget.title,
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.alef(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                if (widget.description.isNotEmpty)
                  Text(
                    widget.description,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.alef(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                if (widget.description.isNotEmpty) const SizedBox(height: 8),
                Text(
                  'שבוע של: ${widget.week}',
                  style: GoogleFonts.alef(
                    fontSize: 12,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
