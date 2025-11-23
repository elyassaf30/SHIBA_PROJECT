import 'package:flutter/material.dart';
import 'package:rabbi_shiba/screens/shabat_screen.dart';
import 'package:rabbi_shiba/screens/moadi_israel_screen.dart';
import 'package:rabbi_shiba/screens/general_detail_screen.dart';
import 'package:rabbi_shiba/screens/week_day_tefilot_screen .dart';
import 'package:rabbi_shiba/screens/chet_screen.dart';
import 'package:rabbi_shiba/screens/user_to_synagogue_map.dart';
import 'package:rabbi_shiba/screens/shabbat_screen.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rabbi_shiba/screens/entrance_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showShabbatBanner = false;
  String? _cachedParashaName; // קאש לשם הפרשה

  // העברת הגדרת הבועות לקבוע כדי למנוע יצירה מחדש
  static final List<Map<String, dynamic>> _bubbles = [
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
    _initializeScreen();
  }

  // איחוד של כל ההכנות הדרושות בפונקציה אחת
  void _initializeScreen() {
    print('Initializing HomeScreen...');
    _showShabbatBanner = DateTime.now().weekday == 5;
    print('Show Shabbat banner: $_showShabbatBanner');

    // טעינת הפרשה רק אם צריך
    if (_showShabbatBanner) {
      _fetchAndCacheParashaName();
    }
  }

  Future<void> _fetchAndCacheParashaName() async {
    if (_cachedParashaName != null) return; // שימוש בקאש

    print('Fetching parasha name...');
    try {
      final supabase = Supabase.instance.client;
      final response =
          await supabase
              .from('shabbat_times')
              .select('parasha_name')
              .limit(1)
              .maybeSingle();

      if (response != null && response['parasha_name'] != null) {
        _cachedParashaName = response['parasha_name'] as String;
        print('Parasha name fetched: $_cachedParashaName');
        if (mounted) setState(() {});
      }
    } catch (e) {
      // טיפול בשגיאה בשקט
      print('Error fetching parasha name: $e');
    }
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            iconSize: 30,
            tooltip: 'חזרה למסך הראשי',
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EntranceScreen()),
                ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'כשרות דת והלכה',
                style: GoogleFonts.alef(
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                  color: Colors.black,
                  shadows: [
                    Shadow(
                      blurRadius: 5,
                      color: Colors.black45,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 4),
              Text(
                'מרכז רפואי שיבא תל השומר',
                style: GoogleFonts.rubikDirt(
                  fontSize: 16,
                  color: Colors.black,
                  shadows: [
                    Shadow(
                      blurRadius: 3,
                      color: Colors.black45,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildShabbatBanner() {
    if (!_showShabbatBanner) return SizedBox.shrink();

    final parashaName = _cachedParashaName ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: GestureDetector(
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ShabbatScreen()),
            ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4A3A3A), Color(0xFF3B2C2C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: Colors.amber.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          child: Row(
            children: [
              Icon(Icons.line_weight, color: Colors.amber[200], size: 28),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'זמני שבת ${parashaName.isNotEmpty ? parashaName + " " : ""}',
                      style: GoogleFonts.secularOne(
                        color: Colors.amber[100],
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'לחצו לצפייה בזמני כניסת ויציאת שבת',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              Icon(Icons.arrow_downward, color: Colors.amber[200], size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    // תמיד רקע כחול גרדיאנט - ללא תלות בטעינת תמונה
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB), Color(0xFF90CAF9)],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bubbleSize = screenWidth / 3.5;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // רקע כחול תמיד
          Positioned.fill(child: _buildBackground()),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                _buildShabbatBanner(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 16,
                          runSpacing: 16,
                          children: List.generate(_bubbles.length, (index) {
                            final bubble = _bubbles[index];
                            return _AnimatedBubbleItem(
                              key: ValueKey(bubble['label']), // key לביצועים
                              label: bubble['label'],
                              icon: bubble['icon'],
                              color: bubble['color'],
                              size: bubbleSize,
                              onTap:
                                  () => Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder:
                                          (_, animation, __) =>
                                              bubble['screenBuilder'](),
                                      transitionsBuilder:
                                          (_, animation, __, child) =>
                                              FadeTransition(
                                                opacity: animation,
                                                child: child,
                                              ),
                                      transitionDuration: Duration(
                                        milliseconds: 300,
                                      ),
                                    ),
                                  ),
                              delay: Duration(milliseconds: 50 * index),
                            );
                          }),
                        ),
                      ),
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

class _AnimatedBubbleItem extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;
  final Duration delay;

  const _AnimatedBubbleItem({
    Key? key,
    required this.label,
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
    this.delay = Duration.zero,
  }) : super(key: key);

  @override
  State<_AnimatedBubbleItem> createState() => _AnimatedBubbleItemState();
}

class _AnimatedBubbleItemState extends State<_AnimatedBubbleItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );

    _scale = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _opacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    // התחלת האנימציה מיד עם עיכוב קטן
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: FadeTransition(
        opacity: _opacity,
        child: ScaleTransition(
          scale: _scale,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.color.withOpacity(0.8),
                    widget.color.withOpacity(0.6),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 4,
                    offset: Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              padding: EdgeInsets.all(8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, size: 28, color: Colors.white),
                    SizedBox(height: 6),
                    Text(
                      widget.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                        shadows: [
                          Shadow(
                            blurRadius: 3,
                            offset: Offset(1, 1),
                            color: Colors.black,
                          ),
                        ],
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
  }
}
