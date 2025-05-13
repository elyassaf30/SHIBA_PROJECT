import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatScreen extends StatelessWidget {
  Future<String> getPhoneNumberFromSupabase() async {
    try {
      final response =
          await Supabase.instance.client.from('ווטסאפ').select('מספר').single();
      return response['מספר']?.toString() ?? '';
    } catch (e) {
      print('Error fetching phone number: $e');
      return '';
    }
  }

  Future<void> openWhatsApp(BuildContext context) async {
    try {
      final phoneNumber = await getPhoneNumberFromSupabase();

      if (phoneNumber.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('מספר הטלפון לא נמצא במערכת')));
        return;
      }

      final cleanedNumber = phoneNumber.replaceAll(RegExp(r'[+\-\s]'), '');
      final url =
          'whatsapp://send?phone=$cleanedNumber'; // URI scheme של WhatsApp

      print('Attempting to open: $url'); // Debugging

      if (await canLaunch(url)) {
        await launch(url); // יפתח את WhatsApp אם הוא מותקן
      } else {
        final webUrl =
            'https://wa.me/$cleanedNumber'; // אם WhatsApp לא מותקן, הפנייה לאתר
        if (await canLaunch(webUrl)) {
          await launch(webUrl); // יפתח את דף הווב של WhatsApp
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'לא ניתן לפתוח את WhatsApp. וודא שהאפליקציה מותקנת',
              ),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('שגיאה: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'צ\' אט עם רב בית החולים',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                blurRadius: 10,
                color: Colors.black,
                offset: Offset(2, 2),
              ), // פסיק נוסף כאן
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.green[800]!.withOpacity(0.7), Colors.transparent],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/siba4.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(color: Colors.black.withOpacity(0.3)),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0.8, end: 1.0),
                  duration: Duration(seconds: 2),
                  curve: Curves.elasticOut,
                  builder: (context, double scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: FaIcon(
                          FontAwesomeIcons.whatsapp,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'שיחת ייעוץ עם הרב',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 10,
                          color: Colors.black,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'לחצו על הכפתור כדי להתחיל שיחה בווטסאפ עם הרב לייעוץ אישי',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 40),
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0.95, end: 1.0),
                  duration: Duration(seconds: 1),
                  curve: Curves.easeInOut,
                  builder: (context, double scale, child) {
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: ElevatedButton(
                    onPressed: () => openWhatsApp(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF25D366),
                      padding: EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 40,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 8,
                      shadowColor: Colors.green[800],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FaIcon(
                          FontAwesomeIcons.whatsapp,
                          size: 28,
                          color: Colors.white,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'פתח שיחה בווטסאפ',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
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
