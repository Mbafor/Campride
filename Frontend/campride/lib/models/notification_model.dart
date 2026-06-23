class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final NotificationType type;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.isRead,
    required this.type,
  });

  static List<NotificationModel> mockNotifications() => [
        NotificationModel(
          id: 'notif_001',
          title: 'Shuttle Arriving Soon',
          message: 'Shuttle GR 1234-20 arrives at KSB in 3 minutes.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
          isRead: false,
          type: NotificationType.arrival,
        ),
        NotificationModel(
          id: 'notif_002',
          title: 'Route Delay',
          message: 'Main Campus Loop is delayed by 10 minutes due to traffic near Main Gate.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
          isRead: false,
          type: NotificationType.delay,
        ),
        NotificationModel(
          id: 'notif_003',
          title: 'Service Update',
          message: 'University Hospital Route is temporarily suspended until further notice.',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          isRead: true,
          type: NotificationType.info,
        ),
        NotificationModel(
          id: 'notif_004',
          title: 'Shuttle Full',
          message: 'Shuttle GR 5678-21 is at full capacity. Next shuttle in 15 minutes.',
          timestamp: DateTime.now().subtract(const Duration(hours: 3)),
          isRead: true,
          type: NotificationType.warning,
        ),
        NotificationModel(
          id: 'notif_005',
          title: 'Welcome to KNUST Shuttle Finder',
          message: 'Track shuttles in real time across campus. Tap the Live Map to get started.',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          isRead: true,
          type: NotificationType.info,
        ),
      ];
}

enum NotificationType { arrival, delay, info, warning }
