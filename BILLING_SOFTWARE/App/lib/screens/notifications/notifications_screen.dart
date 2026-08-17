import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/localization.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/theme_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    _refreshNotifications();
  }

  Future<void> _refreshNotifications() async {
    final auth = context.read<AuthProvider>();
    if (auth.apiService.baseUrl.isNotEmpty) {
      await context.read<NotificationProvider>().fetchNotifications(auth.apiService);
    }
  }

  String _localizeNotifTitle(BuildContext context, String rawTitle) {
    if (rawTitle.toLowerCase().contains('cloud backup completed') || rawTitle.toLowerCase().contains('cloud backup')) {
      return context.tr('cloud_backup_completed');
    }
    return context.tr(rawTitle);
  }

  String _localizeNotifMessage(BuildContext context, String rawMessage) {
    final reg = RegExp(r'(\d+)\s*products?,\s*(\d+)\s*sales?,\s*(\d+)\s*customers?', caseSensitive: false);
    final match = reg.firstMatch(rawMessage);
    if (match != null) {
      final pCount = match.group(1) ?? '0';
      final sCount = match.group(2) ?? '0';
      final cCount = match.group(3) ?? '0';
      return '$pCount ${context.tr('products_unit')}, $sCount ${context.tr('invoices_unit')}, $cCount ${context.tr('customers')} (${context.tr('auto_cloud_backup_active')})';
    }
    return context.tr(rawMessage);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final auth = context.watch<AuthProvider>();
    final notifProvider = context.watch<NotificationProvider>();
    final notifications = notifProvider.notifications;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          context.tr('notifications').toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: () => notifProvider.markAllAsRead(auth.apiService),
              child: Text(
                context.tr('mark_all_read'),
                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.terracotta),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshNotifications,
        color: AppColors.terracotta,
        child: notifProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : notifications.isEmpty
                ? Center(
                    child: Text(context.tr('no_notifications'), style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary)),
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.all(20),
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = notifications[index];
                      IconData icon;
                      Color color;

                      switch (item.type) {
                        case 'warning':
                          icon = Icons.warning_amber_rounded;
                          color = AppColors.warning;
                          break;
                        case 'success':
                          icon = Icons.check_circle_rounded;
                          color = AppColors.forestMint;
                          break;
                        default:
                          icon = Icons.info_outline_rounded;
                          color = AppColors.info;
                          break;
                      }

                      return InkWell(
                        onTap: () => notifProvider.markAsRead(auth.apiService, item.id),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: item.isRead ? AppColors.surface : AppColors.primaryContainer.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(icon, color: color, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _localizeNotifTitle(context, item.title),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _localizeNotifMessage(context, item.message),
                                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
