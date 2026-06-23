import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/notification_model.dart';
import '../../../theme/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late List<NotificationModel> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = NotificationModel.mockNotifications();
  }

  IconData _iconForType(NotificationType type) {
    switch (type) {
      case NotificationType.arrival: return Icons.directions_bus;
      case NotificationType.delay: return Icons.schedule;
      case NotificationType.warning: return Icons.warning_amber_outlined;
      case NotificationType.info: return Icons.info_outline;
    }
  }

  Color _colorForType(NotificationType type) {
    switch (type) {
      case NotificationType.arrival: return AppColors.primaryGreen;
      case NotificationType.delay: return AppColors.warning;
      case NotificationType.warning: return AppColors.error;
      case NotificationType.info: return AppColors.info;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d').format(time);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => setState(() {
              _notifications = _notifications.map((n) => NotificationModel(
                id: n.id, title: n.title, message: n.message,
                timestamp: n.timestamp, isRead: true, type: n.type,
              )).toList();
            }),
            child: Text('Mark all read', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
      body: _notifications.isEmpty
          ? const Center(child: Text('No notifications'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final n = _notifications[i];
                final color = _colorForType(n.type);
                return Dismissible(
                  key: Key(n.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete_outline, color: AppColors.error),
                  ),
                  onDismissed: (_) => setState(() => _notifications.removeAt(i)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: n.isRead
                          ? Theme.of(context).cardTheme.color
                          : color.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: n.isRead ? null : Border.all(color: color.withOpacity(0.2)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_iconForType(n.type), color: color, size: 22),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              n.title,
                              style: GoogleFonts.poppins(
                                fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (!n.isRead)
                            Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            n.message,
                            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondaryLight),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(n.timestamp),
                            style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondaryLight),
                          ),
                        ],
                      ),
                      onTap: () => setState(() {
                        _notifications[i] = NotificationModel(
                          id: n.id, title: n.title, message: n.message,
                          timestamp: n.timestamp, isRead: true, type: n.type,
                        );
                      }),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
