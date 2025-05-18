import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:rabbi_shiba/screens/home_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file
  try {
    await dotenv.load(fileName: ".env");
    print('✅ .env loaded successfully.');
  } catch (e) {
    print('❌ Failed to load .env file: $e');
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
    print('✅ Supabase initialized.');
  } catch (e) {
    print('❌ Supabase initialization error: $e');
  }

  // OneSignal Init
  try {
    final onesignalAppId = dotenv.env['ONESIGNAL_APP_ID'];
    if (onesignalAppId == null || onesignalAppId.isEmpty) {
      throw Exception('❌ OneSignal App ID is missing in .env file.');
    }

    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize(onesignalAppId);
    print('✅ OneSignal initialized with App ID: $onesignalAppId');

    final bool accepted = await OneSignal.Notifications.requestPermission(true);
    print("📢 Notification permission granted: $accepted");

    OneSignal.User.pushSubscription.addObserver((state) {
      print(
        '🔔 Push subscription state changed: ${state.current.jsonRepresentation()}',
      );
    });
  } catch (e) {
    print('❌ OneSignal initialization error: $e');
  }

  // Listen to Supabase table changes
  // Listen to Supabase table changes
  try {
    final channel = Supabase.instance.client
        .channel('custom-all-channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'זמני תפילות ימי חול',
          callback: (payload) async {
            print('🔄 שינוי בטבלה התקבל: ${payload.eventType}');
            print(
              'Payload: ${payload.newRecord}',
            ); // או payload.oldRecord בהתאם
            // הוספת קוד לשליחת הפוש

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
              print('❌ שגיאה בשליחת הפוש: $e');
            }
          },
        );

    await channel.subscribe();
    print('📡 Supabase change listener subscribed.');
  } catch (e) {
    print("❌ Error subscribing to table changes: $e");
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

    print('📬 API Response: ${response.statusCode} - ${response.body}');
  } catch (e) {
    print('❌ Error sending push via API: $e');
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'מרכז רפואי שיבא',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Arimo'),
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();

    // מתחילים אנימציית פייד-אין
    Future.delayed(Duration(milliseconds: 100), () {
      setState(() {
        _opacity = 1.0;
      });
    });

    // מעבר אוטומטי אחרי 3 שניות
    Future.delayed(Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: Duration(milliseconds: 800),
          pageBuilder: (_, __, ___) => HomeScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    });

    final status = OneSignal.Notifications.permission;
    print('🔔 סטטוס הרשאות התחלתי: $status');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedOpacity(
          duration: Duration(seconds: 2),
          opacity: _opacity,
          child: Image.asset('assets/siba5.png', width: 250, height: 250),
        ),
      ),
    );
  }
}
