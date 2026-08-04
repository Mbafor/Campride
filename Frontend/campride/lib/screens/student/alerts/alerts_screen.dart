import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import '../../../providers/authentication_provider.dart';
import '../../../theme/app_theme.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final auth = context.read<AuthenticationProvider>();
      if (auth.accessToken == null) {
        setState(() {
          _errorMessage = 'Authentication failed';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseHttpUrl}/notifications'),
        headers: {
          'Authorization': 'Bearer ${auth.accessToken}',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _notifications = List<Map<String, dynamic>>.from(data['notifications'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load notifications';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading notifications: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      final auth = context.read<AuthenticationProvider>();
      if (auth.accessToken == null) return;

      await http.put(
        Uri.parse('${ApiConfig.baseHttpUrl}/notifications/$notificationId/read'),
        headers: {
          'Authorization': 'Bearer ${auth.accessToken}',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      // Reload notifications to reflect the read status
      if (mounted) {
        _loadNotifications();
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: context.textPrimary),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          'Alerts',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: context.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: Text(
                'Notifications',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.poppins(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : _notifications.isEmpty
                          ? Center(
                              child: Text(
                                'No notifications yet',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: context.textSecondary,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _notifications.length,
                              itemBuilder: (context, index) {
                                final notif = _notifications[index];
                                return _NotificationTile(
                                  notification: notif,
                                  onTap: () => _markAsRead(notif['id']),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  String _formatDateTime(String dateTimeString) {
    try {
      final dt = DateTime.parse(dateTimeString);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) {
        return 'now';
      } else if (diff.inHours < 1) {
        return '${diff.inMinutes}m ago';
      } else if (diff.inDays < 1) {
        return '${diff.inHours}h ago';
      } else {
        return '${dt.day}/${dt.month}/${dt.year}';
      }
    } catch (e) {
      return dateTimeString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRead = notification['is_read'] == true;
    final type = notification['type'] ?? 'notification';
    final message = notification['message'] ?? '';
    final createdAt = notification['created_at'] ?? '';
    final formattedTime = _formatDateTime(createdAt);

    return GestureDetector(
      onTap: isRead ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isRead ? context.cardBg : AppColors.primaryGreen.withValues(alpha: 0.08),
          border: Border.all(
            color: isRead ? context.divider : AppColors.primaryGreen,
            width: isRead ? 1 : 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isRead ? context.divider : AppColors.primaryGreen,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconForType(type),
                color: isRead ? context.textSecondary : Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: isRead ? FontWeight.w400 : FontWeight.w500,
                      color: isRead ? context.textSecondary : context.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$formattedTime • $type',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'shuttle':
        return Icons.directions_bus;
      case 'driver':
        return Icons.person;
      case 'system':
        return Icons.notifications;
      default:
        return Icons.info;
    }
  }
}
