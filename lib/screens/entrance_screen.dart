import 'package:flutter/material.dart';
import 'package:rabbi_shiba/screens/home_screen.dart';
import 'package:rabbi_shiba/screens/chet_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/animation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class EntranceScreen extends StatefulWidget {
  @override
  _EntranceScreenState createState() => _EntranceScreenState();
}

class _EntranceScreenState extends State<EntranceScreen>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  String rabbiQuote = 'טוען ציטוט...';
  String rabbiImageUrl = '';
  bool isLoading = true;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _fetchRabbiData();
  }

  void _initializeAnimations() {
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
  }

  Future<void> _fetchRabbiData() async {
    try {
      final response =
          await supabase
              .from('כללי')
              .select('מידע')
              .eq('סוג', 'דבר הרב')
              .limit(1)
              .maybeSingle();

      if (!mounted) return;

      if (response == null || response['מידע'] == null) {
        setState(() {
          rabbiQuote = 'לא נמצא ציטוט';
          isLoading = false;
        });
      } else {
        setState(() {
          rabbiQuote = response['מידע'];
          isLoading = false;
        });
      }

      _controller.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        rabbiQuote = 'שגיאה בטעינת הציטוט';
        isLoading = false;
      });
      _controller.forward();
      print('Error fetching rabbi data: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    children: [
                      Image.asset('assets/siba5.png', height: 130),
                      Text(
                        'ברוכים הבאים',
                        style: GoogleFonts.alef(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'מחלקת כשרות דת והלכה',
                        style: GoogleFonts.alef(
                          fontSize: 22,
                          color: Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 30),

              // Main Content
              ScaleTransition(
                scale: _scaleAnimation,
                child:
                    isLoading
                        ? Center(
                          child: CircularProgressIndicator(
                            color: Colors.blue[800],
                            strokeWidth: 2,
                          ),
                        )
                        : _buildContent(),
              ),
              Spacer(),

              // Buttons
              FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    children: [
                      _buildContactButton(),
                      SizedBox(height: 12),
                      _buildEnterButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 100,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  image: AssetImage('assets/hrav.png') as ImageProvider,
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$rabbiQuote',
                    style: GoogleFonts.davidLibre(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                      color: Colors.grey[800],
                    ),
                    textAlign: TextAlign.right,
                  ),
                  SizedBox(height: 10),
                  Text(
                    '- הרב יואב חנניה אוקנין',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
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

  Widget _buildEnterButton() {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => HomeScreen(),
            transitionsBuilder:
                (_, a, __, c) => FadeTransition(opacity: a, child: c),
            transitionDuration: Duration(milliseconds: 500),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[800],
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 5,
        shadowColor: Colors.blue.withOpacity(0.3),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'כניסה לאפליקציה',
            style: GoogleFonts.alef(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton() {
    return OutlinedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChatScreen()),
        );
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.blue[800],
        side: BorderSide(color: Colors.blue[800]!, width: 1.5),
        padding: EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(FontAwesomeIcons.whatsapp, size: 22, color: Colors.blue[800]),
          SizedBox(width: 8),
          Text(
            'יצירת קשר עם הרב',
            style: GoogleFonts.alef(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
