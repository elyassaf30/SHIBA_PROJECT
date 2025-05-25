import 'package:flutter/material.dart';
import 'package:rabbi_shiba/screens/shabat_screen.dart';
import 'package:rabbi_shiba/screens/moadi_israel_screen.dart';
import 'package:rabbi_shiba/screens/general_detail_screen.dart';
import 'package:rabbi_shiba/screens/week_day_tefilot_screen .dart';
import 'package:rabbi_shiba/screens/chet_screen.dart';
import 'package:rabbi_shiba/screens/user_to_synagogue_map.dart';
import 'package:rabbi_shiba/screens/shabbat_screen.dart'; // ← הוספתי את מסך יום שישי
import 'package:flutter/scheduler.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rabbi_shiba/screens/entrance_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _opacity = 0.0;
  bool _isImageLoaded = false;
  bool _showShabbatBanner = false;

  @override
  void initState() {
    super.initState();

    // אם היום הוא שישי – ניווט ישיר למסך יום שישי
    if (DateTime.now().weekday == 5) {
      _showShabbatBanner = true; // it's Friday
    }
    _loadBackgroundImage(); // תמיד טען רקע
  }

  Future<void> _loadBackgroundImage() async {
    try {
      final imageProvider = AssetImage('assets/siba4.png');
      await precacheImage(imageProvider, context);

      if (mounted) {
        setState(() {
          _isImageLoaded = true;
        });

        Future.delayed(Duration(milliseconds: 100), () {
          if (mounted) {
            setState(() {
              _opacity = 1.0;
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isImageLoaded = true;
          _opacity = 1.0;
        });
      }
    }
  }

  Future<String?> fetchParashaName() async {
    final supabase = Supabase.instance.client;

    final response =
        await supabase
            .from('shabbat_times')
            .select('parasha_name')
            .limit(1)
            .maybeSingle(); // מחזיר רק רשומה אחת או null

    if (response != null && response['parasha_name'] != null) {
      return response['parasha_name'] as String;
    } else {
      return null;
    }
  }

  final List<Map<String, dynamic>> bubbles = [
    {
      'label': 'שבת',
      'icon': Icons.wine_bar,
      'color': Colors.indigo,
      'screen': ShabatScreen(),
    },
    {
      'label': 'כשרות',
      'icon': Icons.food_bank,
      'color': Colors.green,
      'screen': GeneralDetailScreen(type: 'כשרות'),
    },
    {
      'label': 'בתי כנסת במרכז הרפואי',
      'icon': Icons.location_on,
      'color': Colors.orange,
      'screen': UserToSynagogueMap(),
    },
    {
      'label': 'זמני תפילות ימי חול',
      'icon': Icons.access_time,
      'color': Colors.blue,
      'screen': WeekdayTefilotScreen(),
    },
    {
      'label': 'טומאת כהנים',
      'icon': Icons.people,
      'color': Colors.brown,
      'screen': GeneralDetailScreen(type: 'טומאת כהנים'),
    },
    {
      'label': 'נפטרים',
      'icon': Icons.help_outline,
      'color': Colors.grey,
      'screen': GeneralDetailScreen(type: 'נפטרים'),
    },
    {
      'label': 'מקווה',
      'icon': Icons.water,
      'color': Colors.blueAccent,
      'screen': GeneralDetailScreen(type: 'מקווה'),
    },
    {
      'label': 'מועדי ישראל',
      'icon': Icons.calendar_today,
      'color': Colors.purple,
      'screen': MoadiIsraelScreen(),
    },
    {
      'label': 'ייעוץ הלכתי רפואי',
      'icon': Icons.medical_services,
      'color': Colors.teal,
      'screen': ChatScreen(),
    },
    {
      'label': 'אנשי קשר',
      'icon': Icons.contacts,
      'color': Colors.redAccent,
      'screen': GeneralDetailScreen(type: 'אנשי קשר'),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bubbleSize = screenWidth / 3.5;

    return Scaffold(
      extendBodyBehindAppBar: true,
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: AnimatedOpacity(
        opacity: _opacity,
        duration: Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        child: Stack(
          children: [
            if (_isImageLoaded)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/siba4.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(color: Colors.grey.withOpacity(0.3)),
                ),
              ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back, color: Colors.black),
                          iconSize: 30,
                          tooltip: 'חזרה למסך הראשי',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EntranceScreen(),
                              ),
                            );
                          },
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            AnimatedDefaultTextStyle(
                              duration: Duration(milliseconds: 500),
                              style: GoogleFonts.alef(
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                                color:
                                    _isImageLoaded
                                        ? Colors.white
                                        : Colors.transparent,
                                shadows:
                                    _isImageLoaded
                                        ? [
                                          Shadow(
                                            blurRadius: 5,
                                            color: Colors.black45,
                                            offset: Offset(1, 1),
                                          ),
                                        ]
                                        : [],
                              ),
                              child: Text('כשרות דת והלכה'),
                            ),
                            SizedBox(height: 4),
                            AnimatedDefaultTextStyle(
                              duration: Duration(milliseconds: 500),
                              style: GoogleFonts.rubikDirt(
                                fontSize: 16,
                                color:
                                    _isImageLoaded
                                        ? Colors.black
                                        : Colors.transparent,
                                shadows:
                                    _isImageLoaded
                                        ? [
                                          Shadow(
                                            blurRadius: 3,
                                            color: Colors.black45,
                                            offset: Offset(1, 1),
                                          ),
                                        ]
                                        : [],
                              ),
                              child: Text('מרכז רפואי שיבא תל השומר'),
                            ),
                          ],
                        ),
                        SizedBox(
                          width: 48,
                        ), // מרווח כדי לאזן את הכפתור בצד שמאל
                      ],
                    ),
                  ),

                  if (_showShabbatBanner)
                    FutureBuilder<String?>(
                      future: fetchParashaName(),
                      builder: (context, snapshot) {
                        final parashaName = snapshot.data ?? '';
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 10.0,
                          ),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ShabbatScreen(),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF4A3A3A),
                                    Color(0xFF3B2C2C),
                                  ],
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
                              padding: EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 18,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.line_weight, // אייקון נרות שבת
                                    color: Colors.amber[200],
                                    size: 28,
                                  ),
                                  SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
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
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Icon(
                                    Icons.arrow_downward,
                                    color: Colors.amber[200],
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
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
                            children:
                                bubbles.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final bubble = entry.value;
                                  return _AnimatedBubbleItem(
                                    label: bubble['label'],
                                    icon: bubble['icon'],
                                    color: bubble['color'],
                                    size: bubbleSize,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          pageBuilder:
                                              (_, animation, __) =>
                                                  bubble['screen'],
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
                                      );
                                    },
                                    delay: Duration(milliseconds: 100 * index),
                                    isImageLoaded: _isImageLoaded,
                                  );
                                }).toList(),
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
  final bool isImageLoaded;

  const _AnimatedBubbleItem({
    Key? key,
    required this.label,
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
    this.delay = Duration.zero,
    required this.isImageLoaded,
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
      duration: Duration(milliseconds: 800),
    );

    _scale = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _opacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    // התחלת האנימציה רק לאחר שהתמונה טעונה ובהתאם לעיכוב
    if (widget.isImageLoaded) {
      Future.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedBubbleItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isImageLoaded && !oldWidget.isImageLoaded) {
      Future.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
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
    );
  }
}
