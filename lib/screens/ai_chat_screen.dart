import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rabbi_shiba/screens/general_detail_screen.dart';
import 'package:rabbi_shiba/screens/moadi_israel_screen.dart';
import 'package:rabbi_shiba/screens/rabbi_videos_screen.dart';
import 'package:rabbi_shiba/screens/shabat_screen.dart';
import 'package:rabbi_shiba/screens/user_to_synagogue_map.dart';
import 'package:rabbi_shiba/screens/week_day_tefilot_screen.dart'
    show WeekdayTefilotScreen;
import 'package:rabbi_shiba/screens/chet_screen.dart';
import 'package:rabbi_shiba/screens/zmanim_screen.dart';
import 'package:rabbi_shiba/services/ai_service.dart';
import 'package:rabbi_shiba/utils/app_colors.dart';
import 'package:rabbi_shiba/utils/theme_helpers.dart';

// ─────────────────────────────────────────────
// Chat Message Model
// ─────────────────────────────────────────────

class _ChatMessage {
  final String text;
  final bool isUser;
  final List<KnowledgeDoc> sources;

  const _ChatMessage({
    required this.text,
    required this.isUser,
    this.sources = const [],
  });
}

// ─────────────────────────────────────────────
// AI Chat Screen
// ─────────────────────────────────────────────

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen>
    with SingleTickerProviderStateMixin {
  final _messages = <_ChatMessage>[];
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;

  // Suggested questions to show on empty state
  static const _suggestions = [
    'מה הכשרות של הבשר כאן?',
    'מתי שחרית?',
    'מתי מנחה?',
    'מתי ערבית?',
    'מה מותר לעשות בשבת?',
    'מהם זמני הדלקת נרות?',
    'מה זמני היום?',
    'יש סרטונים של הרב?',
    'רוצה לדבר עם הרב',
    'מה הדין לכהן במחלקה?',
    'מה הדין לגבי מקווה?',
    'אנשי קשר',
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? override]) async {
    final text = (override ?? _textController.text).trim();
    if (text.isEmpty || _isLoading) return;

    _textController.clear();
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final response = await AiService.ask(text);
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatMessage(
            text: response.answer,
            isUser: false,
            sources: response.sources,
          ),
        );
      });
    } catch (e) {
      debugPrint('❌ AiChatScreen error: $e');
      if (!mounted) return;
      final errorMsg = _friendlyError(e);
      setState(() {
        _messages.add(_ChatMessage(text: errorMsg, isUser: false));
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('GROQ_API_KEY') ||
        msg.contains('חסר') ||
        msg.contains('לא תקין')) {
      return msg;
    }
    if (msg.toLowerCase().contains('socket') ||
        msg.toLowerCase().contains('connection')) {
      return 'אין חיבור לאינטרנט. אנא בדוק את החיבור ונסה שוב.';
    }
    if (msg.contains('בקשות') || msg.contains('שניות')) return msg;
    debugPrint('❌ AI error: $e');
    return 'אירעה שגיאה. נסה שוב.';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            Positioned.fill(child: ThemeHelpers.buildDefaultBackground()),
            SafeArea(
              child: Column(
                children: [
                  Expanded(child: _buildMessageList()),
                  if (_isLoading) _buildTypingIndicator(),
                  _buildInputBar(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white.withValues(alpha: 0.85),
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded, color: AppColors.navy),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          // Hero widget — מחובר ל-FAB ויוצר אנימציית מעבר חלקה
          Hero(
            tag: 'ai_robot_fab',
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4A90D9), Color(0xFF0D7C60)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.blue.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'עוזר AI',
                style: GoogleFonts.alef(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
              Text(
                'שאל על כשרות, שבת, חגים ועוד',
                style: GoogleFonts.alef(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) return _buildEmptyState();

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      itemCount: _messages.length,
      itemBuilder: (_, i) => _buildBubble(_messages[i]),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 52,
            color: AppColors.skyBlue.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          Text(
            'שאל אותי כל שאלה בנושאי\nכשרות, שבת, חגים והלכה',
            textAlign: TextAlign.center,
            style: GoogleFonts.alef(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'שאלות נפוצות:',
            style: GoogleFonts.alef(
              fontSize: 13,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children:
                _suggestions
                    .map(
                      (q) => _SuggestionChip(
                        label: q,
                        onTap: () => _sendMessage(q),
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(_ChatMessage message) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isUser ? AppColors.blue : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft:
                    isUser
                        ? const Radius.circular(18)
                        : const Radius.circular(4),
                bottomRight:
                    isUser
                        ? const Radius.circular(4)
                        : const Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  message.text,
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.alef(
                    fontSize: 15,
                    color: isUser ? Colors.white : AppColors.textPrimary,
                    height: 1.55,
                  ),
                ),
                if (message.sources.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  _buildSourcesSection(message.sources),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSourcesSection(List<KnowledgeDoc> sources) {
    // One nav button per unique category
    final seen = <String>{};
    final unique = sources.where((s) => seen.add(s.category)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children:
          unique.map((source) {
            final navEntry = _navEntryForSource(source);
            final sourceLabel = _sourceLabelFor(source);

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.tealLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_outlined,
                          size: 11,
                          color: AppColors.teal,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'מקור: $sourceLabel',
                          style: GoogleFonts.alef(
                            fontSize: 11,
                            color: AppColors.teal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (navEntry != null) ...[
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => _navigate(navEntry.screen),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.blue.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.arrow_back_ios_rounded,
                              size: 11,
                              color: AppColors.blue,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'עבור ל${navEntry.label}',
                              style: GoogleFonts.alef(
                                fontSize: 12,
                                color: AppColors.blue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
    );
  }

  void _navigate(Widget screen) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => screen,
        transitionsBuilder:
            (_, animation, __, child) => FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 280),
      ),
    );
  }

  _NavEntry? _categoryNavEntry(String category) {
    switch (category) {
      case 'סרטוני הרב':
        return _NavEntry('סרטוני הרב', const RabbiVideosScreen());
      case 'זמני היום':
        return _NavEntry('זמני היום', ZmanimScreen());
      case 'כשרות':
        return _NavEntry('מסך כשרות', GeneralDetailScreen(type: 'כשרות'));
      case 'שבת':
        return _NavEntry('מסך שבת', const ShabatScreen());
      case 'חגים':
        return _NavEntry('מסך מועדי ישראל', const MoadiIsraelScreen());
      case 'תפילה':
        return _NavEntry('זמני תפילה', const WeekdayTefilotScreen());
      case 'מקווה':
        return _NavEntry('מסך מקווה', GeneralDetailScreen(type: 'מקווה'));
      case 'נפטרים':
        return _NavEntry('מסך נפטרים', GeneralDetailScreen(type: 'נפטרים'));
      case 'הלכה':
        return _NavEntry('טומאת כהנים', GeneralDetailScreen(type: 'טומאת כהנים'));
      case 'אנשי קשר':
        return _NavEntry('אנשי קשר', GeneralDetailScreen(type: 'אנשי קשר'));
      case 'בתי כנסת':
      case 'בית כנסת':
      case 'בתי כנסת במרכז הרפואי':
        return _NavEntry('בתי כנסת במרכז הרפואי', UserToSynagogueMap());
      case 'ייעוץ הלכתי רפואי':
      case 'ייעוץ':
        return _NavEntry('ייעוץ הלכתי רפואי', ChatScreen());
      default:
        return null;
    }
  }

  _NavEntry? _navEntryForSource(KnowledgeDoc source) {
    final metadata = source.metadata;
    final metadataScreen =
        metadata['screen'] ?? metadata['screenType'] ?? metadata['route'];
    if (metadataScreen is String && metadataScreen.isNotEmpty) {
      final entry = _navEntryFromKey(metadataScreen);
      if (entry != null) return entry;
    }

    final metadataCategory = metadata['category'];
    if (metadataCategory is String && metadataCategory.isNotEmpty) {
      final entry = _navEntryFromKey(metadataCategory);
      if (entry != null) return entry;
    }

    return _categoryNavEntry(source.category);
  }

  _NavEntry? _navEntryFromKey(String key) {
    switch (key.trim()) {
      case 'סרטוני הרב':
        return _NavEntry('סרטוני הרב', const RabbiVideosScreen());
      case 'זמני היום':
        return _NavEntry('זמני היום', ZmanimScreen());
      case 'שבת':
        return _NavEntry('מסך שבת', const ShabatScreen());
      case 'כשרות':
        return _NavEntry('מסך כשרות', GeneralDetailScreen(type: 'כשרות'));
      case 'בתי כנסת במרכז הרפואי':
        return _NavEntry('בתי כנסת במרכז הרפואי', UserToSynagogueMap());
      case 'זמני תפילות ימי חול':
      case 'תפילה':
        return _NavEntry('זמני תפילה', const WeekdayTefilotScreen());
      case 'טומאת כהנים':
        return _NavEntry('טומאת כהנים', GeneralDetailScreen(type: 'טומאת כהנים'));
      case 'נפטרים':
        return _NavEntry('נפטרים', GeneralDetailScreen(type: 'נפטרים'));
      case 'מקווה':
        return _NavEntry('מקווה', GeneralDetailScreen(type: 'מקווה'));
      case 'מועדי ישראל':
        return _NavEntry('מסך מועדי ישראל', const MoadiIsraelScreen());
      case 'ייעוץ הלכתי רפואי':
        return _NavEntry('ייעוץ הלכתי רפואי', ChatScreen());
      case 'אנשי קשר':
        return _NavEntry('אנשי קשר', GeneralDetailScreen(type: 'אנשי קשר'));
      default:
        return _categoryNavEntry(key);
    }
  }

  String _sourceLabelFor(KnowledgeDoc source) {
    final metadata = source.metadata;
    final label = metadata['label'] ?? metadata['title'] ?? metadata['screen'];
    if (label is String && label.trim().isNotEmpty) return label.trim();
    return source.category;
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.blue,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'חושב...',
                style: GoogleFonts.alef(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        border: Border(top: BorderSide(color: AppColors.divider, width: 0.8)),
      ),
      child: Row(
        children: [
          // כפתור שליחה
          IconButton(
            onPressed: _isLoading ? null : _sendMessage,
            icon: Icon(
              Icons.send_rounded,
              color: _isLoading ? AppColors.textMuted : AppColors.blue,
            ),
          ),
          // שדה קלט
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.divider),
              ),
              child: TextField(
                controller: _textController,
                textDirection: TextDirection.rtl,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                enabled: !_isLoading,
                maxLines: null,
                style: GoogleFonts.alef(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'שאל שאלה...',
                  hintStyle: GoogleFonts.alef(
                    fontSize: 15,
                    color: AppColors.textMuted,
                  ),
                  hintTextDirection: TextDirection.rtl,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Suggestion Chip Widget
// ─────────────────────────────────────────────

// ─────────────────────────────────────────────
// Nav Entry Model
// ─────────────────────────────────────────────

class _NavEntry {
  final String label;
  final Widget screen;
  const _NavEntry(this.label, this.screen);
}

// ─────────────────────────────────────────────
// Suggestion Chip Widget
// ─────────────────────────────────────────────

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.lightBlue, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          textDirection: TextDirection.rtl,
          style: GoogleFonts.alef(
            fontSize: 13,
            color: AppColors.blue,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
