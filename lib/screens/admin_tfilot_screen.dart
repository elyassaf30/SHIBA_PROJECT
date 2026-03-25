// lib/screens/admin_tefilot_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:rabbi_shiba/screens/entrance_screen.dart';

class AdminTefilotScreen extends StatefulWidget {
  const AdminTefilotScreen({super.key});

  @override
  _AdminTefilotScreenState createState() => _AdminTefilotScreenState();
}

class _AdminTefilotScreenState extends State<AdminTefilotScreen>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  List<Map<String, dynamic>> _tefilotData = [];
  final Map<String, TextEditingController> _timeControllers = {};
  final Map<String, TextEditingController> _notesControllers = {};
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();

  final List<String> _tefilotOptions = ['׳©׳—׳¨׳™׳×', '׳׳ ׳—׳”', '׳¢׳¨׳‘׳™׳×'];

  String? _selectedNewTefilaType;
  final _newTefilaTimeDisplayController = TextEditingController();
  final _newTefilaNotesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _fetchTefilotData();
    _animationController.forward();
  }

  @override
  void dispose() {
    for (var c in _timeControllers.values) {
      c.dispose();
    }
    for (var c in _notesControllers.values) {
      c.dispose();
    }
    _newTefilaTimeDisplayController.dispose();
    _newTefilaNotesController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String _safeIdAsString(dynamic idRaw) {
    if (idRaw == null) return '';
    return idRaw.toString();
  }

  Future<void> _selectNewTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Color(0xFF6C63FF),
            colorScheme: ColorScheme.light(
              primary: Color(0xFF6C63FF),
              secondary: Color(0xFF6C63FF),
            ),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(alwaysUse24HourFormat: true),
              child: child!,
            ),
          ),
        );
      },
    );
    if (picked != null) {
      final baseTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      final formattedTimeWithSeconds = '$baseTime:00';
      _newTefilaTimeDisplayController.text = formattedTimeWithSeconds;
    }
  }

  Future<void> _fetchTefilotData() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase
          .from('׳–׳׳ ׳™ ׳×׳₪׳™׳׳•׳× ׳™׳׳™ ׳—׳•׳')
          .select()
          .order('׳©׳¢׳”', ascending: true);

      _tefilotData = List<Map<String, dynamic>>.from(response);

      _timeControllers.forEach((_, c) => c.dispose());
      _notesControllers.forEach((_, c) => c.dispose());
      _timeControllers.clear();
      _notesControllers.clear();

      for (var item in _tefilotData) {
        final idStr = _safeIdAsString(item['id']);
        if (idStr.isEmpty) {
          debugPrint('Skipping item without id: $item');
          continue;
        }

        _timeControllers[idStr] = TextEditingController(
          text: item['׳©׳¢׳”'] ?? '',
        );
        _notesControllers[idStr] = TextEditingController(
          text: item['׳”׳¢׳¨׳•׳×'] ?? '',
        );
      }
    } on PostgrestException catch (e) {
      _showSnackBar('׳©׳’׳™׳׳” ׳‘׳˜׳¢׳™׳ ׳× ׳”׳ ׳×׳•׳ ׳™׳: ${e.message}', isError: true);
    } catch (e) {
      _showSnackBar(
        '׳©׳’׳™׳׳” ׳›׳׳׳™׳× ׳‘׳˜׳¢׳™׳ ׳× ׳”׳ ׳×׳•׳ ׳™׳: ${e.toString()}',
        isError: true,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteTefila(String id, String type) async {
    setState(() => _isLoading = true);

    try {
      await supabase.from('׳–׳׳ ׳™ ׳×׳₪׳™׳׳•׳× ׳™׳׳™ ׳—׳•׳').delete().eq('id', id);

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('tefilot_data_cache');

      _showSnackBar('׳”׳×׳₪׳™׳׳”$type׳ ׳׳—׳§׳” ׳‘׳”׳¦׳׳—׳”!', isError: false);
      _fetchTefilotData();
    } on PostgrestException catch (e) {
      _showSnackBar(
        '׳©׳’׳™׳׳” ׳‘׳׳—׳™׳§׳” ׳׳©׳¨׳×: ׳•׳“׳ ׳”׳¨׳©׳׳× DELETE ׳‘-RLS. ׳©׳’׳™׳׳”: ${e.message}',
        isError: true,
      );
    } catch (e) {
      _showSnackBar('׳©׳’׳™׳׳” ׳‘׳׳×׳™ ׳¦׳₪׳•׳™׳” ׳‘׳׳—׳™׳§׳”: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _confirmDelete(String id, String type) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '׳׳™׳©׳•׳¨ ׳׳—׳™׳§׳”',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 10),
                Icon(Icons.warning_rounded, color: Colors.orange, size: 28),
              ],
            ),
            content: Text(
              '׳”׳׳ ׳׳×׳” ׳‘׳˜׳•׳— ׳©׳‘׳¨׳¦׳•׳ ׳ ׳׳׳—׳•׳§ ׳׳× ׳”׳×׳₪׳™׳׳”: $type?',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('׳‘׳™׳˜׳•׳', style: TextStyle(color: Colors.grey[600])),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteTefila(id, type);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('׳׳—׳§', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }

  Future<void> _saveTefilotData() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('׳™׳© ׳׳׳׳ ׳׳× ׳›׳ ׳©׳“׳•׳× ׳”׳—׳•׳‘׳” ׳‘׳₪׳•׳¨׳׳˜ ׳”׳ ׳›׳•׳.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      bool isNewItemValid =
          _selectedNewTefilaType != null &&
          _newTefilaTimeDisplayController.text.trim().isNotEmpty;

      for (var item in _tefilotData) {
        final idStr = _safeIdAsString(item['id']);
        if (idStr.isEmpty) continue;

        final updatedData = {
          '׳©׳¢׳”': _timeControllers[idStr]?.text.trim() ?? (item['׳©׳¢׳”'] ?? ''),
          '׳”׳¢׳¨׳•׳×':
              _notesControllers[idStr]?.text.trim() ?? (item['׳”׳¢׳¨׳•׳×'] ?? ''),
          '׳¡׳•׳’ ׳×׳₪׳™׳׳”': item['׳¡׳•׳’ ׳×׳₪׳™׳׳”'],
        };

        await supabase
            .from('׳–׳׳ ׳™ ׳×׳₪׳™׳׳•׳× ׳™׳׳™ ׳—׳•׳')
            .update(updatedData)
            .eq('id', idStr);
      }

      if (isNewItemValid) {
        final insertData = {
          '׳©׳¢׳”': _newTefilaTimeDisplayController.text.trim(),
          '׳”׳¢׳¨׳•׳×': _newTefilaNotesController.text.trim(),
          '׳¡׳•׳’ ׳×׳₪׳™׳׳”': _selectedNewTefilaType!,
        };

        await supabase.from('׳–׳׳ ׳™ ׳×׳₪׳™׳׳•׳× ׳™׳׳™ ׳—׳•׳').insert(insertData).select();
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('tefilot_data_cache');

      if (isNewItemValid) {
        setState(() {
          _selectedNewTefilaType = null;
        });
        _newTefilaTimeDisplayController.clear();
        _newTefilaNotesController.clear();
      }

      _showSnackBar('׳–׳׳ ׳™ ׳”׳×׳₪׳™׳׳•׳× ׳ ׳©׳׳¨׳• ׳‘׳”׳¦׳׳—׳”!', isError: false);
      _fetchTefilotData();
    } on PostgrestException catch (e) {
      _showSnackBar('׳©׳’׳™׳׳” ׳‘׳©׳׳™׳¨׳” ׳׳©׳¨׳×: ${e.message}', isError: true);
    } catch (e) {
      _showSnackBar('׳©׳’׳™׳׳” ׳‘׳׳×׳™ ׳¦׳₪׳•׳™׳”: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => EntranceScreen()),
      (Route<dynamic> route) => false,
    );
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            SizedBox(width: 10),
            Expanded(child: Text(message, style: TextStyle(fontSize: 16))),
          ],
        ),
        backgroundColor: isError ? Color(0xFFE74C3C) : Color(0xFF2ECC71),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: EdgeInsets.all(20),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      ),
    );
  }

  // Scroll helpers for drawer actions
  Future<void> _scrollToTop() async {
    try {
      await _scrollController.animateTo(
        0,
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } catch (_) {}
  }

  Future<void> _scrollToBottom() async {
    try {
      await Future.delayed(Duration(milliseconds: 100));
      final max = _scrollController.position.maxScrollExtent;
      await _scrollController.animateTo(
        max,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } catch (_) {}
  }

  Future<void> _changeRabbiQuote() async {
    String current = '';
    try {
      final res =
          await supabase
              .from('׳›׳׳׳™')
              .select('׳׳™׳“׳¢')
              .eq('׳¡׳•׳’', '׳“׳‘׳¨ ׳”׳¨׳‘')
              .limit(1)
              .maybeSingle();
      if (res != null && res['׳׳™׳“׳¢'] != null) current = res['׳׳™׳“׳¢'] as String;
    } catch (e) {
      // ignore fetch error, show empty
    }

    final controller = TextEditingController(text: current);
    final result = await showDialog<String?>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('׳¢׳¨׳•׳ ׳“׳‘׳¨ ׳”׳¨׳‘'),
            content: TextFormField(
              controller: controller,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: '׳”׳§׳׳“ ׳׳× ׳”׳˜׳§׳¡׳˜ ׳©׳‘׳¨׳¦׳•׳ ׳ ׳׳”׳¦׳™׳’',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('׳‘׳˜׳'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: Text('׳©׳׳•׳¨'),
              ),
            ],
          ),
    );

    if (result != null) {
      setState(() => _isLoading = true);
      try {
        // check if exists
        final existing =
            await supabase
                .from('׳›׳׳׳™')
                .select('id')
                .eq('׳¡׳•׳’', '׳“׳‘׳¨ ׳”׳¨׳‘')
                .limit(1)
                .maybeSingle();

        if (existing != null && existing['id'] != null) {
          await supabase
              .from('׳›׳׳׳™')
              .update({'׳׳™׳“׳¢': result})
              .eq('id', existing['id'].toString());
        } else {
          await supabase.from('׳›׳׳׳™').insert({
            '׳¡׳•׳’': '׳“׳‘׳¨ ׳”׳¨׳‘',
            '׳׳™׳“׳¢': result,
          });
        }

        _showSnackBar('׳“׳‘׳¨ ׳”׳¨׳‘ ׳ ׳©׳׳¨ ׳‘׳”׳¦׳׳—׳”', isError: false);
      } catch (e) {
        _showSnackBar('׳©׳’׳™׳׳” ׳‘׳©׳׳™׳¨׳”: ${e.toString()}', isError: true);
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _validateTimeFormat(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final trimmedValue = value.trim();
    final timeRegex = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?$');

    if (!timeRegex.hasMatch(trimmedValue)) {
      return '׳₪׳•׳¨׳׳˜ ׳©׳¢׳” ׳׳ ׳×׳§׳™׳ (HH:MM)';
    }
    return null;
  }

  Color _getTefilaColor(String type) {
    switch (type) {
      case '׳©׳—׳¨׳™׳×':
        return Color(0xFFFFB74D);
      case '׳׳ ׳—׳”':
        return Color(0xFF64B5F6);
      case '׳¢׳¨׳‘׳™׳×':
        return Color(0xFF9575CD);
      default:
        return Color(0xFF6C63FF);
    }
  }

  IconData _getTefilaIcon(String type) {
    switch (type) {
      case '׳©׳—׳¨׳™׳×':
        return Icons.wb_sunny;
      case '׳׳ ׳—׳”':
        return Icons.wb_twilight;
      case '׳¢׳¨׳‘׳™׳×':
        return Icons.nightlight_round;
      default:
        return Icons.access_time;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF5A52D5)],
                  ),
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '׳×׳₪׳¨׳™׳˜ ׳ ׳™׳”׳•׳',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.edit_calendar),
                title: Text('׳¢׳¨׳™׳›׳” / ׳׳—׳™׳§׳” ׳©׳ ׳×׳₪׳™׳׳•׳×'),
                onTap: () {
                  Navigator.pop(context);
                  _scrollToTop();
                },
              ),
              ListTile(
                leading: Icon(Icons.add_circle_outline),
                title: Text('׳”׳•׳¡׳₪׳× ׳×׳₪׳™׳׳” ׳—׳“׳©׳”'),
                onTap: () {
                  Navigator.pop(context);
                  _scrollToBottom();
                },
              ),
              ListTile(
                leading: Icon(Icons.format_quote),
                title: Text('׳©׳™׳ ׳•׳™ ׳“׳‘׳¨ ׳”׳¨׳‘'),
                onTap: () {
                  Navigator.pop(context);
                  _changeRabbiQuote();
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.logout, color: Colors.red),
                title: Text('׳”׳×׳ ׳×׳§', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _signOut();
                },
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF5A52D5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '׳ ׳™׳”׳•׳ ׳–׳׳ ׳™ ׳×׳₪׳™׳׳•׳×',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 10),
            Icon(Icons.admin_panel_settings, color: Colors.white, size: 28),
          ],
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body:
          _isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF6C63FF),
                      ),
                      strokeWidth: 5,
                    ),
                    SizedBox(height: 20),
                    Text(
                      '׳˜׳•׳¢׳ ׳ ׳×׳•׳ ׳™׳...',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
              : FadeTransition(
                opacity: _fadeAnimation,
                child: Form(
                  key: _formKey,
                  child: ListView(
                    controller: _scrollController,
                    padding: EdgeInsets.all(20),
                    children: [
                      // ׳›׳•׳×׳¨׳× ׳׳¢׳•׳¦׳‘׳×
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF6C63FF).withValues(alpha: 0.1),
                              Colors.white,
                            ],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF6C63FF).withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '׳–׳׳ ׳™ ׳×׳₪׳™׳׳•׳× ׳™׳׳™ ׳—׳•׳',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2C3E50),
                                  ),
                                  textDirection: TextDirection.rtl,
                                ),
                                SizedBox(height: 5),
                                Text(
                                  '׳¢׳¨׳•׳ ׳•׳¢׳“׳›׳ ׳׳× ׳–׳׳ ׳™ ׳”׳×׳₪׳™׳׳•׳×',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey[600],
                                  ),
                                  textDirection: TextDirection.rtl,
                                ),
                              ],
                            ),
                            SizedBox(width: 15),
                            Container(
                              padding: EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: Color(0xFF6C63FF),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF6C63FF).withValues(alpha: 0.3),
                                    blurRadius: 15,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.edit_calendar,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 30),

                      // ׳×׳₪׳™׳׳•׳× ׳§׳™׳™׳׳•׳×
                      ..._tefilotData.asMap().entries.map((entry) {
                        int index = entry.key;
                        var item = entry.value;
                        final idStr = _safeIdAsString(item['id']);
                        if (idStr.isEmpty) return SizedBox.shrink();

                        return TweenAnimationBuilder(
                          duration: Duration(milliseconds: 400 + (index * 100)),
                          tween: Tween<double>(begin: 0, end: 1),
                          builder: (context, double value, child) {
                            return Transform.translate(
                              offset: Offset(0, 50 * (1 - value)),
                              child: Opacity(opacity: value, child: child),
                            );
                          },
                          child: Container(
                            margin: EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: _getTefilaColor(
                                    item['׳¡׳•׳’ ׳×׳₪׳™׳׳”'],
                                  ).withValues(alpha: 0.15),
                                  blurRadius: 20,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Stack(
                                children: [
                                  // ׳₪׳¡ ׳¦׳‘׳¢׳•׳ ׳™ ׳‘׳¦׳“
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 6,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            _getTefilaColor(item['׳¡׳•׳’ ׳×׳₪׳™׳׳”']),
                                            _getTefilaColor(
                                              item['׳¡׳•׳’ ׳×׳₪׳™׳׳”'],
                                            ).withValues(alpha: 0.5),
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        // ׳›׳•׳×׳¨׳× ׳¢׳ ׳׳™׳™׳§׳•׳ ׳•׳׳—׳™׳§׳”
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.red.withValues(alpha: 
                                                  0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: IconButton(
                                                icon: Icon(
                                                  Icons.delete_rounded,
                                                  color: Colors.red,
                                                ),
                                                tooltip: '׳׳—׳§ ׳×׳₪׳™׳׳”',
                                                onPressed:
                                                    () => _confirmDelete(
                                                      idStr,
                                                      item['׳¡׳•׳’ ׳×׳₪׳™׳׳”'],
                                                    ),
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                Text(
                                                  '${item['׳¡׳•׳’ ׳×׳₪׳™׳׳”']}',
                                                  style: TextStyle(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.bold,
                                                    color: _getTefilaColor(
                                                      item['׳¡׳•׳’ ׳×׳₪׳™׳׳”'],
                                                    ),
                                                  ),
                                                  textDirection:
                                                      TextDirection.rtl,
                                                ),
                                                SizedBox(width: 10),
                                                Container(
                                                  padding: EdgeInsets.all(10),
                                                  decoration: BoxDecoration(
                                                    color: _getTefilaColor(
                                                      item['׳¡׳•׳’ ׳×׳₪׳™׳׳”'],
                                                    ).withValues(alpha: 0.15),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Icon(
                                                    _getTefilaIcon(
                                                      item['׳¡׳•׳’ ׳×׳₪׳™׳׳”'],
                                                    ),
                                                    color: _getTefilaColor(
                                                      item['׳¡׳•׳’ ׳×׳₪׳™׳׳”'],
                                                    ),
                                                    size: 24,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 20),

                                        // ׳©׳“׳” ׳©׳¢׳”
                                        TextFormField(
                                          controller: _timeControllers[idStr],
                                          decoration: InputDecoration(
                                            labelText: '׳©׳¢׳”',
                                            labelStyle: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                            prefixIcon: Icon(
                                              Icons.access_time_rounded,
                                              color: _getTefilaColor(
                                                item['׳¡׳•׳’ ׳×׳₪׳™׳׳”'],
                                              ),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey[50],
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              borderSide: BorderSide.none,
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              borderSide: BorderSide(
                                                color: _getTefilaColor(
                                                  item['׳¡׳•׳’ ׳×׳₪׳™׳׳”'],
                                                ),
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          keyboardType: TextInputType.text,
                                          validator: _validateTimeFormat,
                                          maxLength: 8,
                                          maxLengthEnforcement:
                                              MaxLengthEnforcement.enforced,
                                        ),
                                        SizedBox(height: 15),

                                        // ׳©׳“׳” ׳”׳¢׳¨׳•׳×
                                        TextFormField(
                                          controller: _notesControllers[idStr],
                                          decoration: InputDecoration(
                                            labelText: '׳”׳¢׳¨׳•׳×',
                                            labelStyle: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                            prefixIcon: Icon(
                                              Icons.notes_rounded,
                                              color: _getTefilaColor(
                                                item['׳¡׳•׳’ ׳×׳₪׳™׳׳”'],
                                              ),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey[50],
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              borderSide: BorderSide.none,
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              borderSide: BorderSide(
                                                color: _getTefilaColor(
                                                  item['׳¡׳•׳’ ׳×׳₪׳™׳׳”'],
                                                ),
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                          maxLines: 2,
                                          textAlign: TextAlign.right,
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),

                      SizedBox(height: 20),

                      // ׳׳₪׳¨׳™׳“ ׳׳¢׳•׳¦׳‘
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.grey[300],
                              thickness: 2,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 15),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF6C63FF),
                                    Color(0xFF5A52D5),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.grey[300],
                              thickness: 2,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 20),

                      // ׳›׳¨׳˜׳™׳¡ ׳×׳₪׳™׳׳” ׳—׳“׳©׳”
                      _buildNewItemCard(),

                      SizedBox(height: 30),

                      // ׳›׳₪׳×׳•׳¨ ׳©׳׳™׳¨׳” ׳׳¢׳•׳¦׳‘
                      Container(
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFF5A52D5)],
                            begin: Alignment.centerRight,
                            end: Alignment.centerLeft,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF6C63FF).withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _saveTefilotData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '׳©׳׳•׳¨ ׳©׳™׳ ׳•׳™׳™׳',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 10),
                              Icon(
                                Icons.save_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildNewItemCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF6C63FF).withValues(alpha: 0.05),
            Color(0xFF5A52D5).withValues(alpha: 0.05),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Color(0xFF6C63FF).withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF6C63FF).withValues(alpha: 0.1),
            blurRadius: 25,
            offset: Offset(0, 15),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // ׳›׳•׳×׳¨׳×
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '׳”׳•׳¡׳₪׳× ׳×׳₪׳™׳׳” ׳—׳“׳©׳”',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6C63FF),
                  ),
                  textDirection: TextDirection.rtl,
                ),
                SizedBox(width: 10),
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Color(0xFF6C63FF),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF6C63FF).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.add_circle_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
            SizedBox(height: 25),

            // ׳¡׳•׳’ ׳×׳₪׳™׳׳”
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: '׳¡׳•׳’ ׳×׳₪׳™׳׳”',
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: Icon(
                    Icons.category_rounded,
                    color: Color(0xFF6C63FF),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Color(0xFF6C63FF), width: 2),
                  ),
                ),
                value: _selectedNewTefilaType,
                hint: Text('׳‘׳—׳¨ ׳×׳₪׳™׳׳”', textAlign: TextAlign.right),
                isExpanded: true,
                items:
                    _tefilotOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              value,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.right,
                            ),
                            SizedBox(width: 10),
                            Icon(
                              _getTefilaIcon(value),
                              color: _getTefilaColor(value),
                              size: 20,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedNewTefilaType = newValue;
                  });
                },
                validator: (value) => null,
              ),
            ),
            SizedBox(height: 20),

            // ׳©׳¢׳”
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: TextFormField(
                controller: _newTefilaTimeDisplayController,
                decoration: InputDecoration(
                  labelText: '׳©׳¢׳” (HH:MM)',
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: Icon(
                    Icons.schedule_rounded,
                    color: Color(0xFF6C63FF),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Color(0xFF6C63FF), width: 2),
                  ),
                ),
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                keyboardType: TextInputType.none,
                readOnly: true,
                validator: _validateTimeFormat,
                onTap: () => _selectNewTime(context),
                maxLength: 8,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
              ),
            ),
            SizedBox(height: 20),

            // ׳”׳¢׳¨׳•׳×
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: TextFormField(
                controller: _newTefilaNotesController,
                decoration: InputDecoration(
                  labelText: '׳”׳¢׳¨׳•׳× (׳׳•׳₪׳¦׳™׳•׳ ׳׳™)',
                  labelStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: Icon(
                    Icons.note_add_rounded,
                    color: Color(0xFF6C63FF),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Color(0xFF6C63FF), width: 2),
                  ),
                ),
                maxLines: 3,
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

