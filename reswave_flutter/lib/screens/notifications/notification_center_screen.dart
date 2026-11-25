import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/notification_model.dart';
import '../../services/api_client.dart';
import '../../services/push_notification_service.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final ResWaveApiService _apiService = ResWaveApiService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final list = await _apiService.getNotifications();
      if (mounted) setState(() => _notifications = list);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markRead(String notifId) async {
    try {
      await _apiService.markNotificationRead(notifId);
      setState(() {
        final idx = _notifications.indexWhere((n) => n.id == notifId);
        if (idx != -1) {
          final cur = _notifications[idx];
          _notifications[idx] = NotificationModel(
            id: cur.id,
            recipientId: cur.recipientId,
            type: cur.type,
            title: cur.title,
            body: cur.body,
            targetType: cur.targetType,
            targetId: cur.targetId,
            read: true,
            createdAt: cur.createdAt,
          );
        }
      });
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    try {
      await _apiService.markAllNotificationsRead();
      setState(() {
        _notifications = _notifications
            .map((cur) => NotificationModel(
                  id: cur.id,
                  recipientId: cur.recipientId,
                  type: cur.type,
                  title: cur.title,
                  body: cur.body,
                  targetType: cur.targetType,
                  targetId: cur.targetId,
                  read: true,
                  createdAt: cur.createdAt,
                ))
            .toList();
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: _notifications.isEmpty ? null : _markAllRead,
            child: const Text('Mark all read',
                style: TextStyle(color: AppColors.brightTeal)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: _notifications.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_none_rounded,
                                size: 56, color: AppColors.darkTextMuted),
                            SizedBox(height: 14),
                            Text('No notifications yet',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            SizedBox(height: 6),
                            Text(
                              'When peers send connection requests, mentor requests, or project updates, notifications appear here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.darkTextSecondary),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final n = _notifications[index];
                        final isRead = n.read;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          color: isRead
                              ? AppColors.darkSurface
                              : AppColors.darkSurfaceVariant,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isRead
                                  ? AppColors.darkBackground
                                  : AppColors.primaryTeal,
                              child: Icon(
                                n.type == 'Team'
                                    ? Icons.group_add_rounded
                                    : n.type == 'Mentorship'
                                        ? Icons.school_rounded
                                        : n.type == 'Connection'
                                            ? Icons.person_add_alt_1_rounded
                                            : n.type == 'Message'
                                                ? Icons
                                                    .chat_bubble_outline_rounded
                                                : Icons.event_note_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            title: Text(n.title,
                                style: TextStyle(
                                    fontWeight: isRead
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                    fontSize: 14)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 2),
                                Text(n.body,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.darkTextSecondary)),
                              ],
                            ),
                            trailing: isRead
                                ? null
                                : Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                        color: AppColors.brightTeal,
                                        shape: BoxShape.circle),
                                  ),
                            onTap: () async {
                              if (!isRead) await _markRead(n.id);
                              ResWavePushNotificationService.instance
                                  .handleNotificationTap({
                                'targetType': n.targetType ?? '',
                                'targetId': n.targetId ?? '',
                              });
                            },
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
