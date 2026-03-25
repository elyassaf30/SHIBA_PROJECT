import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
      // ׳‘׳“׳™׳§׳” ׳׳ ׳¢׳‘׳¨׳• ׳₪׳—׳•׳× ׳׳©׳¢׳” (3600000 ׳׳™׳׳™׳©׳ ׳™׳•׳×)
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
    // ׳׳ ׳׳™׳ ׳§׳׳© ׳׳• ׳©׳¢׳‘׳¨׳” ׳©׳¢׳”, ׳ ׳˜׳¢׳ ׳׳—׳“׳© ׳׳”׳©׳¨׳×
    await fetchMoadiIsraelData();
  }

  Future<void> fetchMoadiIsraelData() async {
    try {
      final response =
          await Supabase.instance.client.from('׳׳•׳¢׳“׳™ ׳™׳©׳¨׳׳').select();
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
    if (name.contains('׳₪׳¡׳—')) return FontAwesomeIcons.breadSlice;
    if (name.contains('׳©׳‘׳×')) return FontAwesomeIcons.solidStar;
    if (name.contains('׳¨׳׳© ׳”׳©׳ ׳”')) return FontAwesomeIcons.appleAlt;
    if (name.contains('׳™׳•׳ ׳›׳™׳₪׳•׳¨')) return FontAwesomeIcons.prayingHands;
    if (name.contains('׳¡׳•׳›׳•׳×')) return FontAwesomeIcons.campground;
    if (name.contains('׳—׳ ׳•׳›׳”')) return FontAwesomeIcons.menorah;
    if (name.contains('׳₪׳•׳¨׳™׳')) return FontAwesomeIcons.mask;
    if (name.contains('׳™׳•׳ ׳”׳¢׳¦׳׳׳•׳×')) return FontAwesomeIcons.flag;
    return FontAwesomeIcons.calendarDay;
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
          '׳׳•׳¢׳“׳™ ׳™׳©׳¨׳׳',
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
              colors: [Colors.deepPurple.withValues(alpha: 0.7), Colors.transparent],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // ׳¨׳§׳¢ ׳¢׳ ׳׳₪׳§׳˜
          Positioned.fill(child: ThemeHelpers.buildDefaultBackground()),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.1),
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
                                  '׳׳ ׳ ׳׳¦׳׳• ׳×׳•׳¦׳׳•׳×',
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
                              final holidayName = item['׳¡׳•׳’ ׳”׳׳•׳¢׳“'] ?? '׳׳•׳¢׳“';
                              final info = item['׳׳™׳“׳¢'] ?? '';
                              final shouldExpand = false;

                              return AnimatedSwitcher(
                                duration: Duration(milliseconds: 300),
                                child: Card(
                                  key: ValueKey(item['׳¡׳•׳’ ׳”׳׳•׳¢׳“']),
                                  margin: EdgeInsets.only(bottom: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: 5,
                                  color: Colors.deepPurple.withValues(alpha: 0.8),
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

