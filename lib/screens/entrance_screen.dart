import 'package:flutter/material.dart';
import 'package:rabbi_shiba/screens/chet_screen.dart';
import 'package:rabbi_shiba/screens/shabat_screen.dart';
import 'package:rabbi_shiba/screens/moadi_israel_screen.dart';
import 'package:rabbi_shiba/screens/general_detail_screen.dart';
import 'package:rabbi_shiba/screens/week_day_tefilot_screen.dart';
import 'package:rabbi_shiba/screens/user_to_synagogue_map.dart';
import 'package:rabbi_shiba/screens/zmanim_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'package:intl/intl.dart' as intl;
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'AdminLoginScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rabbi_shiba/utils/theme_helpers.dart';

const Map<String, String> parashaTranslations = {
  'Parashat Bereshit': 'בראשית',
  'Parashat Noach': 'נח',
  'Parashat Lech-Lecha': 'לך-לך',
  'Parashat Vayera': 'וירא',
  'Parashat Chayei Sarah': 'חיי-שרה',
  'Parashat Toldot': 'תולדות',
  'Parashat Vayetzei': 'ויצא',
  'Parashat Vayishlach': 'וישלח',
  'Parashat Vayeshev': 'וישב',
  'Parashat Miketz': 'מקץ',
  'Parashat Vayigash': 'ויגש',
  'Parashat Vayechi': 'ויחי',
  'Parashat Shemot': 'שמות',
  'Parashat Vaera': 'וָאֵרָא',
  'Parashat Bo': 'בא',
  'Parashat Beshalach': 'בשלח',
  'Parashat Yitro': 'יתרו',
  'Parashat Mishpatim': 'משפטים',
  'Parashat Terumah': 'תרומה',
  'Parashat Tetzaveh': 'תצוה',
  'Parashat Ki Tisa': 'כי-תשא',
  'Parashat Vayakhel': 'ויקהל',
  'Parashat Pekudei': 'פקודי',
  'Parashat Vayikra': 'ויקרא',
  'Parashat Tzav': 'צו',
  'Parashat Shmini': 'שמיני',
  'Parashat Tazria': 'תזריע',
  'Parashat Metzora': 'מצורע',
  'Parashat Acharei Mot': 'אחרי-מות',
  'Parashat Kedoshim': 'קדושים',
  'Parashat Emor': 'אמור',
  'Parashat Behar': 'בהר',
  'Parashat Bechukotai': 'בחקתי',
  'Parashat Bamidbar': 'במדבר',
  'Parashat Nasso': 'נשא',
  'Parashat Behaalotecha': 'בהעלותך',
  'Parashat Shlach': 'שלח',
  'Parashat Korach': 'קורח',
  'Parashat Chukat': 'חוקת',
  'Parashat Balak': 'בלק',
  'Parashat Pinchas': 'פינחס',
  'Parashat Matot': 'מטות',
  'Parashat Massei': 'מסעי',
  'Parashat Devarim': 'דברים',
  'Parashat Vaetchanan': 'ואתחנן',
  'Parashat Eikev': 'עקב',
  'Parashat Reeh': 'ראה',
  'Parashat Shoftim': 'שופטים',
  'Parashat Ki Teitzei': 'כי תצא',
  'Parashat Ki Tavo': 'כי תבוא',
  'Parashat Nitzavim': 'ניצבים',
  'Parashat Vayelech': 'וילך',
  'Parashat Haazinu': 'האזינו',
  'Parashat Vezot Haberakhah': 'וזאת הברכה',
};

// ─────────────────────────────────────────────
// 1. HebrewDateBanner
// ─────────────────────────────────────────────
class HebrewDateBanner extends StatefulWidget {
  const HebrewDateBanner({super.key});

  @override
  _HebrewDateBannerState createState() => _HebrewDateBannerState();
}

