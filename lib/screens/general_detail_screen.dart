import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeneralDetailScreen extends StatefulWidget {
  final String? type;

  const GeneralDetailScreen({Key? key, this.type}) : super(key: key);

  @override
  _GeneralDetailScreenState createState() => _GeneralDetailScreenState();
}

class _GeneralDetailScreenState extends State<GeneralDetailScreen> {
  String? info;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    fetchInfoByType();
  }

  Future<void> fetchInfoByType() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'generalInfo_${widget.type}';
    final cacheTimeKey = 'generalInfoTime_${widget.type}';

    final cachedData = prefs.getString(cacheKey);
    final cachedTime = prefs.getInt(cacheTimeKey);
    final now = DateTime.now().millisecondsSinceEpoch;

    if (cachedData != null &&
        cachedTime != null &&
        now - cachedTime < 3600000) {
      setState(() {
        info = cachedData;
        _isLoading = false;
      });
      return;
    }

    try {
      final response =
          await Supabase.instance.client
              .from('כללי')
              .select('מידע')
              .eq('סוג', widget.type ?? '')
              .maybeSingle();

      setState(() {
        info = response != null ? (response['מידע'] as String?) : null;
        _isLoading = false;
      });

      if (info != null) {
        await prefs.setString(cacheKey, info!);
        await prefs.setInt(cacheTimeKey, now);
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
        info = 'אירעה שגיאה בטעינת המידע. נסה שוב מאוחר יותר.';
      });
      print('שגיאה ב-fetchInfoByType: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.type ?? 'פרטים כלליים',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
            shadows: [
              Shadow(blurRadius: 6, color: Colors.black, offset: Offset(2, 2)),
            ],
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withOpacity(0.7), Colors.transparent],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // רקע תמונה מלא
          Positioned.fill(
            child: Image.asset('assets/siba4.png', fit: BoxFit.cover),
          ),

          // תוכן מלא המתחיל מלמעלה
          SingleChildScrollView(
            child: Container(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.white.withOpacity(0.9)],
                  stops: [0.3, 0.5], // התחלת מעבר צבע מהשליש העליון
                ),
              ),
              padding: EdgeInsets.only(
                top: 100, // מרווח לכותרת
                left: 24,
                right: 24,
                bottom: 40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // כרטיס תוכן
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(24),
                    child: _buildContent(),
                  ),

                  // כפתור רענון אם יש שגיאה
                  if (_hasError)
                    Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: ElevatedButton(
                        onPressed: fetchInfoByType,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('נסה שוב', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Container(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
          ),
        ),
      );
    }

    if (info == null || info!.isEmpty) {
      return Column(
        children: [
          Icon(Icons.info_outline, size: 50, color: Colors.grey[600]),
          SizedBox(height: 16),
          Text(
            'לא נמצא מידע זמין',
            style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Text(
      info!,
      style: TextStyle(fontSize: 18, height: 1.6, color: Colors.black87),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.justify,
    );
  }
}
