import 'package:flutter/material.dart';
import 'package:rabbi_shiba/screens/shabat_screen.dart';
import 'package:rabbi_shiba/screens/moadi_israel_screen.dart';
import 'package:rabbi_shiba/screens/general_detail_screen.dart';
import 'package:rabbi_shiba/screens/week_day_tefilot_screen .dart';
import 'package:rabbi_shiba/screens/chet_screen.dart';
import 'package:rabbi_shiba/screens/user_to_synagogue_map.dart';
import 'package:flutter/scheduler.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();

    // Trigger fade-in animation when the screen loads
    SchedulerBinding.instance.addPostFrameCallback((_) {
      precacheImage(AssetImage('assets/siba4.png'), context).then((_) {
        if (mounted) {
          // אנימציה חלקה יותר עם delay
          Future.delayed(Duration(milliseconds: 300), () {
            setState(() {
              _opacity = 1.0;
            });
          });
        }
      });
    });
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
      body: AnimatedOpacity(
        opacity: _opacity,
        duration: Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        child: Stack(
          children: [
            // רקע תמונה
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
                  // כותרת עם אנימציות
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        SlideTransition(
                          position: Tween<Offset>(
                            begin: Offset(0, -0.5),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: ModalRoute.of(context)!.animation!,
                              curve: Curves.easeOutQuart,
                            ),
                          ),
                          child: FadeTransition(
                            opacity: ModalRoute.of(context)!.animation!,
                            child: Text(
                              'כשרות דת והלכה',
                              style: GoogleFonts.alef(
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    blurRadius: 5,
                                    color: Colors.black45,
                                    offset: Offset(1, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 4),
                        SlideTransition(
                          position: Tween<Offset>(
                            begin: Offset(0, -0.3),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: ModalRoute.of(context)!.animation!,
                              curve: Curves.easeOutQuart,
                            ),
                          ),
                          child: FadeTransition(
                            opacity: ModalRoute.of(context)!.animation!,
                            child: Text(
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
                          ),
                        ),
                      ],
                    ),
                  ),

                  // בועות עם אנימציות מדורגות
                  Expanded(
                    child: SingleChildScrollView(
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
                                        MaterialPageRoute(
                                          builder:
                                              (context) => bubble['screen'],
                                        ),
                                      );
                                    },
                                    delay: Duration(milliseconds: 100 * index),
                                  );
                                }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // טקסט תחתון עם אנימציה
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(0, 0.5),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: ModalRoute.of(context)!.animation!,
                        curve: Curves.easeOutQuart,
                      ),
                    ),
                    child: FadeTransition(
                      opacity: ModalRoute.of(context)!.animation!,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(),
                                  ),
                                );
                              },
                              child: FaIcon(
                                FontAwesomeIcons.whatsapp,
                                size: 30,
                                color: Colors.green[800]!.withOpacity(0.7),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '* באם יש משהו לא ברור מספיק ניתן להתכתב עם רב המרכז הרפואי בענין.',
                                style: GoogleFonts.notoRashiHebrew(
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
                                textDirection: TextDirection.rtl,
                              ),
                            ),
                          ],
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

/// בועה עם אנימציות משופרות
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
      duration: Duration(milliseconds: 800),
    );

    // אנימציית קפיצה חלקה
    _scale = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    // אנימציית שקיפות
    _opacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    // התחלת האנימציה לאחר delay
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
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
