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
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'package:intl/intl.dart' as intl;
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'AdminLoginScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rabbi_shiba/utils/theme_helpers.dart';

// Map of common Parasha names translations from English to Hebrew.
const Map<String, String> parashaTranslations = {
  'Parashat Bereshit': '׳‘׳¨׳׳©׳™׳×',
  'Parashat Noach': '׳ ׳—',
  'Parashat Lech-Lecha': '׳׳-׳׳',
  'Parashat Vayera': '׳•׳™׳¨׳',
  'Parashat Chayei Sarah': '׳—׳™׳™-׳©׳¨׳”',
  'Parashat Toldot': '׳×׳•׳׳“׳•׳×',
  'Parashat Vayetzei': '׳•׳™׳¦׳',
  'Parashat Vayishlach': '׳•׳™׳©׳׳—',
  'Parashat Vayeshev': '׳•׳™׳©׳‘',
  'Parashat Miketz': '׳׳§׳¥',
  'Parashat Vayigash': '׳•׳™׳’׳©',
  'Parashat Vayechi': '׳•׳™׳—׳™',
  'Parashat Shemot': '׳©׳׳•׳×',
  'Parashat Vaera': '׳•ײ¸׳ײµ׳¨ײ¸׳',
  'Parashat Bo': '׳‘׳',
  'Parashat Beshalach': '׳‘׳©׳׳—',
  'Parashat Yitro': '׳™׳×׳¨׳•',
  'Parashat Mishpatim': '׳׳©׳₪׳˜׳™׳',
  'Parashat Terumah': '׳×׳¨׳•׳׳”',
  'Parashat Tetzaveh': '׳×׳¦׳•׳”',
  'Parashat Ki Tisa': '׳›׳™-׳×׳©׳',
  'Parashat Vayakhel': '׳•׳™׳§׳”׳',
  'Parashat Pekudei': '׳₪׳§׳•׳“׳™',
  'Parashat Vayikra': '׳•׳™׳§׳¨׳',
  'Parashat Tzav': '׳¦׳•',
  'Parashat Shemini': '׳©׳׳™׳ ׳™',
  'Parashat Tazria': '׳×׳–׳¨׳™׳¢',
  'Parashat Metzora': '׳׳¦׳•׳¨׳¢',
  'Parashat Acharei Mot': '׳׳—׳¨׳™-׳׳•׳×',
  'Parashat Kedoshim': '׳§׳“׳•׳©׳™׳',
  'Parashat Emor': '׳׳׳•׳¨',
  'Parashat Behar': '׳‘׳”׳¨',
  'Parashat Bechukotai': '׳‘׳—׳§׳×׳™',
  'Parashat Bamidbar': '׳‘׳׳“׳‘׳¨',
  'Parashat Nasso': '׳ ׳©׳',
  'Parashat Behaalotecha': '׳‘׳”׳¢׳׳•׳×׳',
  'Parashat Shlach': '׳©׳׳—',
  'Parashat Korach': '׳§׳•׳¨׳—',
  'Parashat Chukat': '׳—׳•׳§׳×',
  'Parashat Balak': '׳‘׳׳§',
  'Parashat Pinchas': '׳₪׳™׳ ׳—׳¡',
  'Parashat Matot': '׳׳˜׳•׳×',
  'Parashat Massei': '׳׳¡׳¢׳™',
  'Parashat Devarim': '׳“׳‘׳¨׳™׳',
  'Parashat Vaetchanan': '׳•׳׳×׳—׳ ׳',
  'Parashat Eikev': '׳¢׳§׳‘',
  'Parashat Reeh': '׳¨׳׳”',
  'Parashat Shoftim': '׳©׳•׳₪׳˜׳™׳',
  'Parashat Ki Teitzei': '׳›׳™ ׳×׳¦׳',
  'Parashat Ki Tavo': '׳›׳™ ׳×׳‘׳•׳',
  'Parashat Nitzavim': '׳ ׳™׳¦׳‘׳™׳',
  'Parashat Vayelech': '׳•׳™׳׳',
  'Parashat Haazinu': '׳”׳׳–׳™׳ ׳•',
  'Parashat Vezot Haberakhah': '׳•׳–׳׳× ׳”׳‘׳¨׳›׳”',
};

// ג… 1. ׳•׳•׳™׳“׳’'׳˜ ׳׳”׳¦׳’׳× ׳×׳׳¨׳™׳ ׳¢׳‘׳¨׳™ ׳•׳₪׳¨׳©׳”
class HebrewDateBanner extends StatefulWidget {
  const HebrewDateBanner({super.key});

