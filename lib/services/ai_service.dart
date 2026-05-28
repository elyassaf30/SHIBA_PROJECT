import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────
// Data Models
// ─────────────────────────────────────────────

class KnowledgeDoc {
  final String content;
  final String category;
  final Map<String, dynamic> metadata;

  const KnowledgeDoc({
    required this.content,
    required this.category,
    required this.metadata,
  });
}

class AiResponse {
  final String answer;
  final List<KnowledgeDoc> sources;

  const AiResponse({required this.answer, required this.sources});
}

// ─────────────────────────────────────────────
// Category Detection
// ─────────────────────────────────────────────

enum _Category {
  kashrus,
  shabbat,
  holidays,
  prayer,
  zmanim,
  mikveh,
  niftarim,
  halacha,
  contacts,
  consultation,
  videos,
  unknown,
}

_Category _detectCategory(String question) {
  final q = question.toLowerCase();

  const kashrusWords = [
    'כשר',
    'כשרות',
    'בשר',
    'חלב',
    'בשרי',
    'חלבי',
    'טרף',
    'טריף',
    'תולעים',
    'מאכל',
  ];
  const shabbatWords = [
    'שבת',
    'שבתון',
    'מלאכה',
    'הדלקת נרות',
    'הבדלה',
    'קידוש',
    'ליל שבת',
    'שבת שלום',
  ];
  const holidayWords = [
    'פסח',
    'סוכות',
    'חנוכה',
    'פורים',
    'ראש השנה',
    'יום כיפור',
    'שמחת תורה',
    'שבועות',
    'חג',
    'מועד',
    'יום טוב',
    'ל"ג בעומר',
    'לג בעומר',
  ];
  const prayerWords = [
    'תפילה',
    'שחרית',
    'מנחה',
    'ערבית',
    'מוסף',
    'מתפלל',
    'סידור',
    'זמן תפילה',
    'זמני תפילה',
    'להתפלל',
    'תפילות',
  ];
  const zmanimWords = [
    'הנץ',
    'שקיעה',
    'חצות',
    'עלות השחר',
    'צאת הכוכבים',
    'זמני היום',
    'פלג המנחה',
    'זמנים הלכתיים',
    'זמן ק"ש',
  ];
  const mikvehWords = ['מקווה', 'טבילה', 'טהרה', 'טהור', 'טמא', 'נידה'];
  const niftarimWords = [
    'נפטר',
    'פטירה',
    'אבל',
    'שבעה',
    'קבורה',
    'גסיסה',
    'נפטרים',
    'הלוויה',
    'גוסס',
  ];
  const halachaWords = [
    'כהן',
    'טומאה',
    'תפילין',
    'הלכה',
    'איסור',
    'מותר',
    'אסור',
    'טומאת כהנים',
  ];
  const contactsWords = [
    'טלפון',
    'אנשי קשר',
    'להתקשר',
    'כתובת',
    'יצירת קשר',
    'לפנות',
    'ווטסאפ של',
  ];
  const consultationWords = [
    'ייעוץ',
    'שאלה לרב',
    'לשאול רב',
    'ייעוץ הלכתי',
    'פנה לרב',
    'עם הרב',
    'לדבר עם',
    'לשוחח עם',
    'שיחה עם',
  ];
  const videosWords = [
    'סרטון',
    'סרטונים',
    'וידאו',
    'שיעור',
    'שיעורים',
    'לצפות',
    'צפייה',
    'סרטי הרב',
  ];

  if (kashrusWords.any(q.contains)) return _Category.kashrus;
  if (shabbatWords.any(q.contains)) return _Category.shabbat;
  if (holidayWords.any(q.contains)) return _Category.holidays;
  if (prayerWords.any(q.contains)) return _Category.prayer;
  if (zmanimWords.any(q.contains)) return _Category.zmanim;
  if (mikvehWords.any(q.contains)) return _Category.mikveh;
  if (niftarimWords.any(q.contains)) return _Category.niftarim;
  if (halachaWords.any(q.contains)) return _Category.halacha;
  if (contactsWords.any(q.contains)) return _Category.contacts;
  if (consultationWords.any(q.contains)) return _Category.consultation;
  if (videosWords.any(q.contains)) return _Category.videos;
  return _Category.unknown;
}

