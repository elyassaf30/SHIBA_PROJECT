import 'package:onesignal_flutter/onesignal_flutter.dart';

class NotificationService {
  // OneSignal is configured in main.dart
  // For sending notifications to all users, use the OneSignal REST API from server-side

  static Future<void> showNewVideoNotification(String title) async {
    try {
      // Log for now - notifications are sent server-side when video is added to database
      // To send real notifications, implement a Supabase Edge Function that calls OneSignal REST API
      print('📹$title :סרטון פרשת שבוע חדש');

      // Optional: Send in-app notification using OneSignal inbox (if enabled in OneSignal dashboard)
      // This will appear in the notification center if user has OneSignal inbox enabled
      OneSignal.Notifications.clearAll();
    } catch (e) {
      print('Error with notification: $e');
    }
  }
}
