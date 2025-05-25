import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WeekdayTefilotScreen extends StatefulWidget {
  @override
  _WeekdayTefilotScreenState createState() => _WeekdayTefilotScreenState();
}

class _WeekdayTefilotScreenState extends State<WeekdayTefilotScreen> {
  Map<String, List<Map<String, dynamic>>> groupedTefilot = {};
  String hebrewDateInfo = '';
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
      await Future.wait([
        fetchHebrewDateAndParasha(),
        fetchTefilotData(),
        fetchTefilinInfo(),
      ]);
    } catch (e) {
      print('Error fetching data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchHebrewDateAndParasha() async {
    try {
      final nowDate = DateTime.now();
      final formattedDate =
          '${nowDate.year}-${nowDate.month.toString().padLeft(2, '0')}-${nowDate.day.toString().padLeft(2, '0')}';

      final response = await http.get(
        Uri.parse(
          'https://www.hebcal.com/converter?cfg=json&date=$formattedDate&g2h=1',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final hebrewDate = data['hebrew'] ?? 'לא זמין';
        String parasha = 'לא זמין';

        if (data['events'] != null) {
          final events = List<String>.from(data['events']);
          parasha = events.firstWhere(
            (event) => event.startsWith('Parashat'),
            orElse: () => 'לא זמין',
          );
        }

        setState(() {
          hebrewDateInfo = 'תאריך עברי: $hebrewDate\n  $parasha :פרשת השבוע';
        });
      } else {
        setState(() {
          hebrewDateInfo = 'שגיאה: ה-API החזיר קוד ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(
        () => hebrewDateInfo = 'שגיאה: לא ניתן לטעון תאריך עברי. נסה שוב.',
      );
      debugPrint('שגיאה ב-fetchHebrewDateAndParasha: $e');
    }
  }

  Future<void> fetchTefilotData() async {
    try {
      final response =
          await Supabase.instance.client.from('זמני תפילות ימי חול').select();

      final data = List<Map<String, dynamic>>.from(response);
      Map<String, List<Map<String, dynamic>>> grouped = {};

      // Group tefilot by type
      for (var tefila in data) {
        final type = tefila['סוג תפילה'] ?? 'לא ידוע';
        if (!grouped.containsKey(type)) {
          grouped[type] = [];
        }
        grouped[type]!.add(tefila);
      }

      // Sort each group by time ascending
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

      // Sort the groups by predefined order: שחרית, מנחה, ערבית
      final List<String> tefilaOrder = ['שחרית', 'מנחה', 'ערבית'];
      Map<String, List<Map<String, dynamic>>> sortedGrouped = {
        for (var type in tefilaOrder)
          if (grouped.containsKey(type)) type: grouped[type]!,
      };

      setState(() => groupedTefilot = sortedGrouped);
    } catch (e) {
      print('Error fetching tefilot data: $e');
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

      final info = response['מידע'] ?? 'אין מידע זמין על שאילת תפילין';

      setState(() {
        tefilinInfo = info;
      });
    } catch (e) {
      setState(() => tefilinInfo = 'לא ניתן לטעון מידע על תפילין');
      print('Error fetching tefilin info: $e');
    }
  }

  IconData getIconForTefilaType(String type) {
    if (type.contains('שחרית')) return Icons.wb_sunny;
    if (type.contains('מנחה')) return Icons.wb_cloudy;
    if (type.contains('ערבית')) return Icons.nights_stay;
    return Icons.access_time;
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
          'זמני תפילות - ימי חול',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/siba4.png', fit: BoxFit.cover),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey.withOpacity(0.5),
                  Colors.grey.withOpacity(0.4),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          isLoading
              ? Center(child: CircularProgressIndicator())
              : ListView(
                padding: EdgeInsets.fromLTRB(16, 100, 16, 32),
                children: [
                  // Hebrew date and parasha section
                  Container(
                    margin: EdgeInsets.only(bottom: 16),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue, width: 2),
                    ),
                    child: Text(
                      hebrewDateInfo,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  // Tefilot times
                  ...groupedTefilot.keys.map((type) {
                    final tefilot = groupedTefilot[type]!;
                    return Container(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: [
                            Colors.deepPurple.shade400.withOpacity(0.9),
                            Colors.deepPurple.shade700.withOpacity(0.9),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(2, 4),
                          ),
                        ],
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                          splashColor: Colors.white24,
                          highlightColor: Colors.white10,
                        ),
                        child: ExpansionTile(
                          leading: Icon(
                            getIconForTefilaType(type),
                            color: Colors.white,
                          ),
                          title: Text(
                            type,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                          iconColor: Colors.white,
                          collapsedIconColor: Colors.white,
                          children:
                              tefilot.map((tefila) {
                                final note = tefila['הערות'] ?? '';
                                final time = tefila['שעה'] ?? 'לא צוין שעה';

                                return Container(
                                  margin: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white30,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Time
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            time,
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Note icon (if exists)
                                      if (note.isNotEmpty)
                                        Tooltip(
                                          message: note,
                                          decoration: BoxDecoration(
                                            color: Colors.black87,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          textStyle: TextStyle(
                                            color: Colors.white,
                                          ),
                                          child: IconButton(
                                            icon: Icon(
                                              Icons.info_outline,
                                              color: Colors.amberAccent,
                                            ),
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder:
                                                    (_) => AlertDialog(
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              20,
                                                            ),
                                                      ),
                                                      backgroundColor:
                                                          Colors.white,
                                                      title: Row(
                                                        children: [
                                                          Icon(
                                                            Icons.info,
                                                            color:
                                                                Colors
                                                                    .deepPurple,
                                                          ),
                                                          SizedBox(width: 8),
                                                          Text('הערה'),
                                                        ],
                                                      ),
                                                      content: Text(
                                                        note,
                                                        textAlign:
                                                            TextAlign.right,
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed:
                                                              () =>
                                                                  Navigator.pop(
                                                                    context,
                                                                  ),
                                                          child: Text('סגור'),
                                                        ),
                                                      ],
                                                    ),
                                              );
                                            },
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                    );
                  }).toList(),

                  // Tefilin info section
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.brown.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            ':שאילת תפילין',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          tefilinInfo,
                          style: TextStyle(fontSize: 16, color: Colors.white),
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        ],
      ),
    );
  }
}
