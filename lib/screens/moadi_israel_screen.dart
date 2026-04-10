import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rabbi_shiba/utils/theme_helpers.dart';

class MoadiIsraelScreen extends StatefulWidget {
  const MoadiIsraelScreen({super.key});

  @override
  _MoadiIsraelScreenState createState() => _MoadiIsraelScreenState();
}

class _MoadiIsraelScreenState extends State<MoadiIsraelScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> allData = [];
  List<Map<String, dynamic>> filteredData = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('moadiIsraelData');
    final cachedTime = prefs.getInt('moadiIsraelTime');

    if (cachedData != null && cachedTime != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - cachedTime < 3600000) {
        final decodedData = List<Map<String, dynamic>>.from(
          json.decode(cachedData),
        );
        setState(() {
          allData = decodedData;
          filteredData = decodedData;
          _isLoading = false;
        });
        _animationController.forward();
        return;
      }
    }
    await fetchMoadiIsraelData();
  }

  Future<void> fetchMoadiIsraelData() async {
    try {
      final response =
          await Supabase.instance.client.from('מועדי ישראל').select();
      final data = List<Map<String, dynamic>>.from(response);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('moadiIsraelData', json.encode(data));
      await prefs.setInt(
        'moadiIsraelTime',
        DateTime.now().millisecondsSinceEpoch,
      );

      setState(() {
        allData = data;
        filteredData = data;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  IconData _getIconForHoliday(String holidayName) {
    final name = holidayName.toLowerCase();
    if (name.contains('פסח')) return FontAwesomeIcons.breadSlice;
    if (name.contains('שבת')) return FontAwesomeIcons.solidStar;
    if (name.contains('ראש השנה')) return FontAwesomeIcons.appleAlt;
    if (name.contains('יום כיפור')) return FontAwesomeIcons.prayingHands;
    if (name.contains('סוכות')) return FontAwesomeIcons.campground;
    if (name.contains('חנוכה')) return FontAwesomeIcons.menorah;
    if (name.contains('פורים')) return FontAwesomeIcons.mask;
    if (name.contains('יום העצמאות')) return FontAwesomeIcons.flag;
    return FontAwesomeIcons.calendarDay;
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
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 18, 19, 23)),
        title: Text(
          'מועדי ישראל',
          style: GoogleFonts.alef(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color.fromARGB(255, 9, 10, 14),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: ThemeHelpers.buildDefaultBackground()),
          FadeTransition(
            opacity: _fadeAnimation,
            child:
                _isLoading
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            color: Color(0xFF378ADD),
                            strokeWidth: 2.5,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'טוען מועדים...',
                            style: GoogleFonts.alef(
                              fontSize: 15,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    )
                    : filteredData.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: const Color(0xFF94A3B8),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'לא נמצאו תוצאות',
                            style: GoogleFonts.alef(
                              fontSize: 17,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.only(
                        top: 100,
                        bottom: 24,
                        left: 16,
                        right: 16,
                      ),
                      itemCount: filteredData.length,
                      itemBuilder: (context, index) {
                        final item = filteredData[index];
                        final holidayName = item['סוג המועד'] ?? 'מועד';
                        final info = item['מידע'] ?? '';

                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _MoadTile(
                            key: ValueKey(item['סוג המועד']),
                            holidayName: holidayName,
                            info: info,
                            icon: _getIconForHoliday(holidayName),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// כרטיס מועד
// ─────────────────────────────────────────────
class _MoadTile extends StatefulWidget {
  final String holidayName;
  final String info;
  final IconData icon;

  const _MoadTile({
    super.key,
    required this.holidayName,
    required this.info,
    required this.icon,
  });

  @override
  State<_MoadTile> createState() => _MoadTileState();
}

class _MoadTileState extends State<_MoadTile>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _ctrl;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _expandAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // חץ
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 260),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 22,
                      color: Color(0xFF378ADD),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // שם המועד
                  Flexible(
                    child: Text(
                      widget.holidayName,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.alef(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // אייקון
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF534AB7).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: FaIcon(
                        widget.icon,
                        size: 17,
                        color: const Color(0xFF534AB7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── תוכן מורחב ───
          SizeTransition(
            sizeFactor: _expandAnim,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 0.8,
                    color: Colors.black.withValues(alpha: 0.07),
                    margin: const EdgeInsets.only(bottom: 12),
                  ),
                  Text(
                    widget.info,
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
            ),
          ),
        ],
      ),
    );
  }
}
