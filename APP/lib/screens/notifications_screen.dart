import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/api_service.dart';
import '../core/theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final res = await ApiService.getNotifications();
      if (res['success'] == true && mounted) {
        setState(() {
          _notifications = res['data']['notifications'] ?? [];
          _isLoading = false;
        });
        
        // Mark all as read in background
        if (_notifications.any((n) => n['read'] == false)) {
          ApiService.markAllNotificationsRead();
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w600, color: EcoColors.primary),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: EcoColors.primary),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: EcoColors.primaryContainer))
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: EcoColors.primaryContainer,
                  onRefresh: _fetchNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notif = _notifications[index];
                      final isRead = notif['read'] == true;
                      
                      IconData typeIcon = Icons.notifications;
                      if (notif['type'] == 'transaction') typeIcon = Icons.swap_horiz;
                      else if (notif['type'] == 'reward') typeIcon = Icons.emoji_events;
                      
                      final timeStr = notif['timestamp'] != null 
                          ? DateFormat('MMM d, h:mm a').format(DateTime.parse(notif['timestamp']).toLocal())
                          : '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isRead ? EcoColors.surfaceContainerLow : EcoColors.surfaceContainerHighest.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: isRead ? null : Border.all(color: EcoColors.primaryContainer.withOpacity(0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: EcoColors.surfaceContainerHighest,
                              ),
                              child: Icon(typeIcon, size: 16, color: EcoColors.primaryContainer),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          notif['title'] ?? 'Alert',
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 14, 
                                            fontWeight: isRead ? FontWeight.w600 : FontWeight.w700, 
                                            color: EcoColors.primary
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        timeStr,
                                        style: GoogleFonts.inter(fontSize: 10, color: EcoColors.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    notif['message'] ?? '',
                                    style: GoogleFonts.inter(
                                      fontSize: 13, 
                                      color: isRead ? EcoColors.onSurfaceVariant : EcoColors.primary
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.05);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: EcoColors.surfaceContainerHigh,
            ),
            child: const Icon(Icons.notifications_off, size: 48, color: EcoColors.onSurfaceVariant),
          ).animate().scale(delay: 200.ms, duration: 400.ms),
          const SizedBox(height: 24),
          Text(
            'No notifications yet',
            style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w600, color: EcoColors.primary),
          ),
          const SizedBox(height: 8),
          Text(
            "We'll let you know when something happens.",
            style: GoogleFonts.inter(fontSize: 14, color: EcoColors.onSurfaceVariant),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }
}