// ─────────────────────────────────────────────
// AI Service — Groq + חיפוש ישיר בסופאבייס
// ─────────────────────────────────────────────

class AiService {
  static final _supabase = Supabase.instance.client;
  static const String _logTag = 'AiService';

  static const _systemPrompt =
      'אתה עוזר AI של מרכז רפואי שיבא, המתמחה בנושאי כשרות, שבת, חגים, הלכות ומידע תורני. '
      'ענה תמיד בעברית רהוטה ומנומסת. '
      'הסתמך אך ורק על המידע שסופק בהקשר — זה המידע הרשמי של המרכז. '
      'כשיש מסך רלוונטי באפליקציה, ציין בקצרה שניתן לעבור אליו. '
      'אם המידע אינו כולל תשובה ישירה לשאלה, ציין זאת ואמור שכדאי לפנות ישירות לצוות. '
      'הצג תשובות קצרות וברורות.';

  // ── Static context docs for screens with no Supabase text ────

  static const _zmanimDoc = KnowledgeDoc(
    content:
        'מסך "זמני היום" מציג זמנים הלכתיים לפי המיקום הנוכחי: '
        'עלות השחר (72 דקות לפני הנץ), הנץ החמה, סוף זמן ק"ש (גר"א), '
        'סוף זמן תפילה (גר"א), חצות היום, מנחה גדולה, מנחה קטנה, '
        'פלג המנחה, שקיעה, צאת הכוכבים (20 דקות אחרי שקיעה) וחצות הלילה.',
    category: 'זמני היום',
    metadata: {'source': 'זמני היום'},
  );

  static const _videosDoc = KnowledgeDoc(
    content:
        'מסך "סרטוני הרב" מכיל שיעורי תורה וסרטונים של הרב. '
        'ניתן לצפות בהם ישירות מהאפליקציה.',
    category: 'סרטוני הרב',
    metadata: {'source': 'סרטוני הרב'},
  );

  static const _consultationDoc = KnowledgeDoc(
    content:
        'ניתן לפנות לרב בית החולים לייעוץ הלכתי-רפואי אישי דרך ווטסאפ. '
        'לחצו על "ייעוץ הלכתי רפואי" בתפריט האפליקציה לפתיחת שיחה ישירה עם הרב.',
    category: 'ייעוץ הלכתי רפואי',
    metadata: {'source': 'ייעוץ הלכתי רפואי'},
  );

  // ── חיפוש ישיר בטבלאות המקוריות לפי קטגוריה ─────────────

  static Future<List<KnowledgeDoc>> searchKnowledge(String question) async {
    final category = _detectCategory(question);
    final docs = <KnowledgeDoc>[];

    try {
      switch (category) {
        case _Category.kashrus:
          docs.addAll(await _fetchKlali('כשרות', 'כשרות'));
        case _Category.shabbat:
          docs.addAll(await _fetchShabbat());
        case _Category.holidays:
          docs.addAll(await _fetchHolidays(question));
        case _Category.prayer:
          docs.addAll(await _fetchPrayers());
        case _Category.mikveh:
          docs.addAll(await _fetchKlali('מקווה', 'מקווה'));
        case _Category.niftarim:
          docs.addAll(await _fetchKlali('נפטרים', 'נפטרים'));
        case _Category.halacha:
          docs.addAll(await _fetchKlali('טומאת כהנים', 'הלכה'));
          docs.addAll(await _fetchKlali('שאילת תפילין', 'הלכה'));
        case _Category.contacts:
          docs.addAll(await _fetchKlali('אנשי קשר', 'אנשי קשר'));
        case _Category.unknown:
          docs.addAll(await _fetchKlali('כשרות', 'כשרות'));
          docs.addAll(await _fetchShabbat());
        default:
          break;
      }
    } catch (e) {
      debugPrint('⚠️ searchKnowledge error: $e');
    }

    // Always guarantee a navigation doc — runs even if DB query failed/empty
    _ensureNavDoc(category, docs);

    return docs;
  }