  @override
  _HebrewDateBannerState createState() => _HebrewDateBannerState();
}

class _HebrewDateBannerState extends State<HebrewDateBanner> {
  String hebrewDate = '׳˜׳•׳¢׳...';
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

      // ׳˜׳¢׳™׳ ׳” ׳׳”׳©׳¨׳× ׳›׳“׳™ ׳׳§׳‘׳ ׳׳× ׳”׳×׳׳¨׳™׳ ׳”׳¢׳‘׳¨׳™ ׳”׳ ׳•׳›׳—׳™
      final formattedDate =
          '${nowDate.year}-${nowDate.month.toString().padLeft(2, '0')}-${nowDate.day.toString().padLeft(2, '0')}';

      final response = await http.get(
        Uri.parse(
          'https://www.hebcal.com/converter?cfg=json&date=$formattedDate&g2h=1',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String fetchedHebrewDate = data['hebrew'] ?? '׳׳ ׳–׳׳™׳';
        String fetchedParasha = '';

        // ׳‘׳“׳™׳§׳” ׳׳ ׳”׳×׳׳¨׳™׳ ׳”׳¢׳‘׳¨׳™ ׳”׳©׳×׳ ׳” (׳›׳׳•׳׳¨ ׳¢׳‘׳¨ ׳¦׳׳× ׳”׳›׳•׳›׳‘׳™׳ ׳•׳™׳•׳ ׳¢׳‘׳¨׳™ ׳—׳“׳©)
        final cachedHebrewDate = prefs.getString('cachedHebrewDate');

        if (cachedHebrewDate == fetchedHebrewDate) {
          // ׳׳•׳×׳• ׳™׳•׳ ׳¢׳‘׳¨׳™ - ׳”׳©׳×׳׳© ׳‘-cache ׳©׳ ׳”׳₪׳¨׳©׳”
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

        // ׳™׳•׳ ׳¢׳‘׳¨׳™ ׳—׳“׳© - ׳˜׳¢׳ ׳׳× ׳”׳₪׳¨׳©׳” ׳׳—׳“׳©
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

        // ׳©׳׳™׳¨׳” ׳‘-cache - ׳”׳×׳׳¨׳™׳ ׳”׳¢׳‘׳¨׳™ ׳”׳•׳ ׳”׳׳₪׳×׳—
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
            hebrewDate = '׳©׳’׳™׳׳” ׳‘׳˜׳¢׳™׳ ׳”';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          hebrewDate = '׳©׳’׳™׳׳” ׳‘׳˜׳¢׳™׳ ׳”';
          isLoading = false;
        });
      }
      debugPrint('׳©׳’׳™׳׳” ׳‘-fetchHebrewDateAndParasha: $e');
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
              '׳˜׳•׳¢׳ ׳×׳׳¨׳™׳ ׳¢׳‘׳¨׳™...',
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
                    '׳₪׳¨׳©׳× $parasha',
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

// ג… 2. ׳•׳•׳™׳“׳’'׳˜ ׳׳”׳¦׳’׳× ׳”׳–׳׳ ׳”׳‘׳ (׳ ׳¥/׳©׳§׳™׳¢׳”)
class NextZmanBanner extends StatefulWidget {
  const NextZmanBanner({super.key});

  @override
  _NextZmanBannerState createState() => _NextZmanBannerState();
}

class _NextZmanBannerState extends State<NextZmanBanner> {
  String _nextZman = '׳˜׳•׳¢׳...';
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
    _zmanCheckTimer = Timer.periodic(Duration(minutes: 5), (timer) {
      _fetchNextZman();
    });
  }

