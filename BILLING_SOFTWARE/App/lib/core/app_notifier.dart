import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';

enum NotificationType { success, error, warning, info }

class AppNotifier {
  static void show(
    BuildContext context, {
    required String message,
    String? title,
    NotificationType type = NotificationType.success,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
    if (scaffoldMessenger == null) return;

    scaffoldMessenger.hideCurrentSnackBar();

    final Color bgColor;
    final Color accentColor;
    final IconData iconData;
    final String defaultTitle;

    switch (type) {
      case NotificationType.success:
        bgColor = AppColors.isDark ? const Color(0xFF0F3823) : const Color(0xFFE8F5E9);
        accentColor = const Color(0xFF2ECC71);
        iconData = Icons.check_circle_rounded;
        defaultTitle = 'SUCCESS';
        break;
      case NotificationType.error:
        bgColor = AppColors.isDark ? const Color(0xFF3E1B1B) : const Color(0xFFFFEBEE);
        accentColor = const Color(0xFFE74C3C);
        iconData = Icons.error_rounded;
        defaultTitle = 'ERROR';
        break;
      case NotificationType.warning:
        bgColor = AppColors.isDark ? const Color(0xFF3D3213) : const Color(0xFFFFF8E1);
        accentColor = const Color(0xFFF39C12);
        iconData = Icons.warning_rounded;
        defaultTitle = 'WARNING';
        break;
      case NotificationType.info:
        bgColor = AppColors.isDark ? const Color(0xFF162D42) : const Color(0xFFE1F5FE);
        accentColor = const Color(0xFF3498DB);
        iconData = Icons.info_rounded;
        defaultTitle = 'INFORMATION';
        break;
    }

    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      elevation: 6,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      duration: duration,
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor.withAlpha(140), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: accentColor.withAlpha(35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withAlpha(35),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: accentColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title ?? defaultTitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.isDark ? const Color(0xFFF5F7FA) : const Color(0xFF1F2421),
                    ),
                  ),
                ],
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  scaffoldMessenger.hideCurrentSnackBar();
                  onAction();
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  backgroundColor: accentColor.withAlpha(30),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  actionLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    scaffoldMessenger.showSnackBar(snackBar);
  }

  static void success(BuildContext context, String message, {String? title, VoidCallback? onAction, String? actionLabel}) {
    show(context, message: message, title: title, type: NotificationType.success, onAction: onAction, actionLabel: actionLabel);
  }

  static void error(BuildContext context, String message, {String? title, VoidCallback? onAction, String? actionLabel}) {
    show(context, message: message, title: title, type: NotificationType.error, onAction: onAction, actionLabel: actionLabel);
  }

  static void warning(BuildContext context, String message, {String? title, VoidCallback? onAction, String? actionLabel}) {
    show(context, message: message, title: title, type: NotificationType.warning, onAction: onAction, actionLabel: actionLabel);
  }

  static void info(BuildContext context, String message, {String? title, VoidCallback? onAction, String? actionLabel}) {
    show(context, message: message, title: title, type: NotificationType.info, onAction: onAction, actionLabel: actionLabel);
  }
}
