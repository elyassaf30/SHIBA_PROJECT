// lib/screens/admin_login_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rabbi_shiba/screens/admin_tfilot_screen.dart';
import 'package:rabbi_shiba/utils/theme_helpers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  _AdminLoginScreenState createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  static const String _rememberedEmailKey = 'admin_remembered_email';
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _rememberEmail = false;
  StreamSubscription<AuthState>? _authStateSubscription;

  @override
  void initState() {
    super.initState();
    _loadRememberedEmail();

    final currentSession = Supabase.instance.client.auth.currentSession;
    if (currentSession != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AdminTefilotScreen()),
          );
        }
      });
      return;
    }

    _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange
        .listen((data) {
          if (!mounted) return;

          if (data.session != null && data.event == AuthChangeEvent.signedIn) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => AdminTefilotScreen()),
            );
          }
        });
  }

  Future<void> _loadRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberedEmail = prefs.getString(_rememberedEmailKey);

    if (!mounted || rememberedEmail == null || rememberedEmail.isEmpty) {
      return;
    }

    setState(() {
      _rememberEmail = true;
      _emailController.text = rememberedEmail;
    });
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // פונקציית ההתחברות ל-Supabase
  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // **שים לב:** ודא שיש לך משתמש קיים עם המייל והסיסמה האלה
      // ב-Supabase Authentication. זהו משתמש הניהול שלך.
      final AuthResponse response = await Supabase.instance.client.auth
          .signInWithPassword(email: email, password: password);

      if (response.user != null) {
        final prefs = await SharedPreferences.getInstance();
        if (_rememberEmail) {
          await prefs.setString(_rememberedEmailKey, email);
        } else {
          await prefs.remove(_rememberedEmailKey);
        }

        // לאחר התחברות מוצלחת, נווט למסך הניהול
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AdminTefilotScreen()),
        );
      } else {
        _showErrorSnackBar('שגיאה: משתמש לא נמצא או סיסמה שגויה.');
      }
    } on AuthException catch (e) {
      _showErrorSnackBar('שגיאת התחברות: ${e.message}');
    } catch (e) {
      _showErrorSnackBar('שגיאה כללית: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('התחברות מנהל', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: ThemeHelpers.buildDefaultBackground()),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'כניסה למערכת הניהול',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 30),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'דוא"ל',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'נא להזין דוא"ל';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 15),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'סיסמה',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'נא להזין סיסמה';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: _rememberEmail,
                      onChanged: (value) {
                        setState(() {
                          _rememberEmail = value ?? false;
                        });
                      },
                      title: const Text('זכור אימייל במכשיר זה'),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    SizedBox(height: 30),
                    _isLoading
                        ? CircularProgressIndicator()
                        : ElevatedButton(
                          onPressed: _signIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade900,
                            minimumSize: Size(double.infinity, 50),
                          ),
                          child: Text(
                            'התחבר',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
