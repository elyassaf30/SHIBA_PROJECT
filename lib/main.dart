import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:rabbi_shiba/screens/splash_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:rabbi_shiba/services/video_check_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file
  try {
    await dotenv.load(fileName: ".env");
    debugPrint('✅ .env loaded successfully.');
  } catch (e) {
    debugPrint('❌ Failed to load .env file: $e');
  }

  // Supabase Init
  try {
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];
    if (anonKey == null || anonKey.isEmpty) {
      throw Exception(
        '❌ Supabase anon key is missing or empty. Check your .env file.',
      );
    }

    await Supabase.initialize(
      url: 'https://srdwmyerieeeyrkgxsgi.supabase.co',
      anonKey: anonKey,
    );
    debugPrint('✅ Supabase initialized.');
  } catch (e) {
    debugPrint('❌ Supabase initialization error: $e');
  }

  // OneSignal Init
  try {
    final onesignalAppId = dotenv.env['ONESIGNAL_APP_ID'];
    if (onesignalAppId == null || onesignalAppId.isEmpty) {
      throw Exception('❌ OneSignal App ID is missing in .env file.');
    }

    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize(onesignalAppId);
    debugPrint('✅ OneSignal initialized with App ID: $onesignalAppId');

    final bool accepted = await OneSignal.Notifications.requestPermission(true);
    debugPrint("📢 Notification permission granted: $accepted");

    OneSignal.User.pushSubscription.addObserver((state) {
      debugPrint(
        '🔔 Push subscription state changed: ${state.current.jsonRepresentation()}',
      );
    });
  } catch (e) {
    debugPrint('❌ OneSignal initialization error: $e');
  }

  // Local Notifications (handled by OneSignal)
  // NotificationService methods are kept for compatibility
  debugPrint('✅ Notification service ready (OneSignal).');

  // Check for new videos
  try {
    await VideoCheckService.checkForNewVideos();
    debugPrint('✅ Video check completed.');
  } catch (e) {
    debugPrint('❌ Video check error: $e');
  }

  // Listen to Supabase table changes
  try {
    final channel = Supabase.instance.client
        .channel('custom-all-channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'זמני תפילות ימי חול',
          callback: (payload) async {
            debugPrint('🔄 שינוי בטבלה התקבל: ${payload.eventType}');
            debugPrint('Payload: ${payload.newRecord}');

            String message;
            switch (payload.eventType) {
              case PostgresChangeEvent.insert:
                message = "🆕 נוסף זמן תפילה חדש!";
                break;
              case PostgresChangeEvent.update:
                message = "🔄 עודכן זמן תפילה!";
                break;
              case PostgresChangeEvent.delete:
                message = "🗑️ זמן תפילה הוסר!";
                break;
              default:
                message = "📅 שינוי בזמני התפילה!";
            }

            try {
              await _sendPushNotificationViaAPI(message);
            } catch (e) {
              debugPrint('❌ שגיאה בשליחת הפוש: $e');
            }
          },
        );

    channel.subscribe();
    debugPrint('📡 Supabase change listener subscribed.');
  } catch (e) {
    debugPrint("❌ Error subscribing to table changes: $e");
  }

  // Run App
  runApp(MyApp());
}

// Function to send Push notifications via OneSignal API
Future<void> _sendPushNotificationViaAPI(String message) async {
  final onesignalAppId = dotenv.env['ONESIGNAL_APP_ID'];
  final onesignalRestApiKey = dotenv.env['ONESIGNAL_REST_API_KEY'];

  try {
    final response = await http.post(
      Uri.parse('https://onesignal.com/api/v1/notifications'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Basic $onesignalRestApiKey',
      },
      body: jsonEncode({
        'app_id': onesignalAppId,
        'included_segments': ['Subscribed Users'],
        'contents': {'en': message, 'he': message},
        'headings': {'en': 'Prayer Time Update', 'he': 'עדכון זמני תפילה'},
      }),
    );

    debugPrint('📬 API Response: ${response.statusCode} - ${response.body}');
  } catch (e) {
    debugPrint('❌ Error sending push via API: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'מרכז רפואי שיבא',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Arimo',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF3B82F6),
          brightness: Brightness.light,
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF1E293B),
        ),
      ),
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
