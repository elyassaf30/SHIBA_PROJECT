// lib/screens/admin_tefilot_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rabbi_shiba/screens/entrance_screen.dart';
import 'package:rabbi_shiba/utils/theme_helpers.dart';

class AdminTefilotScreen extends StatefulWidget {
  const AdminTefilotScreen({super.key});

  @override
  _AdminTefilotScreenState createState() => _AdminTefilotScreenState();
}

class _AdminTefilotScreenState extends State<AdminTefilotScreen> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;
  List<Map<String, dynamic>> _tefilotData = [];
  final Map<String, TextEditingController> _timeControllers = {};
  final Map<String, TextEditingController> _notesControllers = {};
  final ScrollController _scrollController = ScrollController();

  final List<String> _tefilotOptions = ['שחרית', 'מנחה', 'ערבית'];

  String? _selectedNewTefilaType;
  final _newTefilaTimeDisplayController = TextEditingController();
  final _newTefilaNotesController = TextEditingController();

  // Track which cards are expanded for notes
  final Set<String> _expandedNotes = {};

  @override
  void initState() {
    super.initState();
    _fetchTefilotData();
  }

  @override
  void dispose() {
    for (var c in _timeControllers.values) c.dispose();
    for (var c in _notesControllers.values) c.dispose();
    _newTefilaTimeDisplayController.dispose();
    _newTefilaNotesController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _safeIdAsString(dynamic idRaw) =>
      idRaw == null ? '' : idRaw.toString();

  Future<void> _selectTime(TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder:
          (context, child) => Theme(
            data: ThemeData.light().copyWith(
              colorScheme: ColorScheme.light(primary: Color(0xFF6C63FF)),
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
          ),
    );
    if (picked != null) {
      controller.text =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00';
    }
  }

  Future<void> _fetchTefilotData() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase
          .from('זמני תפילות ימי חול')
          .select()
          .order('שעה', ascending: true);

      _tefilotData = List<Map<String, dynamic>>.from(response);

      _timeControllers.forEach((_, c) => c.dispose());
      _notesControllers.forEach((_, c) => c.dispose());
      _timeControllers.clear();
      _notesControllers.clear();

      for (var item in _tefilotData) {
        final idStr = _safeIdAsString(item['id']);
        if (idStr.isEmpty) continue;
        _timeControllers[idStr] = TextEditingController(
          text: item['שעה'] ?? '',
        );
        _notesControllers[idStr] = TextEditingController(
          text: item['הערות'] ?? '',
        );
      }
    } on PostgrestException catch (e) {
      _showSnackBar('שגיאה בטעינת הנתונים: ${e.message}', isError: true);
    } catch (e) {
      _showSnackBar('שגיאה: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteTefila(String id) async {
    try {
      await supabase.from('זמני תפילות ימי חול').delete().eq('id', id);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('tefilot_data_cache');
      _showSnackBar('נמחק בהצלחה', isError: false);
      _fetchTefilotData();
    } on PostgrestException catch (e) {
      _showSnackBar('שגיאה במחיקה: ${e.message}', isError: true);
    }
  }

  void _confirmDelete(String id, String type) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'מחיקת $type?',
              textDirection: TextDirection.rtl,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('ביטול'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteTefila(id);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('מחק', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }

  Future<void> _saveTefilotData() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      for (var item in _tefilotData) {
        final idStr = _safeIdAsString(item['id']);
        if (idStr.isEmpty) continue;
        await supabase
            .from('זמני תפילות ימי חול')
            .update({
              'שעה': _timeControllers[idStr]?.text.trim() ?? '',
              'הערות': _notesControllers[idStr]?.text.trim() ?? '',
              'סוג תפילה': item['סוג תפילה'],
            })
            .eq('id', idStr);
      }

      if (_selectedNewTefilaType != null &&
          _newTefilaTimeDisplayController.text.trim().isNotEmpty) {
        await supabase.from('זמני תפילות ימי חול').insert({
          'שעה': _newTefilaTimeDisplayController.text.trim(),
          'הערות': _newTefilaNotesController.text.trim(),
          'סוג תפילה': _selectedNewTefilaType!,
        });
        setState(() => _selectedNewTefilaType = null);
        _newTefilaTimeDisplayController.clear();
        _newTefilaNotesController.clear();
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('tefilot_data_cache');
      _showSnackBar('נשמר בהצלחה!', isError: false);
      _fetchTefilotData();
    } on PostgrestException catch (e) {
      _showSnackBar('שגיאה: ${e.message}', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => EntranceScreen()),
      (_) => false,
    );
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Color(0xFFE74C3C) : Color(0xFF2ECC71),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _changeRabbiQuote() async {
    String current = '';
    try {
      final res =
          await supabase
              .from('כללי')
              .select('מידע')
              .eq('סוג', 'דבר הרב')
              .limit(1)
              .maybeSingle();
      if (res != null) current = res['מידע'] ?? '';
    } catch (_) {}

    final controller = TextEditingController(text: current);
    final result = await showDialog<String?>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('דבר הרב', textDirection: TextDirection.rtl),
            content: TextField(
              controller: controller,
              maxLines: 6,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('בטל'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF6C63FF),
                ),
                child: Text('שמור', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );

    if (result != null) {
      setState(() => _isLoading = true);
      try {
        final existing =
            await supabase
                .from('כללי')
                .select('id')
                .eq('סוג', 'דבר הרב')
                .limit(1)
                .maybeSingle();
        if (existing != null && existing['id'] != null) {
          await supabase
              .from('כללי')
              .update({'מידע': result})
              .eq('id', existing['id'].toString());
        } else {
          await supabase.from('כללי').insert({
            'סוג': 'דבר הרב',
            'מידע': result,
          });
        }
        _showSnackBar('נשמר בהצלחה', isError: false);
      } catch (e) {
        _showSnackBar('שגיאה: ${e.toString()}', isError: true);
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _validateTimeFormat(String? value) {
    if (value == null || value.isEmpty) return null;
    final timeRegex = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?$');
    if (!timeRegex.hasMatch(value.trim())) return 'פורמט לא תקין (HH:MM)';
    return null;
  }

  Color _getTefilaColor(String type) {
    switch (type) {
      case 'שחרית':
        return Color(0xFFFFB74D);
      case 'מנחה':
        return Color(0xFF64B5F6);
      case 'ערבית':
        return Color(0xFF9575CD);
      default:
        return Color(0xFF6C63FF);
    }
  }

  IconData _getTefilaIcon(String type) {
    switch (type) {
      case 'שחרית':
        return Icons.wb_sunny;
      case 'מנחה':
        return Icons.wb_twilight;
      case 'ערבית':
        return Icons.nightlight_round;
      default:
        return Icons.access_time;
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      drawer: _buildDrawer(),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'ניהול תפילות',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.admin_panel_settings, color: Colors.white, size: 24),
          ],
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: ThemeHelpers.buildDefaultBackground()),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFF6C63FF)),
              ),
            )
          else
            Form(
              key: _formKey,
              child: ListView(
                controller: _scrollController,
                padding: EdgeInsets.fromLTRB(14, 100, 14, 24),
                children: [
                  // ── Existing prayers ──────────────────────────────────
                  ..._tefilotData.map((item) {
                    final idStr = _safeIdAsString(item['id']);
                    if (idStr.isEmpty) return SizedBox.shrink();
                    return _buildCompactCard(item, idStr);
                  }),

                  SizedBox(height: 12),
                  _buildAddNewCard(),
                  SizedBox(height: 16),

                  // ── Save button ───────────────────────────────────────
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveTefilotData,
                      icon:
                          _isSaving
                              ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : Icon(Icons.save_rounded, color: Colors.white),
                      label: Text(
                        'שמור שינויים',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF6C63FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
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

  /// Compact, single-row card for an existing prayer
  Widget _buildCompactCard(Map<String, dynamic> item, String idStr) {
    final type = item['סוג תפילה'] as String? ?? '';
    final color = _getTefilaColor(type);
    final hasNotes = _expandedNotes.contains(idStr);

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(right: BorderSide(color: color, width: 5)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          children: [
            // ── Main row ────────────────────────────────────────────
            Row(
              children: [
                // Delete
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.red[300],
                    size: 20,
                  ),
                  tooltip: 'מחק',
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _confirmDelete(idStr, type),
                ),

                SizedBox(width: 6),

                // Time field – compact
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _timeControllers[idStr],
                    readOnly: true,
                    onTap: () => _selectTime(_timeControllers[idStr]!),
                    validator: _validateTimeFormat,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      filled: true,
                      fillColor: color.withValues(alpha: 0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: Icon(
                        Icons.access_time_rounded,
                        size: 16,
                        color: color,
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 8),

                // Prayer type badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        type,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      SizedBox(width: 4),
                      Icon(_getTefilaIcon(type), color: color, size: 16),
                    ],
                  ),
                ),
              ],
            ),

            // ── Notes toggle ────────────────────────────────────────
            InkWell(
              onTap:
                  () => setState(
                    () =>
                        hasNotes
                            ? _expandedNotes.remove(idStr)
                            : _expandedNotes.add(idStr),
                  ),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      _notesControllers[idStr]?.text.isNotEmpty == true
                          ? _notesControllers[idStr]!.text
                          : 'הוסף הערה',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.rtl,
                    ),
                    SizedBox(width: 4),
                    Icon(
                      hasNotes ? Icons.expand_less : Icons.expand_more,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ),
            ),

            if (hasNotes)
              Padding(
                padding: EdgeInsets.only(top: 6),
                child: TextFormField(
                  controller: _notesControllers[idStr],
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  maxLines: 2,
                  style: TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'הערות...',
                    hintTextDirection: TextDirection.rtl,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddNewCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Color(0xFF6C63FF).withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Icon(
          Icons.add_circle_outline,
          color: Color(0xFF6C63FF),
          size: 22,
        ),
        title: Text(
          'הוספת תפילה חדשה',
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6C63FF),
          ),
        ),
        children: [
          // Prayer type
          DropdownButtonFormField<String>(
            value: _selectedNewTefilaType,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'סוג תפילה',
              labelStyle: TextStyle(fontSize: 13),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            items:
                _tefilotOptions
                    .map(
                      (v) => DropdownMenuItem(
                        value: v,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(v, textDirection: TextDirection.rtl),
                            SizedBox(width: 8),
                            Icon(
                              _getTefilaIcon(v),
                              color: _getTefilaColor(v),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
            onChanged: (v) => setState(() => _selectedNewTefilaType = v),
          ),
          SizedBox(height: 10),

          // Time
          TextFormField(
            controller: _newTefilaTimeDisplayController,
            readOnly: true,
            onTap: () => _selectTime(_newTefilaTimeDisplayController),
            validator: _validateTimeFormat,
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              labelText: 'שעה',
              labelStyle: TextStyle(fontSize: 13),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              prefixIcon: Icon(
                Icons.schedule_rounded,
                color: Color(0xFF6C63FF),
                size: 18,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          SizedBox(height: 10),

          // Notes
          TextFormField(
            controller: _newTefilaNotesController,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            maxLines: 2,
            style: TextStyle(fontSize: 13),
            decoration: InputDecoration(
              labelText: 'הערות (אופציונלי)',
              labelStyle: TextStyle(fontSize: 13),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
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
                  'תפריט ניהול',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.format_quote),
              title: Text('שינוי דבר הרב'),
              onTap: () {
                Navigator.pop(context);
                _changeRabbiQuote();
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text('התנתק', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _signOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}
