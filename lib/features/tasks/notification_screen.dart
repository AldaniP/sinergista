import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/connection_service.dart';
import '../../core/services/task_service.dart';
import '../../core/models/connection_model.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _isLoading = true;
  final List<NotificationItem> _notifications = [];
  final _supabaseService = SupabaseService();
  final _connectionService = ConnectionService();
  final _taskService = TaskService();

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  // Helper to check if two dates are on the same day, ignoring time
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _fetchNotifications() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      _notifications.clear();

      // 1. Friend Requests
      try {
        final friendRequests = await _connectionService.getIncomingRequests();
        for (var request in friendRequests) {
          _notifications.add(NotificationItem(
            icon: LucideIcons.userPlus,
            iconColor: AppColors.primary,
            iconBgColor: AppColors.tagBlue,
            title: 'Permintaan Pertemanan',
            message:
                '${request.friendProfile.fullName} ingin berteman dengan Anda',
            time: 'Baru saja',
            isRead: false,
            type: NotificationType.friendRequest,
            actionData: request,
          ));
        }
      } catch (e) {
        debugPrint('Error fetching friend requests: $e');
      }

      // 2. Module Deadlines
      try {
        final modules = await _supabaseService.getModules();
        for (var module in modules) {
          if (module.rawDueDate != null) {
            final due = module.rawDueDate!;
            // Using helper to avoid robust time comparison issues

            if (_isSameDay(due, today)) {
              _notifications.add(NotificationItem(
                icon: LucideIcons.alertCircle,
                iconColor: AppColors.error,
                iconBgColor: AppColors.tagRed,
                title: 'Deadline Hari Ini!',
                message: 'Modul "${module.title}" harus selesai hari ini.',
                time: 'Hari ini',
                isRead: false,
                type: NotificationType.deadline,
              ));
            } else if (_isSameDay(due, tomorrow)) {
              _notifications.add(NotificationItem(
                icon: LucideIcons.clock,
                iconColor: AppColors.warning,
                iconBgColor: AppColors.tagPurple,
                title: 'Deadline Besok',
                message: 'Persiapkan diri untuk "${module.title}".',
                time: 'Besok',
                isRead: false,
                type: NotificationType.deadline,
              ));
            } else if (due.isBefore(today)) {
              // Optional: Show overdue items if desired, or skip
              // Adding overdue items helps users not miss things
              _notifications.add(NotificationItem(
                icon: LucideIcons.alertTriangle,
                iconColor: AppColors.error,
                iconBgColor: AppColors.tagRed,
                title: 'Deadline Terlewat',
                message: 'Modul "${module.title}" sudah lewat deadline.',
                time: DateFormat('dd MMM').format(due),
                isRead: false,
                type: NotificationType.deadline,
              ));
            }
          }
        }
      } catch (e) {
        debugPrint('Error fetching module deadlines: $e');
      }

      // 3. Task Deadlines
      try {
        final tasks = await _supabaseService.getTasks();
        for (var task in tasks) {
          if (task.dueDate != null && !task.isCompleted) {
            final due = task.dueDate!;

            if (_isSameDay(due, today)) {
              _notifications.add(NotificationItem(
                icon: LucideIcons.checkSquare,
                iconColor: AppColors.error,
                iconBgColor: AppColors.tagRed,
                title: 'Task Deadline Hari Ini!',
                message: 'Task "${task.title}" harus diselesaikan hari ini.',
                time: 'Hari ini',
                isRead: false,
                type: NotificationType.deadline,
              ));
            } else if (_isSameDay(due, tomorrow)) {
              _notifications.add(NotificationItem(
                icon: LucideIcons.checkSquare,
                iconColor: AppColors.warning,
                iconBgColor: AppColors.tagPurple,
                title: 'Task Deadline Besok',
                message: 'Jangan lupa "${task.title}".',
                time: 'Besok',
                isRead: false,
                type: NotificationType.deadline,
              ));
            }
            // Similar catch for overdue tasks (optional, keeping minimal for now to match user request)
          }
        }
      } catch (e) {
        debugPrint('Error fetching task deadlines: $e');
      }

      // 4. Achievements
      await _checkAchievements();

      // 5. Welcome message (only if NO REAL notifications)
      // Filter out system welcome messages if checking count
      if (_notifications.isEmpty) {
        _notifications.add(NotificationItem(
          icon: LucideIcons.checkCircle,
          iconColor: AppColors.success,
          iconBgColor: AppColors.tagGreen,
          title: 'Selamat Datang',
          message: 'Anda tidak memiliki notifikasi baru.',
          time: 'Baru saja',
          isRead: true, // Auto-read
          type: NotificationType.system,
        ));
      } else {
        // Sort: Unread first, then type?
        _notifications.sort((a, b) {
          if (a.isRead != b.isRead) {
            return a.isRead ? 1 : -1;
          }
          return 0;
        });
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkAchievements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final acknowledgedIds =
          prefs.getStringList('acknowledged_achievements') ?? [];

      // Calculate achievements (replicate logic from AchievementScreen)
      final completedTasks = await _taskService.getCompletedTaskCount();
      final modules = await _supabaseService.getModules();
      final totalSessions = await _supabaseService.getTotalSessionCount();

      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      final weekSessions = await _supabaseService.getFocusSessionsForDateRange(
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
        DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59),
      );
      final weekMinutes =
          weekSessions.fold<int>(0, (sum, s) => sum + (s.durationMinutes ?? 0));
      final hasLongSession =
          weekSessions.any((s) => (s.durationMinutes ?? 0) >= 120);

      final achievements = [
        {
          'id': 'first_steps',
          'title': 'First Steps',
          'unlocked': completedTasks >= 1
        },
        {
          'id': 'task_warrior',
          'title': 'Task Warrior',
          'unlocked': completedTasks >= 50
        },
        {
          'id': 'century_club',
          'title': 'Century Club',
          'unlocked': completedTasks >= 100
        },
        {
          'id': 'streak_master',
          'title': 'Streak Master',
          'unlocked': weekSessions.length >= 12
        },
        {
          'id': 'speed_learner',
          'title': 'Speed Learner',
          'unlocked': (weekMinutes / 60) >= 40
        },
        {
          'id': 'organizer_pro',
          'title': 'Organizer Pro',
          'unlocked': modules.length >= 5
        },
        {'id': 'marathoner', 'title': 'Marathoner', 'unlocked': hasLongSession},
        {
          'id': 'session_collector',
          'title': 'Session Collector',
          'unlocked': totalSessions >= 50
        },
        {
          'id': 'module_maestro',
          'title': 'Module Maestro',
          'unlocked': modules.length >= 10
        },
      ];

      for (var achievement in achievements) {
        if (achievement['unlocked'] == true &&
            !acknowledgedIds.contains(achievement['id'])) {
          _notifications.add(NotificationItem(
            icon: LucideIcons.trophy,
            iconColor: AppColors.warning,
            iconBgColor: AppColors.tagPurple,
            title: 'Achievement Unlocked!',
            message: 'Anda mendapatkan "${achievement['title']}"',
            time: 'Baru saja',
            isRead: false,
            type: NotificationType.achievement,
            actionData: achievement['id'],
          ));
        }
      }
    } catch (e) {
      debugPrint('Error checking achievements: $e');
    }
  }

  Future<void> _handleFriendRequest(
      ConnectionModel request, bool accept) async {
    try {
      if (accept) {
        await _connectionService.acceptRequest(request.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('${request.friendProfile.fullName} ditambahkan')),
          );
        }
      } else {
        await _connectionService.removeConnection(request.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permintaan ditolak')),
          );
        }
      }
      _fetchNotifications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _acknowledgeAchievement(String achievementId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final acknowledged =
          prefs.getStringList('acknowledged_achievements') ?? [];
      acknowledged.add(achievementId);
      await prefs.setStringList('acknowledged_achievements', acknowledged);
      _fetchNotifications();
    } catch (e) {
      debugPrint('Error acknowledging achievement: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter out system messages for unread count
    final unreadCount = _notifications
        .where((n) => !n.isRead && n.type != NotificationType.system)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        elevation: 0,
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () {
                setState(() {
                  for (var notification in _notifications) {
                    notification.isRead = true;
                  }
                });
              },
              child: const Text('Tandai Semua Dibaca'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications
                      .where((n) => n.type != NotificationType.system)
                      .isEmpty &&
                  _notifications.any((n) => n.type == NotificationType.system)
              ? _buildEmptyState() // Use improved empty state visual if only system message exists
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    return _buildNotificationItem(notification);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    // Return the Welcome Card as the "Empty State" or a nicer UI
    // The user showed a screenshot where "Welcome" was a card.
    // Let's keep the card but maybe style it better or just return it as item
    // Actually, if system message is there, the ListView will render it.
    // So I will revert the "Empty State" check in build to just rely on list
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return _buildNotificationItem(notification);
      },
    );
  }

  Widget _buildNotificationItem(NotificationItem notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead
              ? Theme.of(context).dividerColor
              : AppColors.primary.withOpacity(0.3),
          width: notification.isRead ? 1 : 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() => notification.isRead = true);
            if (notification.type == NotificationType.achievement) {
              _acknowledgeAchievement(notification.actionData as String);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: notification.iconBgColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    notification.icon,
                    color: notification.iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: notification.isRead
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      if (notification.type ==
                          NotificationType.friendRequest) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () => _handleFriendRequest(
                                notification.actionData as ConnectionModel,
                                true,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                              ),
                              child: const Text('Terima'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () => _handleFriendRequest(
                                notification.actionData as ConnectionModel,
                                false,
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                              ),
                              child: const Text('Tolak'),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        notification.time,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
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
          ),
        ),
      ),
    );
  }
}

enum NotificationType {
  friendRequest,
  deadline,
  achievement,
  system,
}

class NotificationItem {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String message;
  final String time;
  bool isRead;
  final NotificationType type;
  final dynamic actionData;

  NotificationItem({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.message,
    required this.time,
    this.isRead = false,
    this.type = NotificationType.system,
    this.actionData,
  });
}
