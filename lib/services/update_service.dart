import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:rabbi_shiba/utils/app_colors.dart';

/// Manages flexible in-app updates (Android / Play Store only).
/// Call [checkAndPrompt] once per session from the home screen's initState.
class UpdateService {
  UpdateService._();

  static bool _checkedThisSession = false;

  static Future<void> checkAndPrompt(BuildContext context) async {
    // Flexible updates are Android / Play Store only — skip on web and iOS.
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    if (_checkedThisSession) return;
    _checkedThisSession = true;

    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) return;
      if (!context.mounted) return;

      final shouldUpdate = await _showUpdateDialog(context);
      if (!shouldUpdate || !context.mounted) return;

      final result = await InAppUpdate.startFlexibleUpdate();
      if (result != AppUpdateResult.success || !context.mounted) return;

      _showRestartSnackBar(context);
    } catch (e) {
      debugPrint('Update check skipped: $e');
    }
  }

  static Future<bool> _showUpdateDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder:
              (ctx) => Directionality(
                textDirection: TextDirection.rtl,
                child: AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Text(
                    'עדכון זמין',
                    style: GoogleFonts.alef(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  content: Text(
                    'קיימת גרסה חדשה של האפליקציה. מומלץ לעדכן כדי ליהנות מהתכונות והשיפורים האחרונים.',
                    style: GoogleFonts.alef(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(
                        'אולי מאוחר יותר',
                        style: GoogleFonts.alef(color: AppColors.textMuted),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      child: Text(
                        'עדכן עכשיו',
                        style: GoogleFonts.alef(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
        ) ??
        false;
  }

  static void _showRestartSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'העדכון הורד בהצלחה ומוכן להתקנה.',
          textDirection: TextDirection.rtl,
          style: GoogleFonts.alef(color: Colors.white),
        ),
        backgroundColor: AppColors.teal,
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: 'הפעלה מחדש',
          textColor: Colors.white,
          onPressed: () => InAppUpdate.completeFlexibleUpdate(),
        ),
      ),
    );
  }
}
