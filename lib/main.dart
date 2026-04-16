import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:rabbi_shiba/screens/splash_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:rabbi_shiba/services/video_check_service.dart';
import 'package:flutter/foundation.dart';

const _supabaseUrl = 'https://srdwmyerieeeyrkgxsgi.supabase.co';
// Supabase anon key is public by design. Keep server secrets out of the client.
const _supabaseAnonKeyFallback =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNyZHdteWVyaWVlZXlya2d4c2dpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDUzMTAwNzgsImV4cCI6MjA2MDg4NjA3OH0.m8FyC9TeyNzeYbjDcULl6Gzh11d2H96wdSt0D6XTgyE';

bool get _isOneSignalSupportedPlatform {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

String _readConfigValue(String key) {
  String definedValue = '';
  switch (key) {
    case 'SUPABASE_ANON_KEY':
      definedValue = const String.fromEnvironment('SUPABASE_ANON_KEY');
      break;
    case 'ONESIGNAL_APP_ID':
      definedValue = const String.fromEnvironment('ONESIGNAL_APP_ID');
      break;
    case 'ONESIGNAL_REST_API_KEY':
      definedValue = const String.fromEnvironment('ONESIGNAL_REST_API_KEY');
      break;
  }

  if (definedValue.isNotEmpty) return definedValue;

  try {
    final dotenvValue = dotenv.env[key];
    if (dotenvValue != null && dotenvValue.isNotEmpty) return dotenvValue;
  } catch (_) {
    // dotenv isn't initialized on web unless it is explicitly loaded.
  }

  return '';
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var supabaseInitialized = false;

  // Load .env file only on mobile/desktop. Web should use dart-define values.
  if (!kIsWeb) {
    try {
      await dotenv.load(fileName: ".env");
      debugPrint('✅ .env loaded successfully.');
    } catch (e) {
      debugPrint('❌ Failed to load .env file: $e');
    }
  } else {
    debugPrint('ℹ️ Skipping .env asset load on web.');
  }

  // Supabase Init
  try {
    final anonKey = _readConfigValue('SUPABASE_ANON_KEY');
    final effectiveAnonKey =
        anonKey.isNotEmpty ? anonKey : _supabaseAnonKeyFallback;

    if (effectiveAnonKey.isEmpty) {
      throw Exception(
        '❌ Supabase anon key is missing or empty. Provide it via .env or dart-define.',
      );
    }

    if (anonKey.isEmpty) {
      debugPrint('⚠️ SUPABASE_ANON_KEY not provided, using fallback key.');
    }

    await Supabase.initialize(url: _supabaseUrl, anonKey: effectiveAnonKey);
    supabaseInitialized = true;
    debugPrint('✅ Supabase initialized.');
  } catch (e) {
    debugPrint('❌ Supabase initialization error: $e');
  }

  if (!supabaseInitialized) {
    runApp(
      const _StartupErrorApp(
        message:
            'האפליקציה לא הצליחה להתחבר לשרת כרגע. נסו לרענן את הדף או לנסות שוב בעוד כמה דקות.',
      ),
    );
    return;
  }

  // OneSignal Init (mobile only)
  if (_isOneSignalSupportedPlatform) {
    try {
      final onesignalAppId = _readConfigValue('ONESIGNAL_APP_ID');
      if (onesignalAppId.isEmpty) {
        throw Exception('❌ OneSignal App ID is missing in .env file.');
      }

      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      OneSignal.initialize(onesignalAppId);
      debugPrint('✅ OneSignal initialized with App ID: $onesignalAppId');

      final bool accepted = await OneSignal.Notifications.requestPermission(
        true,
      );
      debugPrint("📢 Notification permission granted: $accepted");

      OneSignal.User.pushSubscription.addObserver((state) {
        debugPrint(
          '🔔 Push subscription state changed: ${state.current.jsonRepresentation()}',
        );
      });
    } catch (e) {
      debugPrint('❌ OneSignal initialization error: $e');
    }
  } else {
    debugPrint('ℹ️ OneSignal skipped: unsupported platform (web/desktop).');
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

  // Listen to table changes only on non-web clients.
  // Push delivery should be done from a trusted backend function.
  if (!kIsWeb) {
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
  } else {
    debugPrint('ℹ️ Skipping client-side push sender on web.');
  }

  // Run App
  runApp(MyApp());
}

// Function to send Push notifications via OneSignal API
Future<void> _sendPushNotificationViaAPI(String message) async {
  final onesignalAppId = _readConfigValue('ONESIGNAL_APP_ID');
  final onesignalRestApiKey = _readConfigValue('ONESIGNAL_REST_API_KEY');

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

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 58),
                const SizedBox(height: 14),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontSize: 17),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
