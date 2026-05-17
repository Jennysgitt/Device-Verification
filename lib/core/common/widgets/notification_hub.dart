import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../backend/providers/notification_provider.dart';
import '../../theme/app_colors.dart';

class NotificationHub extends StatelessWidget {
  const NotificationHub({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final notifications = provider.notifications;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Notifications',
                      style: GoogleFonts.manrope(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (provider.hasUnread)
                      TextButton(
                        onPressed: provider.markAllAsRead,
                        child: const Text('Mark all as read'),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_none, size: 64, color: AppColors.onSurfaceVariant.withOpacity(0.2)),
                            const SizedBox(height: 16),
                            Text(
                              'No notifications yet',
                              style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final notification = notifications[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 0,
                            color: notification.isRead ? AppColors.surface : AppColors.primary.withOpacity(0.05),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: notification.isRead ? AppColors.surfaceVariant : AppColors.primary.withOpacity(0.2),
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(notification.category).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getCategoryIcon(notification.category),
                                  color: _getCategoryColor(notification.category),
                                ),
                              ),
                              title: Text(
                                notification.title,
                                style: GoogleFonts.inter(
                                  fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    notification.message,
                                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    DateFormat('MMM d, HH:mm').format(notification.createdAt),
                                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant.withOpacity(0.5)),
                                  ),
                                ],
                              ),
                              onTap: () => provider.markAsRead(notification.id),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'security_alert':
        return Icons.security;
      case 'announcement':
        return Icons.campaign;
      default:
        return Icons.notifications;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'security_alert':
        return AppColors.error;
      case 'announcement':
        return AppColors.primary;
      default:
        return AppColors.onSurfaceVariant;
    }
  }
}