  // מבטיח שיהיה לפחות doc אחד עם קטגוריה נכונה לניווט
  static void _ensureNavDoc(_Category category, List<KnowledgeDoc> docs) {
    bool lacks(String cat) => !docs.any((d) => d.category == cat);

    switch (category) {
      case _Category.prayer:
        if (lacks('תפילה')) {
          docs.add(
            const KnowledgeDoc(
              content:
                  'מסך "זמני תפילות" מציג את שעות שחרית, מנחה וערבית במרכז הרפואי שיבא.',
              category: 'תפילה',
              metadata: {'source': 'זמני תפילות ימי חול'},
            ),
          );
        }
      case _Category.holidays:
        if (lacks('חגים')) {
          docs.add(
            const KnowledgeDoc(
              content:
                  'מסך "מועדי ישראל" מכיל מידע על פסח, סוכות, חנוכה, פורים, ראש השנה, יום כיפור, שבועות ועוד.',
              category: 'חגים',
              metadata: {'source': 'מועדי ישראל'},
            ),
          );
        }
      case _Category.zmanim:
        docs.add(_zmanimDoc);
      case _Category.videos:
        docs.add(_videosDoc);
      case _Category.consultation:
        docs.add(_consultationDoc);
      case _Category.kashrus:
        if (lacks('כשרות')) {
          docs.add(
            const KnowledgeDoc(
              content:
                  'מסך "כשרות" מכיל מידע על כשרות המזון במרכז הרפואי שיבא.',
              category: 'כשרות',
              metadata: {'source': 'כשרות'},
            ),
          );
        }
      case _Category.shabbat:
        if (lacks('שבת')) {
          docs.add(
            const KnowledgeDoc(
              content: 'מסך "שבת" מכיל מידע על שמירת שבת במרכז הרפואי שיבא.',
              category: 'שבת',
              metadata: {'source': 'שבת'},
            ),
          );
        }
      case _Category.mikveh:
        if (lacks('מקווה')) {
          docs.add(
            const KnowledgeDoc(
              content: 'מסך "מקווה" מכיל מידע על הלכות מקווה.',
              category: 'מקווה',
              metadata: {'source': 'מקווה'},
            ),
          );
        }
      case _Category.niftarim:
        if (lacks('נפטרים')) {
          docs.add(
            const KnowledgeDoc(
              content: 'מסך "נפטרים" מכיל מידע על הלכות נפטרים.',
              category: 'נפטרים',
              metadata: {'source': 'נפטרים'},
            ),
          );
        }
      case _Category.halacha:
        if (lacks('הלכה')) {
          docs.add(
            const KnowledgeDoc(
              content:
                  'מסך "טומאת כהנים" מכיל הלכות הנוגעות לכהנים בבית החולים.',
              category: 'הלכה',
              metadata: {'source': 'הלכה'},
            ),
          );
        }
      case _Category.contacts:
        if (lacks('אנשי קשר')) {
          docs.add(
            const KnowledgeDoc(
              content: 'מסך "אנשי קשר" מכיל פרטי יצירת קשר.',
              category: 'אנשי קשר',
              metadata: {'source': 'אנשי קשר'},
            ),
          );
        }
      default:
        break;
    }
  }

  // שולף מטבלת "כללי" לפי סוג
  static Future<List<KnowledgeDoc>> _fetchKlali(
    String type,
    String categoryLabel,
  ) async {
    final rows = await _supabase
        .from('כללי')
        .select('מידע, סוג')
        .eq('סוג', type);

    return (rows as List<dynamic>)
        .map(
          (r) => KnowledgeDoc(
            content: r['מידע']?.toString() ?? '',
            category: categoryLabel,
            metadata: {'source': 'כללי', 'type': type},
          ),
        )
        .where((d) => d.content.isNotEmpty)
        .toList();
  }

