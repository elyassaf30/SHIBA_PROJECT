import 'package:flutter/material.dart';
import 'package:rabbi_shiba/screens/announcements_screen.dart';
import 'package:rabbi_shiba/services/announcement_service.dart';

/// Bell icon with a red badge when there are unread announcements.
/// Drop this into any AppBar actions list.
class AnnouncementBellIcon extends StatefulWidget {
  const AnnouncementBellIcon({super.key});

  @override
  State<AnnouncementBellIcon> createState() => _AnnouncementBellIconState();
}

class _AnnouncementBellIconState extends State<AnnouncementBellIcon> {
  bool _hasUnread = false;

  void _handleRefreshTick() {
    _checkUnread();
  }

  @override
  void initState() {
    super.initState();
    AnnouncementService.refreshTick.addListener(_handleRefreshTick);
    _checkUnread();
  }

  @override
  void dispose() {
    AnnouncementService.refreshTick.removeListener(_handleRefreshTick);
    super.dispose();
  }

  Future<void> _checkUnread() async {
    try {
      final unread = await AnnouncementService.hasUnread();
      if (mounted) setState(() => _hasUnread = unread);
    } catch (_) {
      // Silently ignore — badge is a best-effort UX hint
    }
  }

  Future<void> _openAnnouncements() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AnnouncementsScreen()),
    );
    // Recheck after returning so the badge is refreshed
    _checkUnread();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: GestureDetector(
        onTap: _openAnnouncements,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(
                Icons.notifications_outlined,
                size: 26,
                color: Color(0xFF0C2D5E),
              ),
            ),
            // Red dot badge — only shown when there are unread items
            if (_hasUnread)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD62B2B),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