  void _fetchNextZman() async {
    try {
      final now = DateTime.now();
      final currentMinutes = now.hour * 60 + now.minute;

      // ׳׳™׳¦׳•׳¨ Zmanim calendar ׳¢׳‘׳•׳¨ ׳™׳¨׳•׳©׳׳™׳ (׳‘׳¨׳™׳¨׳× ׳׳—׳“׳)
      final geoLocation = GeoLocation.setLocation(
        '׳™׳¨׳•׳©׳׳™׳',
        31.7683,
        35.2137,
        now,
      );

      final zmanimCalendar = ComplexZmanimCalendar.intGeoLocation(geoLocation);
      final dateFormat = intl.DateFormat('HH:mm');

      // ׳§׳— ׳׳× ׳”׳–׳׳ ׳™׳ ׳”׳—׳©׳•׳‘׳™׳
      final sunrise = zmanimCalendar.getSunrise();
      final sunset = zmanimCalendar.getSunset();

      Map<String, dynamic>? nextZman;

      // ׳‘׳“׳•׳§ ׳׳™׳–׳” ׳–׳׳ ׳”׳•׳ ׳”׳‘׳
      if (sunrise != null) {
        final sunriseMinutes = sunrise.hour * 60 + sunrise.minute;
        if (sunriseMinutes > currentMinutes) {
          nextZman = {
            'time': dateFormat.format(sunrise),
            'label': '׳ ׳¥ ׳”׳—׳׳”',
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
              'label': '׳©׳§׳™׳¢׳”',
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
            _nextZman = '׳׳ ׳–׳׳™׳';
            _nextZmanLabel = '';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _nextZman = '׳©׳’׳™׳׳”';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox.shrink();
    }

    if (_nextZman == '׳׳ ׳–׳׳™׳' || _nextZman == '׳©׳’׳™׳׳”') {
      return SizedBox.shrink();
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Icon(Icons.wb_sunny, color: Color(0xFFF57F17), size: 20),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              '$_nextZmanLabel ׳‘׳©׳¢׳” $_nextZman',
              textDirection: TextDirection.rtl,
              style: GoogleFonts.alef(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF57F17),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ג… 3. ׳•׳•׳™׳“׳’'׳˜ ׳׳”׳¦׳’׳× ׳”׳×׳₪׳™׳׳” ׳”׳‘׳׳”
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
    _prayerCheckTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      _fetchAndDetermineNextPrayer();
    });
  }

  void _fetchAndDetermineNextPrayer() async {
    try {
      final now = DateTime.now();
      final currentMinutes = now.hour * 60 + now.minute;

      final response = await Supabase.instance.client
          .from('׳–׳׳ ׳™ ׳×׳₪׳™׳׳•׳× ׳™׳׳™ ׳—׳•׳')
          .select('׳©׳¢׳”, "׳¡׳•׳’ ׳×׳₪׳™׳׳”"');

      final data = List<Map<String, dynamic>>.from(response);
      Map<String, dynamic>? nextPrayer;

      data.sort((a, b) => a['׳©׳¢׳”'].compareTo(b['׳©׳¢׳”']));

      for (var item in data) {
        final timeString = item['׳©׳¢׳”'];
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
      // ׳׳˜׳₪׳ ׳‘׳©׳’׳™׳׳” ׳‘׳©׳§׳˜
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_nextPrayerTime == null) {
      return SizedBox.shrink();
    }

    final time = _nextPrayerTime!['׳©׳¢׳”'];
    final type = _nextPrayerTime!['׳¡׳•׳’ ׳×׳₪׳™׳׳”'];
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
              '׳”׳×׳₪׳™׳׳” ׳”׳‘׳׳”: $type ׳‘׳©׳¢׳” $displayTime',
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

// ג… 3. ׳׳¡׳ EntranceScreen ׳׳©׳•׳₪׳¨

class EntranceScreen extends StatefulWidget {
  const EntranceScreen({super.key});

  @override
  _EntranceScreenState createState() => _EntranceScreenState();
}

class _EntranceScreenState extends State<EntranceScreen>
    with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  String rabbiQuote = '׳˜׳•׳¢׳ ׳¦׳™׳˜׳•׳˜...';
  String rabbiImageUrl = '';
  bool isLoading = true;
  int _adminTapCount = 0; // secret tap counter for admin

  late AnimationController _mainController;
  late AnimationController _quoteController;
  late AnimationController _buttonController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _quoteOpacityAnimation;
  late Animation<double> _buttonSlideAnimation;

  // ׳¨׳©׳™׳׳× ׳”׳‘׳•׳¢׳•׳× - ׳›׳ ׳”׳׳₪׳©׳¨׳•׳™׳•׳×
  static final List<Map<String, dynamic>> _bubbles = [
    {
      'label': '׳–׳׳ ׳™ ׳”׳™׳•׳',
      'icon': Icons.sunny,
      'color': Colors.amber,
      'screenBuilder': () => ZmanimScreen(),
    },
    {
      'label': '׳©׳‘׳×',
      'icon': Icons.wine_bar,
      'color': Colors.indigo,
      'screenBuilder': () => ShabatScreen(),
    },
    {
      'label': '׳›׳©׳¨׳•׳×',
      'icon': Icons.food_bank,
      'color': Colors.green,
      'screenBuilder': () => GeneralDetailScreen(type: '׳›׳©׳¨׳•׳×'),
    },
    {
      'label': '׳‘׳×׳™ ׳›׳ ׳¡׳× ׳‘׳׳¨׳›׳– ׳”׳¨׳₪׳•׳׳™',
      'icon': Icons.location_on,
      'color': Colors.orange,
      'screenBuilder': () => UserToSynagogueMap(),
    },
    {
      'label': '׳–׳׳ ׳™ ׳×׳₪׳™׳׳•׳× ׳™׳׳™ ׳—׳•׳',
      'icon': Icons.access_time,
      'color': Colors.blue,
      'screenBuilder': () => WeekdayTefilotScreen(),
    },
    {
      'label': '׳˜׳•׳׳׳× ׳›׳”׳ ׳™׳',
      'icon': Icons.people,
      'color': Colors.brown,
      'screenBuilder': () => GeneralDetailScreen(type: '׳˜׳•׳׳׳× ׳›׳”׳ ׳™׳'),
    },
    {
      'label': '׳ ׳₪׳˜׳¨׳™׳',
      'icon': Icons.help_outline,
      'color': Colors.grey,
      'screenBuilder': () => GeneralDetailScreen(type: '׳ ׳₪׳˜׳¨׳™׳'),
    },
    {
      'label': '׳׳§׳•׳•׳”',
      'icon': Icons.water,
      'color': Colors.blueAccent,
      'screenBuilder': () => GeneralDetailScreen(type: '׳׳§׳•׳•׳”'),
    },
    {
      'label': '׳׳•׳¢׳“׳™ ׳™׳©׳¨׳׳',
      'icon': Icons.calendar_today,
      'color': Colors.purple,
      'screenBuilder': () => MoadiIsraelScreen(),
    },
    {
      'label': '׳™׳™׳¢׳•׳¥ ׳”׳׳›׳×׳™ ׳¨׳₪׳•׳׳™',
      'icon': Icons.medical_services,
      'color': Colors.teal,
      'screenBuilder': () => ChatScreen(),
    },
    {
      'label': '׳׳ ׳©׳™ ׳§׳©׳¨',
      'icon': Icons.contacts,
      'color': Colors.redAccent,
      'screenBuilder': () => GeneralDetailScreen(type: '׳׳ ׳©׳™ ׳§׳©׳¨'),
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
              .from('׳›׳׳׳™')
              .select('׳׳™׳“׳¢')
              .eq('׳¡׳•׳’', '׳“׳‘׳¨ ׳”׳¨׳‘')
              .limit(1)
              .maybeSingle();

      if (!mounted) return;

      if (response == null || response['׳׳™׳“׳¢'] == null) {
        setState(() {
          rabbiQuote =
              '׳‘׳¨׳•׳›׳™׳ ׳”׳‘׳׳™׳ ׳׳׳₪׳׳™׳§׳¦׳™׳™׳× ׳›׳©׳¨׳•׳× ׳“׳× ׳•׳”׳׳›׳” ׳©׳ ׳׳¨׳›׳– ׳¨׳₪׳•׳׳™ ׳©׳™׳‘׳. ׳›׳׳ ׳×׳׳¦׳׳• ׳׳× ׳›׳ ׳”׳׳™׳“׳¢ ׳”׳“׳¨׳•׳© ׳׳›׳ ׳׳©׳׳™׳¨׳” ׳¢׳ ׳”׳׳›׳•׳× ׳”׳›׳©׳¨׳•׳× ׳•׳”׳“׳× ׳‘׳׳¨׳›׳– ׳”׳¨׳₪׳•׳׳™.';
          isLoading = false;
        });
      } else {
        setState(() {
          rabbiQuote =
              response['׳׳™׳“׳¢']?.toString() ??
              '׳‘׳¨׳•׳›׳™׳ ׳”׳‘׳׳™׳ ׳׳׳₪׳׳™׳§׳¦׳™׳™׳× ׳›׳©׳¨׳•׳× ׳“׳× ׳•׳”׳׳›׳” ׳©׳ ׳׳¨׳›׳– ׳¨׳₪׳•׳׳™ ׳©׳™׳‘׳.';
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
            '׳‘׳¨׳•׳›׳™׳ ׳”׳‘׳׳™׳ ׳׳׳₪׳׳™׳§׳¦׳™׳™׳× ׳›׳©׳¨׳•׳× ׳“׳× ׳•׳”׳׳›׳” ׳©׳ ׳׳¨׳›׳– ׳¨׳₪׳•׳׳™ ׳©׳™׳‘׳. ׳›׳׳ ׳×׳׳¦׳׳• ׳׳× ׳›׳ ׳”׳׳™׳“׳¢ ׳”׳“׳¨׳•׳© ׳׳›׳ ׳׳©׳׳™׳¨׳” ׳¢׳ ׳”׳׳›׳•׳× ׳”׳›׳©׳¨׳•׳× ׳•׳”׳“׳× ׳‘׳׳¨׳›׳– ׳”׳¨׳₪׳•׳׳™.';
        isLoading = false;
      });
      _mainController.forward();
      _quoteController.forward();
      _buttonController.forward();
      debugPrint('Error fetching rabbi data: $e');
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
      drawer: _buildDrawer(),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: Color(0xFF1E293B)),
        title: Text(
          '׳›׳©׳¨׳•׳× ׳“׳× ׳•׳”׳׳›׳”',
          style: GoogleFonts.alef(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
          textDirection: TextDirection.rtl,
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: ThemeHelpers.buildDefaultBackground(
              colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.05,
                vertical: safeAreaHeight * 0.02,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. ׳×׳׳¨׳™׳ ׳¢׳‘׳¨׳™ ׳•׳₪׳¨׳©׳” - ׳¨׳׳©׳•׳
                  HebrewDateBanner(),

                  SizedBox(height: 10),

                  // 2. ׳‘׳׳ ׳¨ ׳”׳–׳׳ ׳”׳‘׳ - ׳©׳ ׳™
                  NextZmanBanner(),

                  SizedBox(height: 10),

                  // 3. ׳‘׳׳ ׳¨ ׳”׳×׳₪׳™׳׳” ׳”׳‘׳׳” - ׳©׳׳™׳©׳™
                  NextPrayerBanner(),

                  SizedBox(height: safeAreaHeight * 0.02),

                  // 4. Header Section - ׳¨׳‘׳™׳¢׳™ (with secret admin tap)
                  AnimatedBuilder(
                    animation: _mainController,
                    builder: (context, child) {
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          _adminTapCount++;
                          if (_adminTapCount >= 5) {
                            _adminTapCount = 0;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AdminLoginScreen(),
                              ),
                            );
                          }
                        },
                        child: Transform.translate(
                          offset: Offset(0, _slideAnimation.value),
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: ScaleTransition(
                              scale: _scaleAnimation,
                              child: _buildHeader(),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: safeAreaHeight * 0.02),

                  // 5. Quote Section - ׳—׳׳™׳©׳™, ׳×׳•׳₪׳¡ ׳׳× ׳¨׳•׳‘ ׳”׳׳¡׳
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

                  // 6. Buttons Section - ׳©׳™׳©׳™
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
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title
        Text(
          '׳‘׳¨׳•׳›׳™׳ ׳”׳‘׳׳™׳',
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
          '׳׳—׳׳§׳× ׳›׳©׳¨׳•׳× ׳“׳× ׳•׳”׳׳›׳”',
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
          SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              color: Color(0xFF3B82F6),
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 20),
          Text(
            '...׳˜׳•׳¢׳',
            style: GoogleFonts.alef(fontSize: 16, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteCard() {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.045),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rabbi Image - ׳§׳˜׳ ׳™׳•׳×׳¨
            Container(
              width: MediaQuery.of(context).size.width * 0.16,
              height: MediaQuery.of(context).size.width * 0.16,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  MediaQuery.of(context).size.width * 0.08,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF3B82F6).withValues(alpha: 0.2),
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

            // Quote mark - ׳§׳˜׳ ׳™׳•׳×׳¨
            Icon(
              Icons.format_quote,
              size: 24,
              color: Color(0xFF3B82F6).withValues(alpha: 0.6),
            ),

            SizedBox(height: 8),

            // Quote text
            Padding(
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

            SizedBox(height: 12),

            // Attribution - ׳§׳•׳׳₪׳§׳˜׳™ ׳™׳•׳×׳¨
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '׳”׳¨׳‘ ׳™׳•׳׳‘ ׳—׳ ׳ ׳™׳” ׳׳•׳§׳ ׳™׳',
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
        SizedBox(
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
              shadowColor: Colors.black.withValues(alpha: 0.15),
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
                  '׳™׳¦׳™׳¨׳× ׳§׳©׳¨ ׳¢׳ ׳”׳¨׳‘',
                  style: GoogleFonts.alef(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book, size: 40, color: Colors.white),
                  SizedBox(height: 12),
                  Text(
                    '׳×׳₪׳¨׳™׳˜ ׳¨׳׳©׳™',
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.alef(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
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
                  leading: Icon(
                    bubble['icon'],
                    color: bubble['color'],
                    size: 24,
                  ),
                  title: Text(
                    bubble['label'],
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.alef(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
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
                        transitionDuration: Duration(milliseconds: 300),
                      ),
                    );
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

