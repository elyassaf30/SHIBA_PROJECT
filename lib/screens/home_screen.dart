import 'package:flutter/material.dart';
import 'package:rabbi_shiba/screens/shabat_screen.dart';
import 'package:rabbi_shiba/screens/moadi_israel_screen.dart';
import 'package:rabbi_shiba/screens/general_detail_screen.dart';
import 'package:rabbi_shiba/screens/week_day_tefilot_screen.dart';
import 'package:rabbi_shiba/screens/chet_screen.dart';
import 'package:rabbi_shiba/screens/user_to_synagogue_map.dart';
import 'package:rabbi_shiba/screens/zmanim_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rabbi_shiba/screens/entrance_screen.dart';
import 'package:rabbi_shiba/screens/AdminLoginScreen.dart';
import 'package:rabbi_shiba/screens/shabat_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Cached text styles to avoid recomputing each build
  late final TextStyle _titleStyle;
  late final TextStyle _subtitleStyle;

  // העברת הגדרת הבועות לקבוע כדי למנוע יצירה מחדש
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

    // Initialize and cache styles once to avoid per-build computation
    _titleStyle = GoogleFonts.alef(
      fontWeight: FontWeight.bold,
      fontSize: 28,
      color: Colors.black,
      shadows: [
        Shadow(blurRadius: 5, color: Colors.black45, offset: Offset(1, 1)),
      ],
    );

    _subtitleStyle = GoogleFonts.rubikDirt(
      fontSize: 16,
      color: Colors.black,
      shadows: [
        Shadow(blurRadius: 3, color: Colors.black45, offset: Offset(1, 1)),
      ],
    );

    // no Shabbat banner initialization
  }

  //

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
              Text('כשרות דת והלכה', style: _titleStyle),
              SizedBox(height: 4),
              Text('מרכז רפואי שיבא תל השומר', style: _subtitleStyle),
            ],
          ),
          SizedBox(width: 48),
        ],
      ),
    );
  }

  // Shabbat banner removed

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

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // רקע כחול תמיד
          Positioned.fill(child: _buildBackground()),
          SafeArea(
            child: Column(
              children: [
                GestureDetector(
                  child: _buildAppBar(), // כותרת
                ),
                // Shabbat banner removed
                Expanded(
                  child: Center(
                    // Center the content vertically when there are few bubbles
                    child: SingleChildScrollView(
                      physics: BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(8.0),
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final double spacing = 16.0;
                            final double availableWidth = constraints.maxWidth;
                            // scale down bubbles slightly
                            final double scale = 0.70;
                            final double baseItemSize =
                                (availableWidth - spacing) / 2;
                            final double itemSize = baseItemSize * scale;

                            return Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: spacing,
                              runSpacing: 16,
                              children: List.generate(_bubbles.length, (index) {
                                final bubble = _bubbles[index];
                                return _AnimatedBubbleItem(
                                  key: ValueKey(bubble['label']),
                                  label: bubble['label'],
                                  icon: bubble['icon'],
                                  color: bubble['color'],
                                  size: itemSize,
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
                            );
                          },
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

class _AnimatedBubbleItemState extends State<_AnimatedBubbleItem> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedOpacity(
        duration: Duration(milliseconds: 400),
        opacity: _visible ? 1.0 : 0.0,
        child: AnimatedScale(
          scale: _visible ? 1.0 : 0.85,
          duration: Duration(milliseconds: 450),
          curve: Curves.easeOutBack,
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
