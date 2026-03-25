import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rabbi_shiba/services/data_service.dart';
import 'package:rabbi_shiba/utils/animation_helpers.dart';
import 'package:rabbi_shiba/utils/theme_helpers.dart';
import 'package:rabbi_shiba/widgets/state_widgets.dart';

class ShabatScreen extends StatefulWidget {
  const ShabatScreen({super.key});

  @override
  ShabatScreenState createState() => ShabatScreenState();
}

class ShabatScreenState extends State<ShabatScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> filteredData = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Use animation helpers for consistency
    _animationController = AnimationHelpers.createFadeController(
      this,
      durationMs: 1000,
    );
    _fadeAnimation = AnimationHelpers.createFadeAnimation(
      _animationController,
      curve: Curves.easeInOut,
    );
    loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    try {
      final data = await DataService.fetchWithCache<List<Map<String, dynamic>>>(
        'shabatData',
        _fetchShabbatFromSupabase,
        cacheDuration: const Duration(hours: 1),
      );

      if (data != null) {
        setState(() {
          filteredData = data;
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<List<Map<String, dynamic>>?> _fetchShabbatFromSupabase() async {
    try {
      final response = await Supabase.instance.client.from('שבת').select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  IconData _getIconForShabat(String type) {
    if (type.toLowerCase().contains('תפילה')) return FontAwesomeIcons.wineGlass;
    if (type.toLowerCase().contains('שיעור')) return FontAwesomeIcons.bookOpen;
    return FontAwesomeIcons.wineGlass;
  }

  Widget _buildBackground() {
    return ThemeHelpers.buildDefaultBackground();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ThemeHelpers.buildDefaultAppBar(
        title: 'מידע שבת',
        subtitle: 'כל מה שצריך לדעת לשבת',
        context: context,
      ),
      body: Stack(
        children: [
          Positioned.fill(child: _buildBackground()),
          FadeTransition(
            opacity: _fadeAnimation,
            child: StateBuilder(
              isLoading: _isLoading,
              hasError: filteredData.isEmpty && !_isLoading,
              contentBuilder: (_) => _buildContentList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentList() {
    if (filteredData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 50, color: Colors.white70),
            SizedBox(height: 16),
            Text(
              'לא נמצאו תוצאות',
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filteredData.length,
      itemBuilder: (context, index) {
        final item = filteredData[index];
        final info = item['מידע'] ?? '';
        final type = item['סוג'] ?? 'לא צוין סוג';

        return AnimatedSwitcher(
          duration: Duration(milliseconds: 300),
          child: Card(
            key: ValueKey(item['סוג']),
            margin: EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 5,
            color: Colors.deepPurple.withValues(alpha: 0.8),
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: Center(
                  child: Text(
                    type,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                leading: FaIcon(_getIconForShabat(type), color: Colors.white),
                iconColor: Colors.white,
                collapsedIconColor: Colors.white,
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      info,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

