import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WeekdayTefilotScreen extends StatefulWidget {
  @override
  _WeekdayTefilotScreenState createState() => _WeekdayTefilotScreenState();
}

class _WeekdayTefilotScreenState extends State<WeekdayTefilotScreen> {
  Map<String, List<Map<String, dynamic>>> groupedTefilot = {};
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
      await Future.wait([fetchTefilotData(), fetchTefilinInfo()]);
    } catch (e) {
      print('Error fetching data: $e');
    } finally {
      setState(() => isLoading = false);
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

  Color getColorForTefilaType(String type) {
    if (type.contains('שחרית')) return Colors.orange.shade700;
    if (type.contains('מנחה')) return Colors.blue.shade700;
    if (type.contains('ערבית')) return Colors.indigo.shade800;
    return Colors.grey.shade700;
  }

  Widget _buildBackground() {
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

  Widget _buildTefilaCard(String type, List<Map<String, dynamic>> tefilot) {
    final color = getColorForTefilaType(type);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(getIconForTefilaType(type), color: Colors.white, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    type,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Times list
          ...tefilot.asMap().entries.map((entry) {
            final index = entry.key;
            final tefila = entry.value;
            final note = tefila['הערות'] ?? '';
            final time = tefila['שעה'] ?? 'לא צוין שעה';
            final isLast = index == tefilot.length - 1;

            return Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom:
                      isLast
                          ? BorderSide.none
                          : BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.access_time, color: color, size: 16),
                        SizedBox(width: 6),
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Spacer(),
                  if (note.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder:
                              (_) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                title: Row(
                                  children: [
                                    Icon(Icons.info, color: color),
                                    SizedBox(width: 8),
                                    Text('הערה'),
                                  ],
                                ),
                                content: Text(
                                  note,
                                  textAlign: TextAlign.right,
                                  style: TextStyle(fontSize: 16),
                                ),
                                actions: [
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      foregroundColor: color,
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('סגור'),
                                  ),
                                ],
                              ),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.info_outline,
                          color: Colors.amber.shade700,
                          size: 18,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTefilinCard() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.brown.shade600, Colors.brown.shade800],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_stories, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'שאילת תפילין',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            tefilinInfo,
            style: TextStyle(fontSize: 16, color: Colors.white, height: 1.5),
            textAlign: TextAlign.right,
          ),
        ],
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
          'זמני תפילות - ימי חול',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black45,
                offset: Offset(1, 1),
                blurRadius: 3,
              ),
              Shadow(blurRadius: 10, color: Colors.black, offset: Offset(2, 2)),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: _buildBackground()),
          if (isLoading)
            Center(
              child: Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.deepPurple,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'טוען נתונים...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView(
              padding: EdgeInsets.fromLTRB(0, 100, 0, 32),
              children: [
                SizedBox(height: 8),
                ...groupedTefilot.entries.map(
                  (entry) => _buildTefilaCard(entry.key, entry.value),
                ),
                _buildTefilinCard(),
              ],
            ),
        ],
      ),
    );
  }
}
