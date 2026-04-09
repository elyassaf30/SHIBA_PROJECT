import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rabbi_shiba/services/data_service.dart';
import 'package:rabbi_shiba/utils/animation_helpers.dart';
import 'package:rabbi_shiba/utils/theme_helpers.dart';
import 'package:rabbi_shiba/widgets/state_widgets.dart';

class ShabatScreen extends StatefulWidget {
  const ShabatScreen({super.key});

  @override
  ShabatScreenState createState() => ShabatScreenState();
}

class ShabatScreenState extends State<ShabatScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> filteredData = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationHelpers.createFadeController(
      this,
      durationMs: 1000,
    );
    _fadeAnimation = AnimationHelpers.createFadeAnimation(
      _animationController,
      curve: Curves.easeInOut,
    );
    loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    try {
      final data = await DataService.fetchWithCache<List<Map<String, dynamic>>>(
        'shabatData',
        _fetchShabbatFromSupabase,
        cacheDuration: const Duration(hours: 1),
      );

      if (data != null) {
        setState(() {
          filteredData = data;
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<List<Map<String, dynamic>>?> _fetchShabbatFromSupabase() async {
    try {
      final response = await Supabase.instance.client.from('שבת').select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  IconData _getIconForShabat(String type) {
    if (type.toLowerCase().contains('תפילה')) return FontAwesomeIcons.wineGlass;
    if (type.toLowerCase().contains('שיעור')) return FontAwesomeIcons.bookOpen;
    return FontAwesomeIcons.wineGlass;
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
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 8, 8, 8)),
        title: Text(
          'מידע שבת',
          style: GoogleFonts.alef(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color.fromARGB(255, 17, 17, 17),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: ThemeHelpers.buildDefaultBackground()),
          FadeTransition(
            opacity: _fadeAnimation,
            child: StateBuilder(
              isLoading: _isLoading,
              hasError: filteredData.isEmpty && !_isLoading,
              contentBuilder: (_) => _buildContentList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentList() {
    if (filteredData.isEmpty) {
      return Center(
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
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 100, bottom: 24, left: 16, right: 16),
      itemCount: filteredData.length,
      itemBuilder: (context, index) {
        final item = filteredData[index];
        final info = item['מידע'] ?? '';
        final type = item['סוג'] ?? 'לא צוין סוג';

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _ShabatTile(
            key: ValueKey(item['סוג']),
            type: type,
            info: info,
            icon: _getIconForShabat(type),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// כרטיס שבת מורחב
// ─────────────────────────────────────────────
class _ShabatTile extends StatefulWidget {
  final String type;
  final String info;
  final IconData icon;

  const _ShabatTile({
    super.key,
    required this.type,
    required this.info,
    required this.icon,
  });

  @override
  State<_ShabatTile> createState() => _ShabatTileState();
}

class _ShabatTileState extends State<_ShabatTile>
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
                  const Spacer(),
                  // שם
                  Flexible(
                    child: Text(
                      widget.type,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.alef(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
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
