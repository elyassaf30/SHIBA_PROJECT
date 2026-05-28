import 'dart:async' show unawaited;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rabbi_shiba/services/announcement_service.dart';
import 'package:rabbi_shiba/utils/theme_helpers.dart';

class AdminNotificationScreen extends StatefulWidget {
  const AdminNotificationScreen({super.key});

  @override
  State<AdminNotificationScreen> createState() =>
      _AdminNotificationScreenState();
}

class _AdminNotificationScreenState extends State<AdminNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isSending = false;

  // Sent announcements list state
  List<Map<String, dynamic>> _sent = [];
  bool _listLoading = true;
  // IDs currently being deleted (to show per-row spinner)
  final Set<int> _deleting = {};

  @override
  void initState() {
    super.initState();
    _loadSent();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadSent() async {
    setState(() => _listLoading = true);
    try {
      final data = await AnnouncementService.fetchAll();
      if (mounted) setState(() { _sent = data; _listLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _listLoading = false);
    }
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSending = true);

    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        _showSnack('שגיאה: לא מחובר. נסה להתחבר מחדש.', isError: true);
        return;
      }

      await AnnouncementService.sendAnnouncement(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        supabaseAccessToken: session.accessToken,
      );

      if (mounted) {
        _titleController.clear();
        _contentController.clear();
        _showSnack('✅ ההודעה נשלחה בהצלחה לכל המשתמשים!');
        // Refresh the list after sending
        unawaited(_loadSent());
      }
    } catch (e) {
      if (mounted) _showSnack('שגיאה בשליחת ההודעה: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _confirmDelete(int id, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'מחיקת הודעה',
            style: GoogleFonts.alef(fontWeight: FontWeight.w700, color: const Color(0xFF0C2D5E)),
          ),
          content: Text(
            'האם למחוק את ההודעה "$title"?\nפעולה זו אינה ניתנת לביטול.',
            style: GoogleFonts.alef(fontSize: 14, color: const Color(0xFF4A5568), height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('ביטול', style: GoogleFonts.alef(color: const Color(0xFF4A5568))),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('מחק', style: GoogleFonts.alef(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() => _deleting.add(id));
    try {
      await AnnouncementService.deleteAnnouncement(id);
      if (mounted) {
        setState(() => _sent.removeWhere((a) => a['id'] == id));
        _showSnack('ההודעה נמחקה בהצלחה.');
      }
    } catch (e) {
      if (mounted) _showSnack('שגיאה במחיקה: $e', isError: true);
    } finally {
      if (mounted) setState(() => _deleting.remove(id));
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textDirection: TextDirection.rtl,
          style: GoogleFonts.alef(color: Colors.white),
        ),
        backgroundColor: isError ? Colors.red.shade700 : const Color(0xFF1A5FB4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      return intl.DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'ניהול הודעות',
          style: GoogleFonts.alef(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: const Color(0xFF0C2D5E),
          ),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF0C2D5E)),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: ThemeHelpers.buildDefaultBackground()),
          Positioned.fill(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Send form ──────────────────────────────────────────
                    _SectionHeader(title: 'שליחת הודעה חדשה', icon: Icons.campaign_rounded),
                    const SizedBox(height: 12),
                    _InfoBanner(),
                    const SizedBox(height: 16),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _FieldLabel(label: 'כותרת ההודעה'),
                          const SizedBox(height: 6),
                          _StyledField(
                            controller: _titleController,
                            hint: 'לדוגמה: עדכון חשוב לגבי שבת',
                            maxLines: 1,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'נא להזין כותרת' : null,
                          ),
                          const SizedBox(height: 16),
                          _FieldLabel(label: 'תוכן ההודעה'),
                          const SizedBox(height: 6),
                          _StyledField(
                            controller: _contentController,
                            hint: 'כתוב כאן את תוכן ההודעה...',
                            maxLines: 5,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'נא להזין תוכן' : null,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: _isSending ? null : _send,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1A5FB4),
                                disabledBackgroundColor:
                                    const Color(0xFF1A5FB4).withValues(alpha: 0.5),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                elevation: 2,
                              ),
                              icon: _isSending
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Icon(Icons.send_rounded, size: 20),
                              label: Text(
                                _isSending ? 'שולח...' : 'שלח לכולם',
                                style: GoogleFonts.alef(
                                    fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Sent announcements list ────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Refresh button on the left (RTL: visually right)
                        GestureDetector(
                          onTap: _loadSent,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD6E8F9).withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.refresh_rounded,
                                size: 18, color: Color(0xFF1A5FB4)),
                          ),
                        ),
                        _SectionHeader(
                            title: 'הודעות שנשלחו', icon: Icons.history_rounded),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (_listLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(color: Color(0xFF1A5FB4)),
                        ),
                      )
                    else if (_sent.isEmpty)
                      _EmptyState()
                    else
                      ...(_sent.map((item) {
                        final id = item['id'] as int;
                        final isDeleting = _deleting.contains(id);
                        return _SentAnnouncementCard(
                          title: item['title'] as String,
                          content: item['content'] as String,
                          date: _formatDate(item['created_at'] as String),
                          isDeleting: isDeleting,
                          onDelete: () => _confirmDelete(id, item['title'] as String),
                        );
                      })),
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

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF1A5FB4).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF1A5FB4)),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.alef(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0C2D5E),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFD6E8F9).withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1A5FB4).withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Color(0xFF1A5FB4), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'ההודעה תישמר בבסיס הנתונים ותישלח כהתראה לכל מי שהתקין את האפליקציה.',
                style: GoogleFonts.alef(fontSize: 13, color: const Color(0xFF0C2D5E), height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textDirection: TextDirection.rtl,
      style: GoogleFonts.alef(
          fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0D1B33)),
    );
  }
}

class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final String? Function(String?) validator;

  const _StyledField({
    required this.controller,
    required this.hint,
    required this.maxLines,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintTextDirection: TextDirection.rtl,
        hintStyle: GoogleFonts.alef(color: const Color(0xFF94A3B8), fontSize: 14),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.85),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2EAF4))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2EAF4))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1A5FB4), width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red.shade400)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red.shade600, width: 1.5)),
      ),
    );
  }
}

class _SentAnnouncementCard extends StatelessWidget {
  final String title;
  final String content;
  final String date;
  final bool isDeleting;
  final VoidCallback onDelete;

  const _SentAnnouncementCard({
    required this.title,
    required this.content,
    required this.date,
    required this.isDeleting,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2EAF4), width: 0.8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0C2D5E).withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.alef(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0D1B33)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      content,
                      style: GoogleFonts.alef(
                          fontSize: 13, color: const Color(0xFF4A5568), height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.schedule_outlined,
                            size: 11, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 3),
                        Text(date,
                            style: GoogleFonts.alef(
                                fontSize: 11, color: const Color(0xFF94A3B8))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Delete button
              GestureDetector(
                onTap: isDeleting ? null : onDelete,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200, width: 0.8),
                  ),
                  child: isDeleting
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.red.shade400),
                        )
                      : Icon(Icons.delete_outline_rounded,
                          size: 18, color: Colors.red.shade500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 40,
              color: const Color(0xFF94A3B8).withValues(alpha: 0.6)),
          const SizedBox(height: 10),
          Text(
            'עדיין לא נשלחו הודעות',
            textDirection: TextDirection.rtl,
            style: GoogleFonts.alef(fontSize: 14, color: const Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}
