import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rabbi_shiba/services/notification_service.dart';

class VideoCheckService {
  static Future<void> checkForNewVideos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheck = prefs.getInt('lastVideoCheck') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      // בדוק רק פעם ביום (86400000 אלפיות שניה = 24 שעות)
      if (now - lastCheck > 86400000) {
        final response = await Supabase.instance.client
            .from('סרטוני_רב')
            .select()
            .order('תאריך_הוספה', ascending: false)
            .limit(1);

        if (response.isNotEmpty) {
          final latestVideo = response[0];
          final lastSeenId = prefs.getString('lastSeenVideoId') ?? '';

          // אם יש סרטון חדש שלא ראינו
          if (latestVideo['id'] != lastSeenId && latestVideo['פעיל'] == true) {
            await NotificationService.showNewVideoNotification(
              latestVideo['כותרת'] ?? 'סרטון חדש',
            );
            await prefs.setString('lastSeenVideoId', latestVideo['id']);
          }
        }

        // שמור את הזמן של ההחזקה
        await prefs.setInt('lastVideoCheck', now);
      }
    } catch (e) {
      debugPrint('שגיאה בבדיקת סרטונים חדשים: $e');
    }
  }
}
