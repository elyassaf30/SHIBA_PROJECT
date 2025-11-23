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
    with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  String rabbiQuote = 'טוען ציטוט...';
  String rabbiImageUrl = '';
  bool isLoading = true;

  late AnimationController _mainController;
  late AnimationController _quoteController;
  late AnimationController _buttonController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _quoteOpacityAnimation;
  late Animation<double> _buttonSlideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _fetchRabbiData();
  }

  void _initializeAnimations() {
    _mainController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    );

    _quoteController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _buttonController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: Interval(0.2, 0.8, curve: Curves.elasticOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _quoteOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _quoteController, curve: Curves.easeIn));

    _buttonSlideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeOut),
    );
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
          rabbiQuote =
              'ברוכים הבאים לאפליקציית כשרות דת והלכה של מרכז רפואי שיבא. כאן תמצאו את כל המידע הדרוש לכם לשמירה על הלכות הכשרות והדת במרכז הרפואי.';
          isLoading = false;
        });
      } else {
        setState(() {
          rabbiQuote =
              response['מידע']?.toString() ??
              'ברוכים הבאים לאפליקציית כשרות דת והלכה של מרכז רפואי שיבא.';
          isLoading = false;
        });
      }

      _mainController.forward();

      Future.delayed(Duration(milliseconds: 400), () {
        if (mounted) {
          _quoteController.forward();
        }
      });

      Future.delayed(Duration(milliseconds: 800), () {
        if (mounted) {
          _buttonController.forward();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        rabbiQuote =
            'ברוכים הבאים לאפליקציית כשרות דת והלכה של מרכז רפואי שיבא. כאן תמצאו את כל המידע הדרוש לכם לשמירה על הלכות הכשרות והדת במרכז הרפואי.';
        isLoading = false;
      });
      _mainController.forward();
      _quoteController.forward();
      _buttonController.forward();
      print('Error fetching rabbi data: $e');
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _quoteController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final safeAreaHeight =
        screenHeight -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Container(
            height: safeAreaHeight,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.06, // 6% של רוחב המסך
                vertical: safeAreaHeight * 0.03, // 3% של גובה המסך
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Section - גמיש בגובה
                  Expanded(
                    flex: 3,
                    child: AnimatedBuilder(
                      animation: _mainController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _slideAnimation.value),
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: ScaleTransition(
                              scale: _scaleAnimation,
                              child: _buildHeader(),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Quote Section - גמיש בגובה
                  Expanded(
                    flex: 4,
                    child: AnimatedBuilder(
                      animation: _quoteController,
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: _quoteOpacityAnimation,
                          child:
                              isLoading
                                  ? _buildLoadingWidget()
                                  : _buildQuoteCard(),
                        );
                      },
                    ),
                  ),

                  // Buttons Section - גובה קבוע
                  AnimatedBuilder(
                    animation: _buttonController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _buttonSlideAnimation.value),
                        child: FadeTransition(
                          opacity: _buttonController,
                          child: _buildButtonsSection(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Logo with shadow
        Flexible(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/siba5.png',
                height:
                    MediaQuery.of(context).size.height *
                    0.12, // 12% של גובה המסך
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),

        SizedBox(height: MediaQuery.of(context).size.height * 0.02),

        // Title
        Text(
          'ברוכים הבאים',
          style: GoogleFonts.alef(
            fontSize:
                MediaQuery.of(context).size.width * 0.08, // 8% של רוחב המסך
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: MediaQuery.of(context).size.height * 0.01),

        // Subtitle
        Text(
          'מחלקת כשרות דת והלכה',
          style: GoogleFonts.alef(
            fontSize:
                MediaQuery.of(context).size.width * 0.045, // 4.5% של רוחב המסך
            fontWeight: FontWeight.w500,
            color: Color(0xFF475569),
            height: 1.3,
          ),
          textAlign: TextAlign.center,
        ),

        // Decorative line
        Container(
          margin: EdgeInsets.only(
            top: MediaQuery.of(context).size.height * 0.02,
          ),
          height: 3,
          width: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              color: Color(0xFF3B82F6),
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 20),
          Text(
            '...טוען',
            style: GoogleFonts.alef(fontSize: 16, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 25,
            offset: Offset(0, 15),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Rabbi Image
            Container(
              width:
                  MediaQuery.of(context).size.width * 0.2, // 20% של רוחב המסך
              height: MediaQuery.of(context).size.width * 0.2,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  MediaQuery.of(context).size.width * 0.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF3B82F6).withOpacity(0.2),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  MediaQuery.of(context).size.width * 0.1,
                ),
                child: Image.asset(
                  'assets/hrav.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter, // זה ייקח יותר מלמעלה
                ),
              ),
            ),

            SizedBox(height: MediaQuery.of(context).size.height * 0.02),

            // Quote mark
            Icon(
              Icons.format_quote,
              size: 28,
              color: Color(0xFF3B82F6).withOpacity(0.6),
            ),

            SizedBox(height: MediaQuery.of(context).size.height * 0.015),

            // Quote text - גמיש וניתן לגלילה פנימית אם צריך
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  rabbiQuote,
                  style: GoogleFonts.alef(
                    fontSize:
                        MediaQuery.of(context).size.width *
                        0.04, // 4% של רוחב המסך
                    height: 1.6,
                    color: Color(0xFF374151),
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                ),
              ),
            ),

            SizedBox(height: MediaQuery.of(context).size.height * 0.02),

            // Attribution
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'הרב יואב חנניה אוקנין',
                style: GoogleFonts.alef(
                  fontSize: MediaQuery.of(context).size.width * 0.04,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
                textDirection: TextDirection.rtl,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonsSection() {
    return Column(
      children: [
        // Contact Button
        Container(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChatScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFF3B82F6),
              elevation: 8,
              shadowColor: Colors.black.withOpacity(0.15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Color(0xFF3B82F6), width: 2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(
                  FontAwesomeIcons.whatsapp,
                  size: 22,
                  color: Color(0xFF25D366),
                ),
                SizedBox(width: 12),
                Text(
                  'יצירת קשר עם הרב',
                  style: GoogleFonts.alef(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 16),

        // Enter Button - תיקון הניווט למסך הבית
        Container(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                // שינוי ל-pushReplacement כדי למנוע חזרה
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => HomeScreen(),
                  transitionsBuilder:
                      (_, a, __, c) => FadeTransition(opacity: a, child: c),
                  transitionDuration: Duration(milliseconds: 600),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              elevation: 12,
              shadowColor: Color(0xFF3B82F6).withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'כניסה לאפליקציה',
                  style: GoogleFonts.alef(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
