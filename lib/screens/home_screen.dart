import 'package:flutter/material.dart';
import 'package:rabbi_shiba/screens/shabat_screen.dart';
import 'package:rabbi_shiba/screens/moadi_israel_screen.dart';
import 'package:rabbi_shiba/screens/general_detail_screen.dart';
import 'package:rabbi_shiba/screens/week_day_tefilot_screen.dart';
import 'package:rabbi_shiba/screens/chet_screen.dart';
import 'package:rabbi_shiba/screens/user_to_synagogue_map.dart';
import 'package:rabbi_shiba/screens/zmanim_screen.dart';
import 'package:rabbi_shiba/screens/entrance_screen.dart';
import 'package:rabbi_shiba/utils/theme_helpers.dart';
import 'package:rabbi_shiba/widgets/card_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
              Text('כשרות דת והלכה', style: ThemeHelpers.titleStyle),
              SizedBox(height: 4),
              Text(
                'מרכז רפואי שיבא תל השומר',
                style: ThemeHelpers.subtitleStyle,
              ),
            ],
          ),
          SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return ThemeHelpers.buildDefaultBackground();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // רקע כחול
          Positioned.fill(child: _buildBackground()),
          SafeArea(
            child: Column(
              children: [
                GestureDetector(
                  child: _buildAppBar(), // כותרת
                ),
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
                                return AnimatedBubbleButton(
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
