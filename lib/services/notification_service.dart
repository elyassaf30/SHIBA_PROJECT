import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter/foundation.dart';

bool get _isOneSignalSupportedPlatform {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

class NotificationService {
  // OneSignal is configured in main.dart
  // For sending notifications to all users, use the OneSignal REST API from server-side

  static Future<void> showNewVideoNotification(String title) async {
    try {
      // Log for now - notifications are sent server-side when video is added to database
      // To send real notifications, implement a Supabase Edge Function that calls OneSignal REST API
      debugPrint('📹$title :סרטון פרשת שבוע חדש');

      // Optional: Send in-app notification using OneSignal inbox (if enabled in OneSignal dashboard)
      // This will appear in the notification center if user has OneSignal inbox enabled
      if (_isOneSignalSupportedPlatform) {
        await OneSignal.Notifications.clearAll();
      }
    } catch (e) {
      debugPrint('Error with notification: $e');
    }
  }
}
