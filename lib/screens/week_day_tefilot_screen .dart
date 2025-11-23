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

  // מילון תרגום פרשיות מאנגלית לעברית
  final Map<String, String> parashaTranslations = {
    'Parashat Bereshit': 'פרשת בראשית',
    'Parashat Noach': 'פרשת נח',
    'Parashat Lech-Lecha': 'פרשת לך לך',
    'Parashat Vayera': 'פרשת וירא',
    'Parashat Chayei Sara': 'פרשת חיי שרה',
    'Parashat Toldot': 'פרשת תולדות',
    'Parashat Vayetzei': 'פרשת ויצא',
    'Parashat Vayishlach': 'פרשת וישלח',
    'Parashat Vayeshev': 'פרשת וישב',
    'Parashat Miketz': 'פרשת מקץ',
    'Parashat Vayigash': 'פרשת ויגש',
    'Parashat Vayechi': 'פרשת ויחי',
    'Parashat Shemot': 'פרשת שמות',
    'Parashat Vaera': 'פרשת וארא',
    'Parashat Bo': 'פרשת בא',
    'Parashat Beshalach': 'פרשת בשלח',
    'Parashat Yitro': 'פרשת יתרו',
    'Parashat Mishpatim': 'פרשת משפטים',
    'Parashat Terumah': 'פרשת תרומה',
    'Parashat Tetzaveh': 'פרשת תצוה',
    'Parashat Ki Tisa': 'פרשת כי תשא',
    'Parashat Vayakhel': 'פרשת ויקהל',
    'Parashat Pekudei': 'פרשת פקודי',
    'Parashat Vayikra': 'פרשת ויקרא',
    'Parashat Tzav': 'פרשת צו',
    'Parashat Shmini': 'פרשת שמיני',
    'Parashat Tazria': 'פרשת תזריע',
    'Parashat Metzora': 'פרשת מצורע',
    'Parashat Achrei Mot': 'פרשת אחרי מות',
    'Parashat Kedoshim': 'פרשת קדושים',
    'Parashat Emor': 'פרשת אמור',
    'Parashat Behar': 'פרשת בהר',
    'Parashat Bechukotai': 'פרשת בחוקתי',
    'Parashat Bamidbar': 'פרשת במדבר',
    'Parashat Nasso': 'פרשת נשא',
    'Parashat Beha\'alotcha': 'פרשת בהעלותך',
    'Parashat Sh\'lach': 'פרשת שלח לך',
    'Parashat Korach': 'פרשת קרח',
    'Parashat Chukat': 'פרשת חקת',
    'Parashat Balak': 'פרשת בלק',
    'Parashat Pinchas': 'פרשת פינחס',
    'Parashat Matot': 'פרשת מטות',
    'Parashat Masei': 'פרשת מסעי',
    'Parashat Devarim': 'פרשת דברים',
    'Parashat Vaetchanan': 'פרשת ואתחנן',
    'Parashat Eikev': 'פרשת עקב',
    'Parashat Re\'eh': 'פרשת ראה',
    'Parashat Shoftim': 'פרשת שופטים',
    'Parashat Ki Teitzei': 'פרשת כי תצא',
    'Parashat Ki Tavo': 'פרשת כי תבוא',
    'Parashat Nitzavim': 'פרשת נצבים',
    'Parashat Vayeilech': 'פרשת וילך',
    'Parashat Ha\'Azinu': 'פרשת האזינו',
    'Parashat V\'Zot HaBerachah': 'פרשת וזאת הברכה',
  };

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
          final englishParasha = events.firstWhere(
            (event) => event.startsWith('Parashat'),
            orElse: () => 'לא זמין',
          );

          // תרגום לעברית
          parasha = parashaTranslations[englishParasha] ?? englishParasha;
        }

        setState(() {
          hebrewDateInfo = '$hebrewDate\n$parasha';
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

  Widget _buildHeaderCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, Colors.transparent],
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
        children: [
          Icon(Icons.today, color: Colors.black, size: 32),
          SizedBox(height: 12),
          Text(
            'תאריך עברי',
            style: TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            hebrewDateInfo,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              height: 1.4,
            ),
          ),
        ],
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
                _buildHeaderCard(),
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
