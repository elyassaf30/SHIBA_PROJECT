import 'package:flutter/material.dart';
import 'package:rabbi_shiba/screens/home_screen.dart';
import 'package:rabbi_shiba/screens/chet_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/animation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Map of common Parasha names translations from English to Hebrew.
const Map<String, String> parashaTranslations = {
  'Parashat Bereshit': 'בראשית',
  'Parashat Noach': 'נח',
  'Parashat Lech-Lecha': 'לך לך',
  'Parashat Vayera': 'וירא',
  'Parashat Chayei Sarah': 'חיי שרה',
  'Parashat Toldot': 'תולדות',
  'Parashat Vayetzei': 'וייצא',
  'Parashat Vayishlach': 'וישלח',
  'Parashat Vayeshev': 'וישב',
  'Parashat Miketz': 'מקץ',
  'Parashat Vayigash': 'ויגש',
  'Parashat Vayechi': 'ויחי',
  'Parashat Shemot': 'שמות',
  'Parashat Vaera': 'וָאֵרָא',
  'Parashat Bo': 'בו',
  'Parashat Beshalach': 'בשלח',
  'Parashat Yitro': 'יתרו',
  'Parashat Mishpatim': 'משפטים',
  'Parashat Terumah': 'תרומה',
  'Parashat Tetzaveh': 'תצוה',
  'Parashat Ki Tisa': 'כי תשא',
  'Parashat Vayakhel': 'ויקהל',
  'Parashat Pekudei': 'פקודי',
  'Parashat Vayikra': 'ויקרא',
  'Parashat Tzav': 'צו',
  'Parashat Shemini': 'שמיני',
  'Parashat Tazria': 'תזריע',
  'Parashat Metzora': 'מצורע',
  'Parashat Acharei Mot': 'אחרי מות',
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

// ✅ 1. ווידג'ט להצגת תאריך עברי ופרשה
class HebrewDateBanner extends StatefulWidget {
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
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: Color(0xFFFFF9C4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFFFDD835), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFF57F17),
              ),
            ),
            SizedBox(width: 10),
            Text(
              'טוען תאריך עברי...',
              style: GoogleFonts.alef(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFFF57F17),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: Color(0xFFFFF9C4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFFDD835), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today, color: Color(0xFFF57F17), size: 20),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  hebrewDate,
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.alef(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF57F17),
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          if (parasha.isNotEmpty) ...[
            SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.book, color: Color(0xFFF57F17), size: 18),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'פרשת $parasha',
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.alef(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF57F17),
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ✅ 2. ווידג'ט להצגת התפילה הבאה
class NextPrayerBanner extends StatefulWidget {
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
    _prayerCheckTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      _fetchAndDetermineNextPrayer();
    });
  }

  void _fetchAndDetermineNextPrayer() async {
    const int TIME_OFFSET_MINUTES = 120;

    try {
      final now = DateTime.now();
      final currentMinutes = now.hour * 60 + now.minute;
      final adjustedMinutes = currentMinutes + TIME_OFFSET_MINUTES;

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

        if (prayerMinutes > adjustedMinutes) {
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
    if (_nextPrayerTime == null) {
      return SizedBox.shrink();
    }

    final time = _nextPrayerTime!['שעה'];
    final type = _nextPrayerTime!['סוג תפילה'];
    final displayTime = time.length >= 5 ? time.substring(0, 5) : time;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: Color(0xFFE0F7FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF4DD0E1), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Icon(Icons.schedule, color: Color(0xFF00ACC1), size: 20),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              'התפילה הבאה: $type בשעה $displayTime',
              textDirection: TextDirection.rtl,
              style: GoogleFonts.alef(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF006064),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ 3. מסך EntranceScreen משופר

class EntranceScreen extends StatefulWidget {
  @override
  _EntranceScreenState createState() => _EntranceScreenState();
}

class _EntranceScreenState extends State<EntranceScreen>
    with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  String rabbiQuote = 'טוען ציטוט...';
  String rabbiImageUrl = '';
  bool isLoading = true;

  late AnimationController _mainController;
  late AnimationController _quoteController;
  late AnimationController _buttonController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _quoteOpacityAnimation;
  late Animation<double> _buttonSlideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _fetchRabbiData();
  }

  void _initializeAnimations() {
    _mainController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    );

    _quoteController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _buttonController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: Interval(0.2, 0.8, curve: Curves.elasticOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _quoteOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _quoteController, curve: Curves.easeIn));

    _buttonSlideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeOut),
    );
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

      if (response == null || response['מידע'] == null) {
        setState(() {
          rabbiQuote =
              'ברוכים הבאים לאפליקציית כשרות דת והלכה של מרכז רפואי שיבא. כאן תמצאו את כל המידע הדרוש לכם לשמירה על הלכות הכשרות והדת במרכז הרפואי.';
          isLoading = false;
        });
      } else {
        setState(() {
          rabbiQuote =
              response['מידע']?.toString() ??
              'ברוכים הבאים לאפליקציית כשרות דת והלכה של מרכז רפואי שיבא.';
          isLoading = false;
        });
      }

      _mainController.forward();

      Future.delayed(Duration(milliseconds: 400), () {
        if (mounted) {
          _quoteController.forward();
        }
      });

      Future.delayed(Duration(milliseconds: 800), () {
        if (mounted) {
          _buttonController.forward();
        }
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
      _buttonController.forward();
      print('Error fetching rabbi data: $e');
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _quoteController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final safeAreaHeight =
        screenHeight -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Container(
            height: safeAreaHeight,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.05,
                vertical: safeAreaHeight * 0.02,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. תאריך עברי ופרשה - ראשון
                  HebrewDateBanner(),

                  SizedBox(height: 10),

                  // 2. באנר התפילה הבאה - שני
                  NextPrayerBanner(),

                  SizedBox(height: safeAreaHeight * 0.02),

                  // 3. Header Section - שלישי
                  AnimatedBuilder(
                    animation: _mainController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: ScaleTransition(
                            scale: _scaleAnimation,
                            child: _buildHeader(),
                          ),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: safeAreaHeight * 0.02),

                  // 4. Quote Section - רביעי, תופס את רוב המסך
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _quoteController,
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: _quoteOpacityAnimation,
                          child:
                              isLoading
                                  ? _buildLoadingWidget()
                                  : _buildQuoteCard(),
                        );
                      },
                    ),
                  ),

                  SizedBox(height: safeAreaHeight * 0.02),

                  // 5. Buttons Section - אחרון
                  AnimatedBuilder(
                    animation: _buttonController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _buttonSlideAnimation.value),
                        child: FadeTransition(
                          opacity: _buttonController,
                          child: _buildButtonsSection(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title
        Text(
          'ברוכים הבאים',
          style: GoogleFonts.alef(
            fontSize: MediaQuery.of(context).size.width * 0.075,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: 4),

        // Subtitle
        Text(
          'מחלקת כשרות דת והלכה',
          style: GoogleFonts.alef(
            fontSize: MediaQuery.of(context).size.width * 0.042,
            fontWeight: FontWeight.w500,
            color: Color(0xFF475569),
            height: 1.3,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: 12),

        // Decorative line
        Container(
          height: 3,
          width: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              color: Color(0xFF3B82F6),
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 20),
          Text(
            '...טוען',
            style: GoogleFonts.alef(fontSize: 16, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 25,
            offset: Offset(0, 15),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.045),
        child: Column(
          children: [
            // Rabbi Image - קטן יותר
            Container(
              width: MediaQuery.of(context).size.width * 0.16,
              height: MediaQuery.of(context).size.width * 0.16,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  MediaQuery.of(context).size.width * 0.08,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF3B82F6).withOpacity(0.2),
                    blurRadius: 15,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  MediaQuery.of(context).size.width * 0.08,
                ),
                child: Image.asset(
                  'assets/hrav.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
            ),

            SizedBox(height: 12),

            // Quote mark - קטן יותר
            Icon(
              Icons.format_quote,
              size: 24,
              color: Color(0xFF3B82F6).withOpacity(0.6),
            ),

            SizedBox(height: 8),

            // Quote text - תופס את רוב המקום
            Expanded(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    rabbiQuote,
                    style: GoogleFonts.alef(
                      fontSize: MediaQuery.of(context).size.width * 0.042,
                      height: 1.7,
                      color: Color(0xFF374151),
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ),
            ),

            SizedBox(height: 12),

            // Attribution - קומפקטי יותר
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'הרב יואב חנניה אוקנין',
                style: GoogleFonts.alef(
                  fontSize: MediaQuery.of(context).size.width * 0.038,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
                textDirection: TextDirection.rtl,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonsSection() {
    return Column(
      children: [
        // Contact Button
        Container(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChatScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFF3B82F6),
              elevation: 8,
              shadowColor: Colors.black.withOpacity(0.15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Color(0xFF3B82F6), width: 2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(
                  FontAwesomeIcons.whatsapp,
                  size: 20,
                  color: Color(0xFF25D366),
                ),
                SizedBox(width: 10),
                Text(
                  'יצירת קשר עם הרב',
                  style: GoogleFonts.alef(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 12),

        // Enter Button
        Container(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => HomeScreen(),
                  transitionsBuilder:
                      (_, a, __, c) => FadeTransition(opacity: a, child: c),
                  transitionDuration: Duration(milliseconds: 600),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              elevation: 12,
              shadowColor: Color(0xFF3B82F6).withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'כניסה לאפליקציה',
                  style: GoogleFonts.alef(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
