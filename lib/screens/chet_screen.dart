import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rabbi_shiba/utils/theme_helpers.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  Future<String> getPhoneNumberFromSupabase() async {
    try {
      final response =
          await Supabase.instance.client.from('׳•׳•׳˜׳¡׳׳₪').select('׳׳¡׳₪׳¨').single();
      return response['׳׳¡׳₪׳¨']?.toString() ?? '';
    } catch (e) {
      debugPrint('Error fetching phone number: $e');
      return '';
    }
  }

  Future<void> openWhatsApp(BuildContext context) async {
    try {
      final phoneNumber = await getPhoneNumberFromSupabase();

      if (phoneNumber.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('׳׳¡׳₪׳¨ ׳”׳˜׳׳₪׳•׳ ׳׳ ׳ ׳׳¦׳ ׳‘׳׳¢׳¨׳›׳×')));
        return;
      }

      final cleanedNumber = phoneNumber.replaceAll(RegExp(r'[+\-\s]'), '');
      final url =
          'whatsapp://send?phone=$cleanedNumber'; // URI scheme ׳©׳ WhatsApp

      debugPrint('Attempting to open: $url'); // Debugging

      if (await canLaunch(url)) {
        await launch(url); // ׳™׳₪׳×׳— ׳׳× WhatsApp ׳׳ ׳”׳•׳ ׳׳•׳×׳§׳
      } else {
        final webUrl =
            'https://wa.me/$cleanedNumber'; // ׳׳ WhatsApp ׳׳ ׳׳•׳×׳§׳, ׳”׳₪׳ ׳™׳™׳” ׳׳׳×׳¨
        if (await canLaunch(webUrl)) {
          await launch(webUrl); // ׳™׳₪׳×׳— ׳׳× ׳“׳£ ׳”׳•׳•׳‘ ׳©׳ WhatsApp
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '׳׳ ׳ ׳™׳×׳ ׳׳₪׳×׳•׳— ׳׳× WhatsApp. ׳•׳•׳“׳ ׳©׳”׳׳₪׳׳™׳§׳¦׳™׳” ׳׳•׳×׳§׳ ׳×',
              ),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('׳©׳’׳™׳׳”: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          '׳¦\' ׳׳˜ ׳¢׳ ׳¨׳‘ ׳‘׳™׳× ׳”׳—׳•׳׳™׳',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                blurRadius: 10,
                color: Colors.black,
                offset: Offset(2, 2),
              ), // ׳₪׳¡׳™׳§ ׳ ׳•׳¡׳£ ׳›׳׳
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
              colors: [Colors.green[800]!.withValues(alpha: 0.7), Colors.transparent],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: ThemeHelpers.buildDefaultBackground()),
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
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Color(0xFF25D366),
                            width: 2,
                          ),
                        ),
                        child: FaIcon(
                          FontAwesomeIcons.whatsapp,
                          size: 80,
                          color: Color(0xFF25D366),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    '׳©׳™׳—׳× ׳™׳™׳¢׳•׳¥ ׳¢׳ ׳”׳¨׳‘',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 5, 79, 32),
                      shadows: [
                        Shadow(
                          blurRadius: 10,
                          color: Colors.white,
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
                    '׳׳—׳¦׳• ׳¢׳ ׳”׳›׳₪׳×׳•׳¨ ׳›׳“׳™ ׳׳”׳×׳—׳™׳ ׳©׳™׳—׳” ׳‘׳•׳•׳˜׳¡׳׳₪ ׳¢׳ ׳”׳¨׳‘ ׳׳™׳™׳¢׳•׳¥ ׳׳™׳©׳™',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color.fromARGB(255, 4, 78, 31),
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
                          '׳₪׳×׳— ׳©׳™׳—׳” ׳‘׳•׳•׳˜׳¡׳׳₪',
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

