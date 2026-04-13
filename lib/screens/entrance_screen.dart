import 'package:flutter/material.dart';
import 'package:rabbi_shiba/screens/chet_screen.dart';
import 'package:rabbi_shiba/screens/shabat_screen.dart';
import 'package:rabbi_shiba/screens/moadi_israel_screen.dart';
import 'package:rabbi_shiba/screens/general_detail_screen.dart';
import 'package:rabbi_shiba/screens/week_day_tefilot_screen.dart';
import 'package:rabbi_shiba/screens/user_to_synagogue_map.dart';
import 'package:rabbi_shiba/screens/zmanim_screen.dart';
import 'package:rabbi_shiba/screens/torah_weekly_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'package:intl/intl.dart' as intl;
import 'dart:async';
import 'AdminLoginScreen.dart';
import 'package:rabbi_shiba/utils/theme_helpers.dart';
import 'package:webview_flutter/webview_flutter.dart';

// ─────────────────────────────────────────────
// Design Tokens
// ─────────────────────────────────────────────
class _AppColors {
  static const navy = Color(0xFF0C2D5E);
  static const blue = Color(0xFF1A5FB4);
  static const skyBlue = Color(0xFF4A90D9);
  static const lightBlue = Color(0xFFD6E8F9);
  static const gold = Color(0xFFB8960C);
  static const goldLight = Color(0xFFFDF3D0);
  static const surface = Color(0xFFF8FAFF);
  static const cardBg = Colors.white;
  static const textPrimary = Color(0xFF0D1B33);
  static const textSecondary = Color(0xFF4A5568);
  static const textMuted = Color(0xFF94A3B8);
  static const divider = Color(0xFFE2EAF4);
  static const teal = Color(0xFF0D7C60);
  static const tealLight = Color(0xFFD4F0E8);
  static const amber = Color(0xFFB45309);
  static const amberLight = Color(0xFFFEF3C7);
}

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
      final formatter =
          HebrewDateFormatter()
            ..hebrewFormat = true
            ..useGershGershayim = true;

      final jewishDate = JewishDate();
      final jewishCalendar = JewishCalendar()..inIsrael = true;

      final fetchedHebrewDate = formatter.format(jewishDate);
      var fetchedParasha = formatter.formatWeeklyParsha(jewishCalendar);

      // The chip already adds "פרשת" prefix in UI.
      if (fetchedParasha.startsWith('פרשת ')) {
        fetchedParasha = fetchedParasha.replaceFirst('פרשת ', '');
      }

      if (!mounted) return;
      setState(() {
        hebrewDate = fetchedHebrewDate;
        parasha = fetchedParasha;
        isLoading = false;
      });
    } catch (e) {
      if (mounted)
        setState(() {
          hebrewDate = 'שגיאה בטעינה';
          isLoading = false;
        });
      debugPrint('שגיאה ב-fetchHebrewDateAndParasha: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _InfoChip(
        icon: Icons.calendar_today_outlined,
        iconColor: _AppColors.blue,
        bgColor: _AppColors.lightBlue,
        child: Row(
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: _AppColors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'טוען תאריך עברי...',
              style: GoogleFonts.alef(fontSize: 13, color: _AppColors.blue),
            ),
          ],
        ),
      );
    }

    return _InfoChip(
      icon: Icons.calendar_today_outlined,
      iconColor: _AppColors.blue,
      bgColor: _AppColors.lightBlue,
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          if (parasha.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
              decoration: BoxDecoration(
                color: _AppColors.navy.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'פרשת $parasha',
                textDirection: TextDirection.rtl,
                style: GoogleFonts.alef(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _AppColors.navy,
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
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _AppColors.textPrimary,
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
    _zmanCheckTimer = Timer.periodic(
      const Duration(minutes: 5),
      (timer) => _fetchNextZman(),
    );
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
      final candidates = <Map<String, dynamic>>[];

      void addCandidate(String label, DateTime? time) {
        if (time == null) return;
        final minutes = time.hour * 60 + time.minute;
        if (minutes > currentMinutes) {
          candidates.add({'label': label, 'time': time, 'minutes': minutes});
        }
      }

      addCandidate('עלות השחר', zmanimCalendar.getAlos72());
      addCandidate('נץ החמה', zmanimCalendar.getSunrise());
      addCandidate('סוף זמן ק״ש', zmanimCalendar.getSofZmanShmaGRA());
      addCandidate('סוף זמן תפילה', zmanimCalendar.getSofZmanTfilaGRA());
      addCandidate('חצות היום', zmanimCalendar.getChatzos());
      addCandidate('מנחה גדולה', zmanimCalendar.getMinchaGedola());
      addCandidate('מנחה קטנה', zmanimCalendar.getMinchaKetana());
      addCandidate('פלג המנחה', zmanimCalendar.getPlagHamincha());
      addCandidate('שקיעה', zmanimCalendar.getSunset());
      addCandidate(
        'צאת הכוכבים',
        zmanimCalendar.getTzaisGeonim7Point083Degrees(),
      );

      Map<String, dynamic>? nextZman;
      if (candidates.isNotEmpty) {
        candidates.sort(
          (a, b) => (a['minutes'] as int).compareTo(b['minutes'] as int),
        );
        nextZman = candidates.first;
      } else {
        // אחרי שכל הזמנים עברו - הצג את הזמן הראשון של מחר.
        final tomorrow = now.add(const Duration(days: 1));
        final tomorrowGeo = GeoLocation.setLocation(
          'ירושלים',
          31.7683,
          35.2137,
          tomorrow,
        );
        final tomorrowCalendar = ComplexZmanimCalendar.intGeoLocation(
          tomorrowGeo,
        );

        final tomorrowAlos = tomorrowCalendar.getAlos72();
        final tomorrowSunrise = tomorrowCalendar.getSunrise();

        if (tomorrowAlos != null) {
          nextZman = {
            'label': 'עלות השחר',
            'time': tomorrowAlos,
            'minutes': tomorrowAlos.hour * 60 + tomorrowAlos.minute,
          };
        } else if (tomorrowSunrise != null) {
          nextZman = {
            'label': 'נץ החמה',
            'time': tomorrowSunrise,
            'minutes': tomorrowSunrise.hour * 60 + tomorrowSunrise.minute,
          };
        }
      }

      if (mounted) {
        setState(() {
          if (nextZman != null) {
            _nextZman = dateFormat.format(nextZman['time'] as DateTime);
            _nextZmanLabel = nextZman['label'] as String;
          } else {
            _nextZman = 'לא זמין';
            _nextZmanLabel = '';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _nextZman = 'שגיאה';
          _isLoading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _nextZman == 'לא זמין' || _nextZman == 'שגיאה')
      return const SizedBox.shrink();

    return _InfoChip(
      icon: Icons.wb_sunny_outlined,
      iconColor: _AppColors.amber,
      bgColor: _AppColors.amberLight,
      child: Text.rich(
        TextSpan(
          style: GoogleFonts.alef(fontSize: 13, color: _AppColors.textPrimary),
          children: [
            const TextSpan(text: 'הזמן הבא: '),
            TextSpan(
              text: _nextZmanLabel,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: _AppColors.amber,
              ),
            ),
            TextSpan(text: ' — $_nextZman'),
          ],
        ),
        textDirection: TextDirection.rtl,
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
    _prayerCheckTimer = Timer.periodic(
      const Duration(minutes: 1),
      (timer) => _fetchAndDetermineNextPrayer(),
    );
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
        final prayerMinutes =
            (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
        if (prayerMinutes > currentMinutes) {
          nextPrayer = item;
          break;
        }
      }

      if (nextPrayer == null && data.isNotEmpty) nextPrayer = data.first;

      if (mounted)
        setState(() {
          _nextPrayerTime = nextPrayer;
        });
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

    return _InfoChip(
      icon: Icons.schedule_outlined,
      iconColor: _AppColors.teal,
      bgColor: _AppColors.tealLight,
      child: Text.rich(
        TextSpan(
          style: GoogleFonts.alef(fontSize: 13, color: _AppColors.textPrimary),
          children: [
            const TextSpan(text: 'תפילה הבאה: '),
            TextSpan(
              text: '$type',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: _AppColors.teal,
              ),
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
// Helper: _InfoChip — שורת מידע משודרגת
// ─────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Widget child;

  const _InfoChip({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withValues(alpha: 0.2), width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: iconColor),
          ),
          const SizedBox(width: 10),
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
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final supabase = Supabase.instance.client;
  String rabbiQuote = 'טוען ציטוט...';
  bool isLoading = true;
  int _adminTapCount = 0;

  Map<String, dynamic>? latestVideo;
  bool videoLoading = true;
  bool showVideoPlayer = false;
  bool _hideNewVideoBadge = false;
  String? _badgeVideoId;
  int _refreshTick = 0;

  late AnimationController _mainController;
  late AnimationController _quoteController;
  late AnimationController _panelController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _quoteOpacityAnimation;
  late Animation<double> _panelSlideAnimation;
  late Animation<double> _panelFadeAnimation;

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
    WidgetsBinding.instance.addObserver(this);
    _initializeAnimations();
    _refreshMainScreen();
  }

  Future<void> _refreshMainScreen() async {
    if (!mounted) return;

    setState(() {
      _refreshTick++;
      showVideoPlayer = false;
    });

    await Future.wait([_fetchRabbiData(), _fetchLatestVideo()]);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshMainScreen();
    }
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
    _panelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
      ),
    );
    _slideAnimation = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );
    _quoteOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _quoteController, curve: Curves.easeIn));
    _panelSlideAnimation = Tween<double>(
      begin: -20.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _panelController, curve: Curves.easeOut));
    _panelFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _panelController, curve: Curves.easeIn));
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
      _panelController.forward();
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
      _panelController.forward();
      _mainController.forward();
      _quoteController.forward();
      debugPrint('Error fetching rabbi data: $e');
    }
  }

  Future<void> _fetchLatestVideo() async {
    try {
      final response = await supabase
          .from('סרטוני_רב')
          .select()
          .eq('פעיל', true)
          .order('תאריך_הוספה', ascending: false)
          .limit(1);
      if (!mounted) return;

      final Map<String, dynamic>? nextVideo =
          response.isNotEmpty ? response[0] : null;
      final String? nextVideoId = nextVideo?['id']?.toString();

      setState(() {
        // Show the badge again only when a different video arrives.
        if (nextVideoId != null && nextVideoId != _badgeVideoId) {
          _hideNewVideoBadge = false;
          _badgeVideoId = nextVideoId;
        }
        latestVideo = nextVideo;
        videoLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        latestVideo = null;
        videoLoading = false;
      });
      debugPrint('Error fetching latest video: $e');
    }
  }

  Widget _buildLatestVideoCard() {
    if (latestVideo == null) return const SizedBox.shrink();

    final title = latestVideo!['כותרת'] ?? 'סרטון חדש';
    final description = latestVideo!['תיאור'] ?? '';
    final thumbnailUrl = latestVideo!['תמונה_thumbnail'];
    final googleDriveUrl = latestVideo!['קישור_גוגל_דרייב'] ?? '';

    if (showVideoPlayer) return _buildVideoPlayer(title, googleDriveUrl);

    return GestureDetector(
      onTap:
          () => setState(() {
            showVideoPlayer = true;
            _hideNewVideoBadge = true;
          }),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _AppColors.blue.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: _AppColors.navy.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Container(
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    _AppColors.navy.withValues(alpha: 0.95),
                    _AppColors.blue.withValues(alpha: 0.75),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                image:
                    thumbnailUrl != null
                        ? DecorationImage(
                          image: NetworkImage(thumbnailUrl),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withValues(alpha: 0.35),
                            BlendMode.darken,
                          ),
                        )
                        : null,
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.5),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: _AppColors.navy.withValues(alpha: 0.3),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(10),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        size: 22,
                        color: _AppColors.navy,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.alef(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textDirection: TextDirection.rtl,
                              style: GoogleFonts.alef(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (!showVideoPlayer && !_hideNewVideoBadge)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD62B2B).withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'סרטון חדש',
                    style: GoogleFonts.alef(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mainController.dispose();
    _quoteController.dispose();
    _panelController.dispose();
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
          color: _AppColors.navy.withValues(alpha: 0.85),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: ThemeHelpers.buildDefaultBackground()),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                screenWidth * 0.048,
                0,
                screenWidth * 0.048,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildScreenHeader(),
                  SizedBox(height: safeAreaHeight * 0.008),
                  SizedBox(
                    height: safeAreaHeight * 0.47,
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
                  SizedBox(height: safeAreaHeight * 0.012),
                  AnimatedBuilder(
                    animation: _panelController,
                    builder:
                        (context, child) => Transform.translate(
                          offset: Offset(0, _panelSlideAnimation.value),
                          child: FadeTransition(
                            opacity: _panelFadeAnimation,
                            child: child,
                          ),
                        ),
                    child: _buildQuickInfoPanel(),
                  ),
                  SizedBox(height: safeAreaHeight * 0.01),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer(String title, String googleDriveUrl) {
    final embedUrl = _convertGoogleDriveUrlToEmbed(googleDriveUrl);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => setState(() => showVideoPlayer = false),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: _AppColors.blue,
                ),
              ),
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.alef(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.black,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: WebViewWidget(
              controller:
                  WebViewController()
                    ..setJavaScriptMode(JavaScriptMode.unrestricted)
                    ..loadRequest(Uri.parse(embedUrl)),
            ),
          ),
        ),
      ],
    );
  }

  String _convertGoogleDriveUrlToEmbed(String url) {
    String fileId = '';
    if (url.contains('/d/')) {
      final parts = url.split('/d/');
      if (parts.length > 1) fileId = parts[1].split('/')[0];
    } else if (url.contains('id=')) {
      final parts = url.split('id=');
      if (parts.length > 1) fileId = parts[1].split('&')[0];
    }
    return 'https://drive.google.com/file/d/$fileId/preview';
  }

  bool _shouldReplaceRabbiTextWithVideo() {
    return DateTime.now().weekday == DateTime.friday && latestVideo != null;
  }

  Widget _buildQuickInfoPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _AppColors.divider, width: 1),
        boxShadow: [
          BoxShadow(
            color: _AppColors.navy.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // כותרת פאנל
          Padding(
            padding: const EdgeInsets.only(bottom: 8, right: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'מידע מהיר',
                  style: GoogleFonts.alef(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: _AppColors.textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: _AppColors.lightBlue,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.dashboard_customize_outlined,
                    size: 13,
                    color: _AppColors.blue,
                  ),
                ),
              ],
            ),
          ),
          HebrewDateBanner(key: ValueKey('hebrew_date_$_refreshTick')),
          const SizedBox(height: 6),
          NextZmanBanner(key: ValueKey('next_zman_$_refreshTick')),
          const SizedBox(height: 6),
          NextPrayerBanner(key: ValueKey('next_prayer_$_refreshTick')),
        ],
      ),
    );
  }

  Widget _buildScreenHeader() {
    return Transform.translate(
      offset: const Offset(0, -4),
      child: Column(
        children: [
          Text(
            'ברוכים הבאים',
            style: GoogleFonts.alef(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: _AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 1),
          Text(
            'מחלקת כשרות דת והלכה',
            style: GoogleFonts.alef(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: _AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 8),
          Container(
            width: 84,
            height: 4,
            decoration: BoxDecoration(
              color: _AppColors.blue.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
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
                  height: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 560),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.42),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _AppColors.navy.withValues(alpha: 0.09),
                        blurRadius: 24,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(
                      MediaQuery.of(context).size.width * 0.045,
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width * 0.155,
                          height: MediaQuery.of(context).size.width * 0.155,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              MediaQuery.of(context).size.width * 0.1,
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.8),
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              MediaQuery.of(context).size.width * 0.1,
                            ),
                            child: Image.asset(
                              'assets/hrav.png',
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Icon(
                          Icons.format_quote_rounded,
                          size: 22,
                          color: _AppColors.blue.withValues(alpha: 0.7),
                        ),
                        const SizedBox(height: 3),

                        // Only this area is scrollable.
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: constraints.maxHeight + 24,
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    ),
                                    child:
                                        _shouldReplaceRabbiTextWithVideo()
                                            ? _buildLatestVideoCard()
                                            : Text(
                                              rabbiQuote,
                                              style: GoogleFonts.alef(
                                                fontSize:
                                                    MediaQuery.of(
                                                      context,
                                                    ).size.width *
                                                    0.041,
                                                height: 1.7,
                                                color: _AppColors.textPrimary,
                                                fontWeight: FontWeight.w400,
                                              ),
                                              textAlign: TextAlign.center,
                                              textDirection: TextDirection.rtl,
                                            ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.32),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            'הרב יואב חנניה אוקנין',
                            style: GoogleFonts.alef(
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.04,
                              fontWeight: FontWeight.w500,
                              color: _AppColors.textPrimary,
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
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _AppColors.lightBlue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: _AppColors.blue,
                  strokeWidth: 2.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '...טוען',
            style: GoogleFonts.alef(fontSize: 15, color: _AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: _AppColors.surface,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_AppColors.navy, Color(0xFF1A5FB4)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      size: 26,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'תפריט ראשי',
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.alef(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'כשרות דת והלכה',
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.alef(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            ..._bubbles.map((bubble) {
              return Directionality(
                textDirection: TextDirection.rtl,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 3,
                  ),
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: (bubble['color'] as Color).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: (bubble['color'] as Color).withValues(
                          alpha: 0.2,
                        ),
                        width: 0.8,
                      ),
                    ),
                    child: Icon(
                      bubble['icon'],
                      color: bubble['color'],
                      size: 19,
                    ),
                  ),
                  title: Text(
                    bubble['label'],
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.alef(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _AppColors.textPrimary,
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
                    ).then((_) {
                      if (!mounted) return;
                      _refreshMainScreen();
                    });
                  },
                ),
              );
            }),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(height: 1, color: _AppColors.divider),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'מרכז רפואי שיבא',
                textAlign: TextAlign.right,
                style: GoogleFonts.alef(
                  fontSize: 11,
                  color: _AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
