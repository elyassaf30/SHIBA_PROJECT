import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/animation.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MoadiIsraelScreen extends StatefulWidget {
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
      duration: Duration(milliseconds: 1000),
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
      // בדיקה אם עברו פחות משעה (3600000 מילישניות)
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
    // אם אין קאש או שעברה שעה, נטען מחדש מהשרת
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
      setState(() {
        _isLoading = false;
      });
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

  Widget _buildBackground() {
    // רקע חלופי אם יש בעיה עם התמונה
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
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'מועדי ישראל',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
            shadows: [
              Shadow(blurRadius: 10, color: Colors.black, offset: Offset(2, 2)),
            ],
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.deepPurple.withOpacity(0.7), Colors.transparent],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // רקע עם אפקט
          Positioned.fill(child: _buildBackground()),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.1),
                ],
              ),
            ),
          ),
          FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                SizedBox(height: 100),
                Expanded(
                  child:
                      _isLoading
                          ? Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : filteredData.isEmpty
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 50,
                                  color: Colors.white70,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'לא נמצאו תוצאות',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : ListView.builder(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            itemCount: filteredData.length,
                            itemBuilder: (context, index) {
                              final item = filteredData[index];
                              final holidayName = item['סוג המועד'] ?? 'מועד';
                              final info = item['מידע'] ?? '';
                              final shouldExpand = false;

                              return AnimatedSwitcher(
                                duration: Duration(milliseconds: 300),
                                child: Card(
                                  key: ValueKey(item['סוג המועד']),
                                  margin: EdgeInsets.only(bottom: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: 5,
                                  color: Colors.deepPurple.withOpacity(0.8),
                                  child: Theme(
                                    data: Theme.of(context).copyWith(
                                      dividerColor: Colors.transparent,
                                    ),
                                    child: ExpansionTile(
                                      initiallyExpanded: shouldExpand,
                                      leading: FaIcon(
                                        _getIconForHoliday(holidayName),
                                        color: Colors.white,
                                      ),
                                      title: Center(
                                        child: Text(
                                          holidayName,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                      iconColor: Colors.white,
                                      collapsedIconColor: Colors.white,
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Text(
                                            info,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              height: 1.6,
                                            ),
                                            textDirection: TextDirection.rtl,
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
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
