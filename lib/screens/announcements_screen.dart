import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import 'package:rabbi_shiba/services/announcement_service.dart';
import 'package:rabbi_shiba/utils/theme_helpers.dart';

// Colors consistent with the rest of the app
class _C {
  static const navy = Color(0xFF0C2D5E);
  static const blue = Color(0xFF1A5FB4);
  static const lightBlue = Color(0xFFD6E8F9);
  static const surface = Color(0xFFF8FAFF);
  static const textPrimary = Color(0xFF0D1B33);
  static const textSecondary = Color(0xFF4A5568);
  static const textMuted = Color(0xFF94A3B8);
  static const divider = Color(0xFFE2EAF4);
}

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  List<Map<String, dynamic>> _announcements = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await AnnouncementService.fetchAll();
      // Mark as read so the bell badge disappears after opening this screen
      await AnnouncementService.markAllRead();

      if (mounted) {
        setState(() {
          _announcements = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'שגיאה בטעינת העדכונים: $e';
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return intl.DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'עדכונים והודעות',
          style: GoogleFonts.alef(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: _C.navy,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        iconTheme: IconThemeData(color: _C.navy.withValues(alpha: 0.85)),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: ThemeHelpers.buildDefaultBackground()),
          SafeArea(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _C.blue),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: _C.textMuted),
              const SizedBox(height: 14),
              Text(
                _error!,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.alef(color: _C.textSecondary, fontSize: 15),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: Text('נסה שוב', style: GoogleFonts.alef()),
              ),
            ],
          ),
        ),
      );
    }

    if (_announcements.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none_rounded, size: 56, color: _C.textMuted.withValues(alpha: 0.6)),
            const SizedBox(height: 14),
            Text(
              'אין עדכונים כרגע',
              style: GoogleFonts.alef(fontSize: 16, color: _C.textMuted),
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: _C.blue,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _announcements.length,
        itemBuilder: (context, index) {
          final item = _announcements[index];
          return _AnnouncementCard(
            title: item['title'] as String,
            content: item['content'] as String,
            date: _formatDate(item['created_at'] as String),
            isFirst: index == 0,
          );
        },
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final String title;
  final String content;
  final String date;
  final bool isFirst;

  const _AnnouncementCard({
    required this.title,
    required this.content,
    required this.date,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isFirst
                ? _C.blue.withValues(alpha: 0.35)
                : _C.divider,
            width: isFirst ? 1.2 : 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: _C.navy.withValues(alpha: 0.07),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: title + optional "חדש" badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.alef(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _C.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isFirst) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _C.blue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _C.blue.withValues(alpha: 0.3), width: 0.8),
                      ),
                      child: Text(
                        'חדש',
                        style: GoogleFonts.alef(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _C.blue,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              // Content
              Text(
                content,
                style: GoogleFonts.alef(
                  fontSize: 14,
                  height: 1.6,
                  color: _C.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              // Date chip
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.schedule_outlined, size: 12, color: _C.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    date,
                    style: GoogleFonts.alef(fontSize: 11, color: _C.textMuted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
