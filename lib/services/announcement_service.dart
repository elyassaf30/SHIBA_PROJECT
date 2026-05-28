import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Shared-prefs key that stores the ID of the last announcement the user opened
const _kLastReadKey = 'last_read_announcement_id';

class AnnouncementService {
  static final _client = Supabase.instance.client;

  // Fetch all announcements, newest first
  static Future<List<Map<String, dynamic>>> fetchAll() async {
    final response = await _client
        .from('announcements')
        .select('id, title, content, created_at')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response as List);
  }

  // Returns the ID of the latest announcement (null if table is empty)
  static Future<int?> fetchLatestId() async {
    final response =
        await _client
            .from('announcements')
            .select('id')
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
    if (response == null) return null;
    return response['id'] as int?;
  }

  // Returns true when the latest Supabase ID is newer than what the user last read
  static Future<bool> hasUnread() async {
    try {
      final latestId = await fetchLatestId();
      if (latestId == null) return false;

      final prefs = await SharedPreferences.getInstance();
      final lastRead = prefs.getInt(_kLastReadKey) ?? 0;
      return latestId > lastRead;
    } catch (e) {
      debugPrint('AnnouncementService.hasUnread error: $e');
      return false;
    }
  }

  // Call this when the user opens the AnnouncementsScreen to clear the badge
  static Future<void> markAllRead() async {
    try {
      final latestId = await fetchLatestId();
      if (latestId == null) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kLastReadKey, latestId);
    } catch (e) {
      debugPrint('AnnouncementService.markAllRead error: $e');
    }
  }

  // Insert a new announcement and trigger the Edge Function to broadcast via FCM
  static Future<void> sendAnnouncement({
    required String title,
    required String content,
    required String supabaseAccessToken,
  }) async {
    // 1. Persist to the database
    await _client.from('announcements').insert({
      'title': title,
      'content': content,
    });

    // 2. Call the Edge Function — it broadcasts the announcement to push subscribers
    final response = await _client.functions.invoke(
      'send-announcement',
      body: {'title': title, 'body': content},
      headers: {'Authorization': 'Bearer $supabaseAccessToken'},
    );

    if (response.status != 200) {
      throw Exception(
        'Edge Function error ${response.status}: ${response.data}',
      );
    }
  }

  // Permanently delete an announcement by its ID
  static Future<void> deleteAnnouncement(int id) async {
    await _client.from('announcements').delete().eq('id', id);
  }
}