  // שולף מטבלת "שבת"
  static Future<List<KnowledgeDoc>> _fetchShabbat() async {
    final rows = await _supabase.from('שבת').select('מידע, סוג');

    return (rows as List<dynamic>)
        .map(
          (r) => KnowledgeDoc(
            content: r['מידע']?.toString() ?? '',
            category: 'שבת',
            metadata: {'source': 'שבת', 'type': r['סוג']?.toString() ?? ''},
          ),
        )
        .where((d) => d.content.isNotEmpty)
        .toList();
  }

  // שולף מטבלת "מועדי ישראל"
  static Future<List<KnowledgeDoc>> _fetchHolidays(String question) async {
    final rows = await _supabase.from('מועדי ישראל').select('מידע, סוג המועד');

    final all =
        (rows as List<dynamic>)
            .map(
              (r) => KnowledgeDoc(
                content: r['מידע']?.toString() ?? '',
                category: 'חגים',
                metadata: {
                  'source': 'מועדי ישראל',
                  'holiday': r['סוג המועד']?.toString() ?? '',
                },
              ),
            )
            .where((d) => d.content.isNotEmpty)
            .toList();

    // מסנן לחג ספציפי אם מוזכר בשאלה, אחרת מחזיר הכל
    final q = question.toLowerCase();
    final specific =
        all.where((d) {
          final holiday = d.metadata['holiday']?.toString() ?? '';
          return holiday.isNotEmpty && q.contains(holiday.toLowerCase());
        }).toList();

    return specific.isNotEmpty ? specific : all;
  }

  // שולף זמני תפילות ימי חול
  static Future<List<KnowledgeDoc>> _fetchPrayers() async {
    final rows = await _supabase
        .from('זמני תפילות ימי חול')
        .select('סוג תפילה, שעה, הערות');

    return (rows as List<dynamic>)
        .map((r) {
          final type = r['סוג תפילה']?.toString() ?? '';
          final time = r['שעה']?.toString() ?? '';
          final notes = r['הערות']?.toString() ?? '';
          final content = '$type — $time${notes.isNotEmpty ? ' ($notes)' : ''}';
          return KnowledgeDoc(
            content: content,
            category: 'תפילה',
            metadata: {'source': 'זמני תפילות ימי חול', 'type': type},
          );
        })
        .where((d) => d.content.trim() != '—')
        .toList();
  }

  // ── קריאה ל-Groq דרך Supabase RPC (PostgreSQL http extension) ──
  // Uses /rest/v1/rpc which works on all platforms including mobile browsers,
  // avoiding the Deno Deploy infrastructure used by Edge Functions.

  static Future<String> _generate(String prompt) async {
    debugPrint('[$_logTag] Sending prompt via RPC call_groq.');
    debugPrint('[$_logTag] Prompt length: ${prompt.length}');

    final data = await _supabase
        .rpc('call_groq', params: {
          'messages': [
            {'role': 'system', 'content': _systemPrompt},
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.3,
          'max_tokens': 1024,
        })
        .timeout(const Duration(seconds: 45));

    debugPrint('[$_logTag] RPC call_groq succeeded.');

    final answer =
        (data['choices'] as List?)?.firstOrNull?['message']?['content']
            as String? ??
        'לא התקבלה תשובה.';

    debugPrint('[$_logTag] Answer length: ${answer.length}');
    return answer;
  }

  // ── ask — הממשק הראשי ─────────────────────────────────────

  static Future<AiResponse> ask(String question) async {
    debugPrint('[$_logTag] ask() received question: $question');
    final docs = await searchKnowledge(question);
    debugPrint('[$_logTag] searchKnowledge returned ${docs.length} docs.');

    final context =
        docs.isEmpty
            ? 'לא נמצא מידע ספציפי במאגר המרכז לשאלה זו.'
            : docs.map((d) => '【${d.category}】 ${d.content}').join('\n\n');

    debugPrint('[$_logTag] Context length: ${context.length}');

    final prompt = 'מידע רשמי מהמאגר:\n$context\n\nשאלה: $question';

    final answer = await _generate(prompt);

    debugPrint('[$_logTag] ask() completed successfully.');

    return AiResponse(answer: answer, sources: docs);
  }
}
