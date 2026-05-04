import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
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
// AI Service — Groq API (חינמי, מהיר)
// ─────────────────────────────────────────────

class AiService {
  static final _supabase = Supabase.instance.client;

  // Groq: חינמי, 14,400 בקשות ביום, מהיר מאוד
  static const _groqUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const _model = 'llama-3.3-70b-versatile';

  static const _systemPrompt =
      'אתה עוזר AI של מרכז רפואי שיבא, המתמחה בנושאי כשרות, שבת, חגים, הלכות ומידע תורני. '
      'ענה תמיד בעברית רהוטה ומנומסת. '
      'אם יש מידע רלוונטי בהקשר — הסתמך עליו. '
      'אם אין מידע ספציפי — ענה על בסיס ידע תורני כללי. '
      'הצג תשובות קצרות וברורות.';

  static String _readApiKey() {
    const defined = String.fromEnvironment('GROQ_API_KEY');
    if (defined.isNotEmpty) return defined;
    try {
      return dotenv.env['GROQ_API_KEY'] ?? '';
    } catch (_) {
      return '';
    }
  }

  // ── קריאה ל-Groq (OpenAI-compatible API) ─────────────────

  static Future<String> _generate(String prompt) async {
    final apiKey = _readApiKey();
    if (apiKey.isEmpty || apiKey == 'YOUR_GROQ_API_KEY_HERE') {
      throw Exception('GROQ_API_KEY חסר — הוסף ל-.env');
    }

    final response = await http
        .post(
          Uri.parse(_groqUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'model': _model,
            'messages': [
              {'role': 'system', 'content': _systemPrompt},
              {'role': 'user', 'content': prompt},
            ],
            'temperature': 0.4,
            'max_tokens': 1024,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return (data['choices'] as List?)
              ?.firstOrNull?['message']?['content'] as String? ??
          'לא התקבלה תשובה.';
    }

    if (response.statusCode == 429) {
      throw Exception('יותר מדי בקשות. נסה שוב בעוד מספר שניות.');
    }

    if (response.statusCode == 401) {
      throw Exception('GROQ_API_KEY לא תקין. בדוק את המפתח ב-.env');
    }

    debugPrint('❌ Groq error ${response.statusCode}: ${response.body}');
    throw Exception('שגיאה בשרת AI. נסה שוב.');
  }

  // ── חיפוש ב-Supabase לפי מילות מפתח ─────────────────────

  static Future<List<KnowledgeDoc>> searchKnowledge(
    String query, {
    int matchCount = 5,
  }) async {
    try {
      final keywords = query.split(' ').where((w) => w.length > 2).toList();

      for (final keyword in keywords) {
        final response = await _supabase
            .from('knowledge_base')
            .select('content, category, metadata')
            .ilike('content', '%$keyword%')
            .limit(matchCount);

        final rows = response as List<dynamic>;
        if (rows.isNotEmpty) {
          return rows
              .map((row) => KnowledgeDoc(
                    content: row['content'] as String,
                    category: row['category'] as String,
                    metadata: Map<String, dynamic>.from(
                      row['metadata'] as Map? ?? {},
                    ),
                  ))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('⚠️ searchKnowledge: $e');
      return [];
    }
  }

  // ── ask — הממשק הראשי ─────────────────────────────────────

  static Future<AiResponse> ask(String question) async {
    final docs = await searchKnowledge(question);

    final context = docs.isEmpty
        ? ''
        : docs.map((d) => '【${d.category}】 ${d.content}').join('\n\n');

    final prompt = context.isEmpty
        ? 'שאלה: $question'
        : 'מידע רלוונטי:\n$context\n\nשאלה: $question';

    final answer = await _generate(prompt);

    return AiResponse(answer: answer, sources: docs);
  }
}
