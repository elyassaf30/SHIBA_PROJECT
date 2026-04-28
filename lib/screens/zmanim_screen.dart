import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kosher_dart/kosher_dart.dart' hide TextDirection;
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:rabbi_shiba/utils/theme_helpers.dart';

class ZmanimScreen extends StatefulWidget {
  const ZmanimScreen({super.key});

  @override
  _ZmanimScreenState createState() => _ZmanimScreenState();
}

class _ZmanimScreenState extends State<ZmanimScreen> {
  ComplexZmanimCalendar? _zmanimCalendar;
  JewishCalendar? _jewishCalendar;
  HebrewDateFormatter? _hebrewFormatter;
  bool _isLoading = true;
  String? _errorMessage;
  String _locationName = 'ישראל';

  @override
  void initState() {
    super.initState();
    _initializeZmanim();
  }

  Future<void> _initializeZmanim() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Position? position;
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
          ).timeout(const Duration(seconds: 5));
          _locationName = 'מיקום נוכחי';
        }
      } catch (e) {
        debugPrint('לא ניתן לקבל מיקום מדויק, משתמש במיקום ברירת מחדל');
      }

      final latitude = position?.latitude ?? 31.7683;
      final longitude = position?.longitude ?? 35.2137;

      GeoLocation geoLocation = GeoLocation.setLocation(
        _locationName,
        latitude,
        longitude,
        DateTime.now(),
      );

      setState(() {
        _zmanimCalendar = ComplexZmanimCalendar.intGeoLocation(geoLocation);
        _jewishCalendar = JewishCalendar();
        _jewishCalendar!.inIsrael = true;
        _hebrewFormatter = HebrewDateFormatter();
        _hebrewFormatter!.hebrewFormat = true;
        _hebrewFormatter!.useGershGershayim = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'שגיאה בטעינת זמנים: $e';
      });
    }
  }

  String _formatTime(DateTime? time) {
    if (time == null) return 'לא זמין';
    return DateFormat('HH:mm').format(time);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'זמני היום',
          style: GoogleFonts.alef(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: const Color.fromARGB(255, 8, 8, 9),
          ),
        ),
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 16, 19, 24)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            onPressed: _initializeZmanim,
            tooltip: 'רענן זמנים',
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: ThemeHelpers.buildDefaultBackground()),
          if (_isLoading)
            _buildLoading()
          else if (_errorMessage != null)
            _buildError()
          else
            _buildContent(),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF378ADD),
            strokeWidth: 2.5,
          ),
          const SizedBox(height: 16),
          Text(
            'טוען זמנים...',
            style: GoogleFonts.alef(
              fontSize: 16,
              color: const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 52, color: Colors.red[300]),
            const SizedBox(height: 14),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: GoogleFonts.alef(fontSize: 15, color: Colors.red[700]),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _initializeZmanim,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text('נסה שוב', style: GoogleFonts.alef()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final topSpacing = MediaQuery.of(context).padding.top + kToolbarHeight + 12;

    return RefreshIndicator(
      onRefresh: _initializeZmanim,
      color: const Color.fromARGB(255, 15, 17, 18),
      child: ListView(
        padding: EdgeInsets.only(
          top: topSpacing,
          bottom: 24,
          left: 16,
          right: 16,
        ),
        children: [
          // ─── כרטיס תאריך עברי ───
          if (_jewishCalendar != null && _hebrewFormatter != null) ...[
            _DateCard(
              hebrewDate: _hebrewFormatter!.format(_jewishCalendar!),
              locationName: _locationName,
            ),
            const SizedBox(height: 16),
          ],

          // ─── קטגוריה: בוקר ───
          _SectionHeader(title: 'בוקר'),
          const SizedBox(height: 6),
          _ZmanTile(
            title: 'עלות השחר',
            subtitle: '72 דקות לפני הנץ',
            time: _formatTime(_zmanimCalendar?.getAlos72()),
            icon: Icons.nightlight_round,
            accentColor: const Color(0xFF534AB7),
          ),
          _ZmanTile(
            title: 'הנץ החמה',
            time: _formatTime(_zmanimCalendar?.getSunrise()),
            icon: Icons.wb_sunny_rounded,
            accentColor: const Color(0xFFBA7517),
          ),
          _ZmanTile(
            title: 'סוף זמן ק"ש (גר"א)',
            time: _formatTime(_zmanimCalendar?.getSofZmanShmaGRA()),
            icon: Icons.menu_book_rounded,
            accentColor: const Color(0xFF185FA5),
          ),
          _ZmanTile(
            title: 'סוף זמן תפילה (גר"א)',
            time: _formatTime(_zmanimCalendar?.getSofZmanTfilaGRA()),
            icon: Icons.access_time_rounded,
            accentColor: const Color(0xFF0F6E56),
          ),

          const SizedBox(height: 14),

          // ─── קטגוריה: צהריים ───
          _SectionHeader(title: 'צהריים'),
          const SizedBox(height: 6),
          _ZmanTile(
            title: 'חצות היום',
            time: _formatTime(_zmanimCalendar?.getChatzos()),
            icon: Icons.wb_twilight_rounded,
            accentColor: const Color(0xFF854F0B),
          ),
          _ZmanTile(
            title: 'מנחה גדולה',
            time: _formatTime(_zmanimCalendar?.getMinchaGedola()),
            icon: Icons.wb_cloudy_rounded,
            accentColor: const Color(0xFF185FA5),
          ),
          _ZmanTile(
            title: 'מנחה קטנה',
            time: _formatTime(_zmanimCalendar?.getMinchaKetana()),
            icon: Icons.cloud_rounded,
            accentColor: const Color(0xFF1D9E75),
          ),
          _ZmanTile(
            title: 'פלג המנחה',
            time: _formatTime(_zmanimCalendar?.getPlagHamincha()),
            icon: Icons.cloud_queue_rounded,
            accentColor: const Color(0xFF0F6E56),
          ),

          const SizedBox(height: 14),

          // ─── קטגוריה: ערב ───
          _SectionHeader(title: 'ערב'),
          const SizedBox(height: 6),
          _ZmanTile(
            title: 'שקיעה',
            time: _formatTime(_zmanimCalendar?.getSunset()),
            icon: Icons.wb_twilight_rounded,
            accentColor: const Color(0xFF993C1D),
          ),
          // צאת הכוכבים הרגיל — getTzais() = 8.5 מעלות (לא צאת שבת/חג)
          _ZmanTile(
            title: 'צאת הכוכבים',
            subtitle: '8.5 מעלות',
            time: _formatTime(_zmanimCalendar?.getTzais()),
            icon: Icons.nights_stay_rounded,
            accentColor: const Color(0xFF3C3489),
          ),
          _ZmanTile(
            title: 'חצות הלילה',
            time: _formatTime(_zmanimCalendar?.getSolarMidnight()),
            icon: Icons.bedtime_rounded,
            accentColor: const Color(0xFF26215C),
          ),

          const SizedBox(height: 16),

          // ─── הערה ───
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFEF9F27).withValues(alpha: 0.4),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 17,
                  color: Color(0xFFBA7517),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'הזמנים מחושבים לפי המיקום שלך',
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.alef(
                      fontSize: 13,
                      color: const Color(0xFF854F0B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// כרטיס תאריך עברי
// ─────────────────────────────────────────────
class _DateCard extends StatelessWidget {
  final String hebrewDate;
  final String locationName;

  const _DateCard({required this.hebrewDate, required this.locationName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 0.8,
        ),
      ),
      child: Column(
        children: [
          Text(
            hebrewDate,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.alef(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 14,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 4),
              Text(
                locationName,
                style: GoogleFonts.alef(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// כותרת קטגוריה
// ─────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4, bottom: 2),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xFF378ADD),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.alef(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF475569),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// שורת זמן
// ─────────────────────────────────────────────
class _ZmanTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String time;
  final IconData icon;
  final Color accentColor;

  const _ZmanTile({
    required this.title,
    required this.time,
    required this.icon,
    required this.accentColor,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.06),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          // שעה
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              time,
              style: GoogleFonts.alef(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: accentColor,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // שם + תת-כותרת
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.alef(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.alef(
                      fontSize: 12,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // אייקון
          Icon(icon, size: 20, color: accentColor.withValues(alpha: 0.7)),
        ],
      ),
    );
  }
}
