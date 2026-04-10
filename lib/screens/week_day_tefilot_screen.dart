import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rabbi_shiba/utils/theme_helpers.dart';

class WeekdayTefilotScreen extends StatefulWidget {
  const WeekdayTefilotScreen({super.key});

  @override
  _WeekdayTefilotScreenState createState() => _WeekdayTefilotScreenState();
}

class _WeekdayTefilotScreenState extends State<WeekdayTefilotScreen> {
  Map<String, List<Map<String, dynamic>>> groupedTefilot = {};
  String tefilinInfo = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAllData();
  }

  Future<void> fetchAllData() async {
    setState(() => isLoading = true);
    try {
      await Future.wait([fetchTefilotData(), fetchTefilinInfo()]);
    } catch (e) {
      debugPrint('Error fetching data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchTefilotData() async {
    try {
      final response =
          await Supabase.instance.client.from('זמני תפילות ימי חול').select();

      final data = List<Map<String, dynamic>>.from(response);
      Map<String, List<Map<String, dynamic>>> grouped = {};

      for (var tefila in data) {
        final type = tefila['סוג תפילה'] ?? 'לא ידוע';
        if (!grouped.containsKey(type)) grouped[type] = [];
        grouped[type]!.add(tefila);
      }

      grouped.forEach((key, value) {
        value.sort((a, b) {
          final timeA = a['שעה'] ?? '';
          final timeB = b['שעה'] ?? '';
          try {
            final parsedA = TimeOfDay(
              hour: int.parse(timeA.split(':')[0]),
              minute: int.parse(timeA.split(':')[1]),
            );
            final parsedB = TimeOfDay(
              hour: int.parse(timeB.split(':')[0]),
              minute: int.parse(timeB.split(':')[1]),
            );
            return parsedA.hour != parsedB.hour
                ? parsedA.hour.compareTo(parsedB.hour)
                : parsedA.minute.compareTo(parsedB.minute);
          } catch (_) {
            return 0;
          }
        });
      });

      final List<String> tefilaOrder = ['שחרית', 'מנחה', 'ערבית'];
      Map<String, List<Map<String, dynamic>>> sortedGrouped = {
        for (var type in tefilaOrder)
          if (grouped.containsKey(type)) type: grouped[type]!,
      };

      setState(() => groupedTefilot = sortedGrouped);
    } catch (e) {
      debugPrint('Error fetching tefilot data: $e');
    }
  }

  Future<void> fetchTefilinInfo() async {
    try {
      final response =
          await Supabase.instance.client
              .from('כללי')
              .select('מידע')
              .eq('סוג', 'שאילת תפילין')
              .single();
      setState(
        () => tefilinInfo = response['מידע'] ?? 'אין מידע זמין על שאילת תפילין',
      );
    } catch (e) {
      setState(() => tefilinInfo = 'לא ניתן לטעון מידע על תפילין');
      debugPrint('Error fetching tefilin info: $e');
    }
  }

  IconData getIconForTefilaType(String type) {
    if (type.contains('שחרית')) return Icons.wb_sunny_rounded;
    if (type.contains('מנחה')) return Icons.wb_cloudy_rounded;
    if (type.contains('ערבית')) return Icons.nights_stay_rounded;
    return Icons.access_time_rounded;
  }

  // צבע accent לכל תפילה
  Color getColorForTefilaType(String type) {
    if (type.contains('שחרית')) return const Color(0xFFBA7517);
    if (type.contains('מנחה')) return const Color(0xFF185FA5);
    if (type.contains('ערבית')) return const Color(0xFF3C3489);
    return const Color(0xFF475569);
  }

  void _showNoteDialog(String note, Color color) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  'הערה',
                  style: GoogleFonts.alef(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            content: Text(
              note,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: GoogleFonts.alef(fontSize: 15, height: 1.7),
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(foregroundColor: color),
                onPressed: () => Navigator.pop(context),
                child: Text('סגור', style: GoogleFonts.alef()),
              ),
            ],
          ),
    );
  }

  Widget _buildTefilaCard(String type, List<Map<String, dynamic>> tefilot) {
    final color = getColorForTefilaType(type);
    final icon = getIconForTefilaType(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.06),
          width: 0.8,
        ),
      ),
      child: Column(
        children: [
          // ─── כותרת ───
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(
                  color: color.withValues(alpha: 0.15),
                  width: 0.8,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 19),
                ),
                const Spacer(),
                Text(
                  type,
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.alef(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),

          // ─── רשימת שעות ───
          ...tefilot.asMap().entries.map((entry) {
            final index = entry.key;
            final tefila = entry.value;
            final note = tefila['הערות'] ?? '';
            final time = tefila['שעה'] ?? 'לא צוין שעה';
            final displayTime = time.length >= 5 ? time.substring(0, 5) : time;
            final isLast = index == tefilot.length - 1;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom:
                      isLast
                          ? BorderSide.none
                          : BorderSide(
                            color: Colors.black.withValues(alpha: 0.05),
                            width: 0.8,
                          ),
                ),
              ),
              child: Row(
                children: [
                  // כפתור הערה
                  if (note.isNotEmpty)
                    GestureDetector(
                      onTap: () => _showNoteDialog(note, color),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAEEDA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFFBA7517),
                          size: 16,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 30),

                  const Spacer(),

                  // שעה
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      displayTime,
                      style: GoogleFonts.alef(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTefilinCard() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.06),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // כותרת
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF633806).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: Color(0xFF633806),
                  size: 19,
                ),
              ),
              const Spacer(),
              Text(
                'שאילת תפילין',
                textDirection: TextDirection.rtl,
                style: GoogleFonts.alef(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF633806),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(height: 0.8, color: Colors.black.withValues(alpha: 0.07)),
          const SizedBox(height: 10),
          Text(
            tefilinInfo,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: GoogleFonts.alef(
              fontSize: 14,
              height: 1.8,
              color: const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
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
        flexibleSpace: ThemeHelpers.buildDefaultBackground(),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 6, 6, 6)),
        title: Text(
          'זמני תפילות — ימי חול',
          style: GoogleFonts.alef(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: const Color.fromARGB(255, 7, 7, 7),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: ThemeHelpers.buildDefaultBackground()),
          if (isLoading)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: Color(0xFF378ADD),
                    strokeWidth: 2.5,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'טוען נתונים...',
                    style: GoogleFonts.alef(
                      fontSize: 15,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 100, 16, 32),
              children: [
                _buildTefilinCard(),
                const SizedBox(height: 4),
                ...groupedTefilot.entries.map(
                  (entry) => _buildTefilaCard(entry.key, entry.value),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
