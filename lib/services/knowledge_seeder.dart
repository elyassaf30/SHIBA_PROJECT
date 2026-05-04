import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────
// Knowledge Seeder
// מריץ פעם אחת כדי למלא את knowledge_base
// מהטבלאות הקיימות ב-Supabase
// ─────────────────────────────────────────────

class KnowledgeSeeder {
  static final _supabase = Supabase.instance.client;

  static const _sources = [
    _SourceConfig(tableName: 'כללי', category: 'כשרות',    filterColumn: 'type', filterValue: 'כשרות',         contentColumn: 'content'),
    _SourceConfig(tableName: 'כללי', category: 'הלכה',     filterColumn: 'type', filterValue: 'טומאת כהנים',   contentColumn: 'content'),
    _SourceConfig(tableName: 'כללי', category: 'הלכה',     filterColumn: 'type', filterValue: 'שאילת תפילין',  contentColumn: 'content'),
    _SourceConfig(tableName: 'שבת',          category: 'שבת',    contentColumn: 'content'),
    _SourceConfig(tableName: 'מועדי ישראל', category: 'חגים',   contentColumn: 'content'),
    _SourceConfig(tableName: 'זמני תפילות ימי חול', category: 'תפילה', contentColumn: 'content'),
  ];

  /// מריץ את כל תהליך ה-seeding.
  /// קרא לפונקציה זו פעם אחת מהמסך הניהולי.
  /// [onProgress] — callback לעדכון ממשק המשתמש (0.0 עד 1.0)
  static Future<SeedResult> seed({
    void Function(double progress, String status)? onProgress,
  }) async {
    int totalInserted = 0;
    int totalFailed = 0;

    // ניקוי נתונים ישנים
    onProgress?.call(0.0, 'מנקה נתונים ישנים...');
    try {
      await _supabase.from('knowledge_base').delete().neq('id', 0);
    } catch (e) {
      debugPrint('⚠️ ניקוי knowledge_base נכשל: $e');
    }

    final total = _sources.length;

    for (var i = 0; i < total; i++) {
      final source = _sources[i];
      onProgress?.call(i / total, 'מעבד: ${source.category}...');

      try {
        final rows = await _fetchRows(source);
        debugPrint('📥 ${rows.length} רשומות מ-${source.tableName}');

        final batch = rows
            .map((row) => _buildContent(row, source))
            .where((c) => c.isNotEmpty)
            .map((content) => {
                  'content': content,
                  'category': source.category,
                  'metadata': {'source': source.tableName},
                })
            .toList();

        if (batch.isNotEmpty) {
          await _supabase.from('knowledge_base').insert(batch);
          totalInserted += batch.length;
        }
      } catch (e) {
        debugPrint('❌ שגיאה ב-${source.tableName}: $e');
        totalFailed++;
      }
    }

    onProgress?.call(1.0, 'הושלם!');
    debugPrint('✅ Seeding: $totalInserted הוכנסו, $totalFailed נכשלו');
    return SeedResult(inserted: totalInserted, failed: totalFailed);
  }

  static Future<List<Map<String, dynamic>>> _fetchRows(_SourceConfig src) async {
    var query = _supabase.from(src.tableName).select();
    if (src.filterColumn != null && src.filterValue != null) {
      query = _supabase
          .from(src.tableName)
          .select()
          .eq(src.filterColumn!, src.filterValue!);
    }
    return List<Map<String, dynamic>>.from(await query);
  }

  static String _buildContent(Map<String, dynamic> row, _SourceConfig src) {
    final val = row[src.contentColumn];
    if (val == null) return '';
    return val.toString().trim();
  }
}

// ─────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────

class _SourceConfig {
  final String tableName;
  final String category;
  final String contentColumn;
  final String? filterColumn;
  final String? filterValue;

  const _SourceConfig({
    required this.tableName,
    required this.category,
    required this.contentColumn,
    this.filterColumn,
    this.filterValue,
  });
}

class SeedResult {
  final int inserted;
  final int failed;

  const SeedResult({required this.inserted, required this.failed});

  bool get success => failed == 0;

  @override
  String toString() => 'הוכנסו: $inserted, נכשלו: $failed';
}