class _HebrewDateBannerState extends State<HebrewDateBanner> {
  String hebrewDate = 'טוען...';
  String parasha = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHebrewDateAndParasha();
  }

  Future<void> _fetchHebrewDateAndParasha() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final nowDate = DateTime.now();

      final formattedDate =
          '${nowDate.year}-${nowDate.month.toString().padLeft(2, '0')}-${nowDate.day.toString().padLeft(2, '0')}';

      final response = await http.get(
        Uri.parse(
          'https://www.hebcal.com/converter?cfg=json&date=$formattedDate&g2h=1',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String fetchedHebrewDate = data['hebrew'] ?? 'לא זמין';
        String fetchedParasha = '';

        final cachedHebrewDate = prefs.getString('cachedHebrewDate');

        if (cachedHebrewDate == fetchedHebrewDate) {
          final cachedParasha = prefs.getString('parasha');
          if (mounted) {
            setState(() {
              hebrewDate = fetchedHebrewDate;
              parasha = cachedParasha ?? '';
              isLoading = false;
            });
          }
          return;
        }

        if (data['events'] != null) {
          final events = List<String>.from(data['events']);
          final englishParasha = events.firstWhere(
            (event) => event.startsWith('Parashat'),
            orElse: () => '',
          );

          if (englishParasha.isNotEmpty) {
            fetchedParasha =
                parashaTranslations[englishParasha] ?? englishParasha;
          }
        }

        await prefs.setString('hebrewDate', fetchedHebrewDate);
        await prefs.setString('parasha', fetchedParasha);
        await prefs.setString('cachedHebrewDate', fetchedHebrewDate);

        if (mounted) {
          setState(() {
            hebrewDate = fetchedHebrewDate;
            parasha = fetchedParasha;
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            hebrewDate = 'שגיאה בטעינה';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          hebrewDate = 'שגיאה בטעינה';
          isLoading = false;
        });
      }
      debugPrint('שגיאה ב-fetchHebrewDateAndParasha: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _InfoRow(
        icon: Icons.calendar_today_outlined,
        iconColor: const Color(0xFF378ADD),
        child: Row(
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF378ADD),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'טוען תאריך עברי...',
              style: GoogleFonts.alef(
                fontSize: 13,
                color: const Color(0xFF378ADD),
              ),
            ),
          ],
        ),
      );
    }

    return _InfoRow(
      icon: Icons.calendar_today_outlined,
      iconColor: const Color(0xFF378ADD),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          if (parasha.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F1FB),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'פרשת $parasha',
                textDirection: TextDirection.rtl,
                style: GoogleFonts.alef(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF0C447C),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              hebrewDate,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.alef(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF0F172A),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 2. NextZmanBanner
// ─────────────────────────────────────────────
class NextZmanBanner extends StatefulWidget {
  const NextZmanBanner({super.key});

  @override
  _NextZmanBannerState createState() => _NextZmanBannerState();
}

class _NextZmanBannerState extends State<NextZmanBanner> {
  String _nextZman = 'טוען...';
  String _nextZmanLabel = '';
  bool _isLoading = true;
  Timer? _zmanCheckTimer;

  @override
  void initState() {
    super.initState();
    _startZmanCheck();
  }

  @override
  void dispose() {
    _zmanCheckTimer?.cancel();
    super.dispose();
  }

  void _startZmanCheck() {
    _fetchNextZman();
    _zmanCheckTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _fetchNextZman();
    });
  }

  void _fetchNextZman() async {
    try {
      final now = DateTime.now();
      final currentMinutes = now.hour * 60 + now.minute;

      final geoLocation = GeoLocation.setLocation(
        'ירושלים',
        31.7683,
        35.2137,
        now,
      );

      final zmanimCalendar = ComplexZmanimCalendar.intGeoLocation(geoLocation);
      final dateFormat = intl.DateFormat('HH:mm');

      final sunrise = zmanimCalendar.getSunrise();
      final sunset = zmanimCalendar.getSunset();

      Map<String, dynamic>? nextZman;

      if (sunrise != null) {
        final sunriseMinutes = sunrise.hour * 60 + sunrise.minute;
        if (sunriseMinutes > currentMinutes) {
          nextZman = {
            'time': dateFormat.format(sunrise),
            'label': 'נץ החמה',
            'minutes': sunriseMinutes,
          };
        }
      }

      if (sunset != null) {
        final sunsetMinutes = sunset.hour * 60 + sunset.minute;
        if (sunsetMinutes > currentMinutes) {
          if (nextZman == null ||
              sunsetMinutes < (nextZman['minutes'] as int)) {
            nextZman = {
              'time': dateFormat.format(sunset),
              'label': 'שקיעה',
              'minutes': sunsetMinutes,
            };
          }
        }
      }

      if (mounted) {
        setState(() {
          if (nextZman != null) {
            _nextZman = nextZman['time'] as String;
            _nextZmanLabel = nextZman['label'] as String;
          } else {
            _nextZman = 'לא זמין';
            _nextZmanLabel = '';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _nextZman = 'שגיאה';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _nextZman == 'לא זמין' || _nextZman == 'שגיאה') {
      return const SizedBox.shrink();
    }

    return _InfoRow(
      icon: Icons.wb_sunny_outlined,
      iconColor: const Color(0xFFEF9F27),
      child: Text(
        '$_nextZmanLabel בשעה $_nextZman',
        textDirection: TextDirection.rtl,
        style: GoogleFonts.alef(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF0F172A),
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 3. NextPrayerBanner
// ─────────────────────────────────────────────
class NextPrayerBanner extends StatefulWidget {
  const NextPrayerBanner({super.key});

  @override
  _NextPrayerBannerState createState() => _NextPrayerBannerState();
}

class _NextPrayerBannerState extends State<NextPrayerBanner> {
  Map<String, dynamic>? _nextPrayerTime;
  Timer? _prayerCheckTimer;

  @override
  void initState() {
    super.initState();
    _startPrayerTimeCheck();
  }

  @override
  void dispose() {
    _prayerCheckTimer?.cancel();
    super.dispose();
  }

  void _startPrayerTimeCheck() {
    _fetchAndDetermineNextPrayer();
    _prayerCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _fetchAndDetermineNextPrayer();
    });
  }

  void _fetchAndDetermineNextPrayer() async {
    try {
      final now = DateTime.now();
      final currentMinutes = now.hour * 60 + now.minute;

      final response = await Supabase.instance.client
          .from('זמני תפילות ימי חול')
          .select('שעה, "סוג תפילה"');

      final data = List<Map<String, dynamic>>.from(response);
      Map<String, dynamic>? nextPrayer;

      data.sort((a, b) => a['שעה'].compareTo(b['שעה']));

      for (var item in data) {
        final timeString = item['שעה'];
        final parts = timeString.split(':');
        if (parts.length < 2) continue;

        final prayerHour = int.tryParse(parts[0]) ?? 0;
        final prayerMinute = int.tryParse(parts[1]) ?? 0;
        final prayerMinutes = prayerHour * 60 + prayerMinute;

        if (prayerMinutes > currentMinutes) {
          nextPrayer = item;
          break;
        }
      }

      if (nextPrayer == null && data.isNotEmpty) {
        nextPrayer = data.first;
      }

      if (mounted) {
        setState(() {
          _nextPrayerTime = nextPrayer;
        });
      }
    } catch (e) {
      // מטפל בשגיאה בשקט
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_nextPrayerTime == null) return const SizedBox.shrink();

    final time = _nextPrayerTime!['שעה'] as String;
    final type = _nextPrayerTime!['סוג תפילה'];
    final displayTime = time.length >= 5 ? time.substring(0, 5) : time;

    return _InfoRow(
      icon: Icons.schedule_outlined,
      iconColor: const Color(0xFF1D9E75),
      child: Text.rich(
        TextSpan(
          style: GoogleFonts.alef(fontSize: 14, color: const Color(0xFF0F172A)),
          children: [
            const TextSpan(text: 'תפילה הבאה: '),
            TextSpan(
              text: '$type',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: ' — $displayTime'),
          ],
        ),
        textDirection: TextDirection.rtl,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Helper: _InfoRow — שורת מידע אחידה
// ─────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.07),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: iconColor),
          const SizedBox(width: 9),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 4. EntranceScreen
// ─────────────────────────────────────────────
class EntranceScreen extends StatefulWidget {
  const EntranceScreen({super.key});

  @override
  _EntranceScreenState createState() => _EntranceScreenState();
}

class _EntranceScreenState extends State<EntranceScreen>
    with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  String rabbiQuote = 'טוען ציטוט...';
  bool isLoading = true;
  int _adminTapCount = 0;

  late AnimationController _mainController;
  late AnimationController _quoteController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _quoteOpacityAnimation;

  static final List<Map<String, dynamic>> _bubbles = [
    {
      'label': 'זמני היום',
      'icon': Icons.sunny,
      'color': Colors.amber,
      'screenBuilder': () => ZmanimScreen(),
    },
    {
      'label': 'שבת',
      'icon': Icons.wine_bar,
      'color': Colors.indigo,
      'screenBuilder': () => ShabatScreen(),
    },
    {
      'label': 'כשרות',
      'icon': Icons.food_bank,
      'color': Colors.green,
      'screenBuilder': () => GeneralDetailScreen(type: 'כשרות'),
    },
    {
      'label': 'בתי כנסת במרכז הרפואי',
      'icon': Icons.location_on,
      'color': Colors.orange,
      'screenBuilder': () => UserToSynagogueMap(),
    },
    {
      'label': 'זמני תפילות ימי חול',
      'icon': Icons.access_time,
      'color': Colors.blue,
      'screenBuilder': () => WeekdayTefilotScreen(),
    },
    {
      'label': 'טומאת כהנים',
      'icon': Icons.people,
      'color': Colors.brown,
      'screenBuilder': () => GeneralDetailScreen(type: 'טומאת כהנים'),
    },
    {
      'label': 'נפטרים',
      'icon': Icons.help_outline,
      'color': Colors.grey,
      'screenBuilder': () => GeneralDetailScreen(type: 'נפטרים'),
    },
    {
      'label': 'מקווה',
      'icon': Icons.water,
      'color': Colors.blueAccent,
      'screenBuilder': () => GeneralDetailScreen(type: 'מקווה'),
    },
    {
      'label': 'מועדי ישראל',
      'icon': Icons.calendar_today,
      'color': Colors.purple,
      'screenBuilder': () => MoadiIsraelScreen(),
    },
    {
      'label': 'ייעוץ הלכתי רפואי',
      'icon': Icons.medical_services,
      'color': Colors.teal,
      'screenBuilder': () => ChatScreen(),
    },
    {
      'label': 'אנשי קשר',
      'icon': Icons.contacts,
      'color': Colors.redAccent,
      'screenBuilder': () => GeneralDetailScreen(type: 'אנשי קשר'),
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _fetchRabbiData();
  }

  void _initializeAnimations() {
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _quoteController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _quoteOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _quoteController, curve: Curves.easeIn));
  }

  Future<void> _fetchRabbiData() async {
    try {
      final response =
          await supabase
              .from('כללי')
              .select('מידע')
              .eq('סוג', 'דבר הרב')
              .limit(1)
              .maybeSingle();

      if (!mounted) return;

      setState(() {
        rabbiQuote =
            (response == null || response['מידע'] == null)
                ? 'ברוכים הבאים לאפליקציית כשרות דת והלכה של מרכז רפואי שיבא. כאן תמצאו את כל המידע הדרוש לכם לשמירה על הלכות הכשרות והדת במרכז הרפואי.'
                : response['מידע']?.toString() ??
                    'ברוכים הבאים לאפליקציית כשרות דת והלכה של מרכז רפואי שיבא.';
        isLoading = false;
      });

      _mainController.forward();
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _quoteController.forward();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        rabbiQuote =
            'ברוכים הבאים לאפליקציית כשרות דת והלכה של מרכז רפואי שיבא. כאן תמצאו את כל המידע הדרוש לכם לשמירה על הלכות הכשרות והדת במרכז הרפואי.';
        isLoading = false;
      });
      _mainController.forward();
      _quoteController.forward();
      debugPrint('Error fetching rabbi data: $e');
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _quoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final safeAreaHeight =
        MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      drawer: _buildDrawer(),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        flexibleSpace: ThemeHelpers.buildDefaultBackground(),
        iconTheme: IconThemeData(
          color: const Color.fromARGB(255, 13, 13, 14).withValues(alpha: 0.9),
        ),
        title: Text(
          'כשרות דת והלכה',
          style: GoogleFonts.alef(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color.fromARGB(
              255,
              14,
              15,
              17,
            ).withValues(alpha: 0.92),
          ),
          textDirection: TextDirection.rtl,
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(child: ThemeHelpers.buildDefaultBackground()),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.05,
                vertical: safeAreaHeight * 0.02,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildQuickInfoPanel(),
                  SizedBox(height: safeAreaHeight * 0.018),
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _quoteController,
                      builder:
                          (context, child) => FadeTransition(
                            opacity: _quoteOpacityAnimation,
                            child:
                                isLoading
                                    ? _buildLoadingWidget()
                                    : _buildWelcomeCard(),
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfoPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color.fromARGB(
            255,
            255,
            255,
            255,
          ).withValues(alpha: 0.35),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // כותרת
          Padding(
            padding: const EdgeInsets.only(bottom: 8, right: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'מידע מהיר',
                  style: GoogleFonts.alef(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.dashboard_customize_outlined,
                  size: 15,
                  color: Color(0xFF378ADD),
                ),
              ],
            ),
          ),
          const HebrewDateBanner(),
          const SizedBox(height: 6),
          const NextZmanBanner(),
          const SizedBox(height: 6),
          const NextPrayerBanner(),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    _adminTapCount++;
                    if (_adminTapCount >= 5) {
                      _adminTapCount = 0;
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AdminLoginScreen()),
                      );
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 560),
                    padding: EdgeInsets.all(
                      MediaQuery.of(context).size.width * 0.05,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 0.8,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // כותרת
                        Text(
                          'ברוכים הבאים',
                          style: GoogleFonts.alef(
                            fontSize: MediaQuery.of(context).size.width * 0.075,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'מחלקת כשרות דת והלכה',
                          style: GoogleFonts.alef(
                            fontSize: MediaQuery.of(context).size.width * 0.042,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF64748B),
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),

                        // קו
                        Container(
                          height: 2,
                          width: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: const Color(0xFF378ADD),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // תמונת הרב
                        Container(
                          width: MediaQuery.of(context).size.width * 0.18,
                          height: MediaQuery.of(context).size.width * 0.18,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              MediaQuery.of(context).size.width * 0.09,
                            ),
                            border: Border.all(
                              color: const Color(0xFFB5D4F4),
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              MediaQuery.of(context).size.width * 0.09,
                            ),
                            child: Image.asset(
                              'assets/hrav.png',
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ציטוט
                        Icon(
                          Icons.format_quote,
                          size: 22,
                          color: const Color(0xFF378ADD).withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.black.withValues(alpha: 0.06),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            rabbiQuote,
                            style: GoogleFonts.alef(
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.042,
                              height: 1.75,
                              color: const Color(0xFF334155),
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // שם הרב
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F1FB),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'הרב יואב חנניה אוקנין',
                            style: GoogleFonts.alef(
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.038,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF0C447C),
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              color: Color(0xFF378ADD),
              strokeWidth: 2.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '...טוען',
            style: GoogleFonts.alef(
              fontSize: 15,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: const Color(0xFFF8FAFC),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF1D4ED8)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.menu_book,
                      size: 26,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'תפריט ראשי',
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.alef(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            ..._bubbles.map((bubble) {
              return Directionality(
                textDirection: TextDirection.rtl,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 2,
                  ),
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: (bubble['color'] as Color).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      bubble['icon'],
                      color: bubble['color'],
                      size: 20,
                    ),
                  ),
                  title: Text(
                    bubble['label'],
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.alef(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder:
                            (_, animation, __) => bubble['screenBuilder'](),
                        transitionsBuilder:
                            (_, animation, __, child) => FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                        transitionDuration: const Duration(milliseconds: 300),
                      ),
                    );
                  },
                ),
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
