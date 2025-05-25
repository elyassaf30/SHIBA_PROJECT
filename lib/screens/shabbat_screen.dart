import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ShabbatScreen extends StatefulWidget {
  @override
  _ShabbatScreenState createState() => _ShabbatScreenState();
}

class _ShabbatScreenState extends State<ShabbatScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> times = [];
  String parasha = '';
  String date = '';
  String dvarTorah = '';
  bool isLoading = true;
  bool isDvarTorahExpanded = false; // מצב הרחבה לדבר התורה

  @override
  void initState() {
    super.initState();
    fetchShabbatData();
  }

  Future<void> fetchShabbatData() async {
    dynamic allCitiesTimes;
    try {
      setState(() => isLoading = true);

      final jerusalemResponse =
          await supabase
              .from('shabbat_times')
              .select('parasha_name, date')
              .eq('city', 'ירושלים')
              .order('date', ascending: false)
              .limit(1)
              .single();

      final currentParasha = jerusalemResponse['parasha_name'];
      final currentDate = jerusalemResponse['date'];

      allCitiesTimes = await supabase
          .from('shabbat_times')
          .select('city, entry_time, exit_time')
          .eq('parasha_name', currentParasha)
          .order('city', ascending: true);

      final dvarResponse =
          await supabase
              .from('divrei_torah')
              .select('content')
              .eq('parasha_name', currentParasha)
              .limit(1)
              .maybeSingle();

      setState(() {
        parasha = currentParasha;
        date = currentDate;
        times = allCitiesTimes;
        dvarTorah = dvarResponse?['content'] ?? '';
      });
    } catch (e) {
      print('Error fetching Shabbat data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('אירעה שגיאה בטעינת נתוני שבת'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1E1212), // רקע כהה יותר
      body:
          isLoading
              ? Center(child: CircularProgressIndicator(color: Colors.amber))
              : NotificationListener<ScrollNotification>(
                onNotification: (scrollNotification) {
                  // אפשר להוסיף כאן לוגיקה להגיב לגלילה אם צריך
                  return false;
                },
                child: CustomScrollView(
                  physics: BouncingScrollPhysics(), // אנימציית גלילה חלקה
                  slivers: [
                    // AppBar עם תמונה
                    SliverAppBar(
                      expandedHeight: 220.0,
                      floating: false,
                      pinned: true,
                      backgroundColor: Color(0xFF1E1212),
                      flexibleSpace: FlexibleSpaceBar(
                        collapseMode:
                            CollapseMode.parallax, // אנימציית קריסה יפה
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              'assets/shabbat_candles.png',
                              fit: BoxFit.cover,
                              opacity: const AlwaysStoppedAnimation(0.8),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Color(0xFF1E1212).withOpacity(0.95),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 20,
                              right: 20,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'פרשת $parasha',
                                    style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 8.0,
                                          color: Colors.black,
                                          offset: Offset(2.0, 2.0),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'יום שישי • $date',
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.white70,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 6.0,
                                          color: Colors.black,
                                          offset: Offset(1.0, 1.0),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // תוכן המסך
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (dvarTorah.isNotEmpty) ...[
                              _buildSectionTitle('💡 דבר תורה'),
                              SizedBox(height: 12),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    isDvarTorahExpanded = !isDvarTorahExpanded;
                                  });
                                },
                                child: _buildDvarTorah(),
                              ),
                              SizedBox(height: 24),
                            ],
                            _buildSectionTitle('🕯 זמני כניסת ויציאת שבת'),
                            SizedBox(height: 12),
                            _buildCitiesTimes(),
                            SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.amber[100],
      ),
      textAlign: TextAlign.right,
    );
  }

  Widget _buildCitiesTimes() {
    return Column(
      children:
          times.map((row) {
            return Container(
              margin: EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: [Color(0xFF3A2A2A), Color(0xFF2D1E1E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                title: Text(
                  row['city'] ?? '',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber[100],
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    'כניסה: ${row['entry_time']}   |   יציאה: ${row['exit_time']}',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 17, color: Colors.white70),
                  ),
                ),
                trailing: Icon(
                  Icons.access_time,
                  color: Colors.amber[200],
                  size: 28,
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildDvarTorah() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Card(
        color: Color(0xFFF6E2B3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 12,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.brown[800],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isDvarTorahExpanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'פרשת $parasha',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14),
              Text(
                dvarTorah,
                style: TextStyle(
                  fontSize: 17,
                  height: 1.7,
                  color: Colors.brown[900],
                ),
                textAlign: TextAlign.right,
                maxLines: isDvarTorahExpanded ? null : 3,
                overflow: isDvarTorahExpanded ? null : TextOverflow.ellipsis,
              ),
              if (!isDvarTorahExpanded) ...[
                SizedBox(height: 8),
                Align(
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.brown[600],
                    size: 28,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
