import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:rabbi_shiba/screens/entrance_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';

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
  try {
    final channel = Supabase.instance.client
        .channel('custom-all-channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'זמני תפילות ימי חול',
          callback: (payload) async {
            print('🔄 שינוי בטבלה התקבל: ${payload.eventType}');
            print('Payload: ${payload.newRecord}');

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

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _progressController;

  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<double> _textSlideAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();

    final status = OneSignal.Notifications.permission;
    print('🔔 סטטוס הרשאות התחלתי: $status');
  }

  void _initializeAnimations() {
    // Logo Animation Controller
    _logoController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    );

    // Text Animation Controller
    _textController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    // Progress Animation Controller
    _progressController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2000),
    );

    // Logo Animations
    _logoScaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // Text Animations
    _textOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));

    _textSlideAnimation = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    // Progress Animation
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
  }

  void _startAnimationSequence() async {
    // Start logo animation immediately
    _logoController.forward();

    // Start text animation after a delay
    Future.delayed(Duration(milliseconds: 600), () {
      if (mounted) {
        _textController.forward();
      }
    });

    // Start progress animation
    Future.delayed(Duration(milliseconds: 800), () {
      if (mounted) {
        _progressController.forward();
      }
    });

    // Navigate to entrance screen
    Future.delayed(Duration(milliseconds: 3500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: Duration(milliseconds: 1000),
            pageBuilder: (_, __, ___) => EntranceScreen(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(0.0, 0.1),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOut),
                  ),
                  child: child,
                ),
              );
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
            stops: [0.0, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Spacer(flex: 2),

                // Logo Section
                AnimatedBuilder(
                  animation: Listenable.merge([_logoController]),
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _logoScaleAnimation.value,
                      child: Opacity(
                        opacity: _logoOpacityAnimation.value,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 30,
                                offset: Offset(0, 15),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: Image.asset(
                              'assets/siba5.png',
                              width: 200,
                              height: 200,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                SizedBox(height: 40),

                // Text Section
                AnimatedBuilder(
                  animation: Listenable.merge([_textController]),
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _textSlideAnimation.value),
                      child: Opacity(
                        opacity: _textOpacityAnimation.value,
                        child: Column(
                          children: [
                            Text(
                              'מרכז רפואי שיבא',
                              style: GoogleFonts.alef(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                                height: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'מחלקת כשרות דת והלכה',
                              style: GoogleFonts.alef(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF475569),
                                height: 1.3,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                Spacer(flex: 2),

                // Progress Section
                AnimatedBuilder(
                  animation: _progressController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _progressAnimation.value,
                      child: Column(
                        children: [
                          Container(
                            width: 200,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerRight,
                              widthFactor: _progressAnimation.value,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF3B82F6),
                                      Color(0xFF1D4ED8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            '...טוען',
                            style: GoogleFonts.alef(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
