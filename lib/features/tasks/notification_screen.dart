import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_colors.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample notifications data
    final notifications = [
      NotificationItem(
        icon: LucideIcons.checkCircle,
        iconColor: AppColors.success,
        iconBgColor: AppColors.tagGreen,
        title: 'Tugas Selesai',
        message: 'Anda telah menyelesaikan "Proposal Klien"',
        time: '2 jam lalu',
        isRead: false,
      ),
      NotificationItem(
        icon: LucideIcons.clock,
        iconColor: AppColors.warning,
        iconBgColor: AppColors.tagRed,
        title: 'Deadline Mendekat',
        message: 'Ujian Midterm besok pukul 10:00',
        time: '4 jam lalu',
        isRead: false,
      ),
      NotificationItem(
        icon: LucideIcons.users,
        iconColor: AppColors.tagBlueText,
        iconBgColor: AppColors.tagBlue,
        title: 'Kolaborasi Baru',
        message: 'Bagus mengundang Anda ke Project Alpha',
        time: '1 hari lalu',
        isRead: true,
      ),
      NotificationItem(
        icon: LucideIcons.trophy,
        iconColor: AppColors.tagPurpleText,
        iconBgColor: AppColors.tagPurple,
        title: 'Achievement Unlocked!',
        message: 'Anda mendapat badge "Fokus 7 Hari"',
        time: '2 hari lalu',
        isRead: true,
      ),
      NotificationItem(
        icon: LucideIcons.fileText,
        iconColor: AppColors.tagGreenText,
        iconBgColor: AppColors.tagGreen,
        title: 'Note Baru',
        message: 'Catatan "Rumus Integral" telah disimpan',
        time: '3 hari lalu',
        isRead: true,
      ),
    ];

    final unreadCount = notifications.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        elevation: 0,
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () {
                // Mark all as read
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Semua notifikasi ditandai sudah dibaca')),
                );
              },
              child: const Text('Tandai Semua'),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.bellOff,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada notifikasi',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (unreadCount > 0) ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$unreadCount Baru',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                ...notifications.map((notification) => _buildNotificationItem(context, notification)),
              ],
            ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, NotificationItem notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.isRead
            ? Theme.of(context).cardColor
            : AppColors.primary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead
              ? Theme.of(context).dividerColor.withValues(alpha: 0.2)
              : AppColors.primary.withValues(alpha: 0.1),
          width: notification.isRead ? 1 : 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Handle notification tap
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Membuka: ${notification.title}')),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: notification.iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    notification.icon,
                    color: notification.iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.bold,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.clock,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            notification.time,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NotificationItem {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String message;
  final String time;
  final bool isRead;

  NotificationItem({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.message,
    required this.time,
    this.isRead = false,
  });
}
