import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rabbi_shiba/widgets/platform_video_player.dart';

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

      videos.sort((a, b) {
        final aDate = a['created_at']?.toString() ?? '';
        final bDate = b['created_at']?.toString() ?? '';
        return bDate.compareTo(aDate);
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
        backgroundColor: const Color(0xFF0D1B2A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D1B2A), Color(0xFF1A2F45)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          foregroundColor: Colors.white,
          title: Text(
            'סרטוני הרב',
            style: GoogleFonts.alef(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Color(0x44FFFFFF),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            if (_selectedVideoUrl != null) _buildPlayerSection(),
            Expanded(child: _buildBody()),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
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
            child: PlatformVideoPlayer(key: ValueKey(_selectedVideoUrl), url: _selectedVideoUrl!),
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
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                color: Color(0xFF4A9EFF),
                strokeWidth: 2.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'טוען סרטונים...',
              style: GoogleFonts.alef(fontSize: 14, color: Colors.white38),
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
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 32,
                  color: Color(0xFFFFB347),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'שגיאה בטעינת הסרטונים',
                style: GoogleFonts.alef(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: _loadVideos,
                style: TextButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF4A9EFF).withValues(alpha: 0.15),
                  foregroundColor: const Color(0xFF4A9EFF),
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
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.video_library_outlined,
                size: 40,
                color: Color(0xFF4A9EFF),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'לא נמצאו סרטונים',
              style: GoogleFonts.alef(fontSize: 16, color: Colors.white38),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadVideos,
      color: const Color(0xFF4A9EFF),
      backgroundColor: const Color(0xFF1A2F45),
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
          return _buildVideoCard(video, isSelected, index);
        },
      ),
    );
  }

  Widget _buildVideoCard(
    Map<String, dynamic> video,
    bool isSelected,
    int index,
  ) {
    final url = video['url'] as String;

    final gradients = [
      [const Color(0xFF1A3A5C), const Color(0xFF0D2035)],
      [const Color(0xFF1E3A5F), const Color(0xFF0A1929)],
      [const Color(0xFF1B2F4A), const Color(0xFF0E1E30)],
      [const Color(0xFF1F3550), const Color(0xFF0C1E30)],
    ];
    final grad = gradients[index % gradients.length];

    return GestureDetector(
      onTap: () => setState(() => _selectedVideoUrl = url),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSelected
                ? [const Color(0xFF1C4A7A), const Color(0xFF0D2A48)]
                : grad,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4A9EFF).withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.06),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF4A9EFF).withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.35),
              blurRadius: isSelected ? 18 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isSelected)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF4A9EFF).withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                    radius: 0.85,
                  ),
                ),
              ),
            Positioned(
              top: 12,
              right: 12,
              child: Text(
                '${index + 1}',
                style: GoogleFonts.alef(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.2),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isSelected
                      ? [const Color(0xFF4A9EFF), const Color(0xFF1A6EDB)]
                      : [
                          Colors.white.withValues(alpha: 0.18),
                          Colors.white.withValues(alpha: 0.08),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? const Color(0xFF4A9EFF).withValues(alpha: 0.45)
                        : Colors.black.withValues(alpha: 0.3),
                    blurRadius: isSelected ? 20 : 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                isSelected ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(18),
                  ),
                  gradient: LinearGradient(
                    colors: isSelected
                        ? [
                            Colors.transparent,
                            const Color(0xFF4A9EFF).withValues(alpha: 0.8),
                            Colors.transparent,
                          ]
                        : [
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.08),
                            Colors.transparent,
                          ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
