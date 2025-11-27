import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../core/constants/app_colors.dart';

class AchievementScreen extends StatelessWidget {
  const AchievementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Achievement'),
            Text(
              '4 dari 9 lencana didapat',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Progress Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.orange, Colors.deepOrange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.trophy,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Progress Keseluruhan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        LinearPercentIndicator(
                          padding: EdgeInsets.zero,
                          lineHeight: 8,
                          percent: 0.44,
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                          progressColor: Colors.white,
                          barRadius: const Radius.circular(10),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '44% selesai',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Achievement Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.75,
              children: [
                _buildAchievementCard(
                  context,
                  icon: LucideIcons.target,
                  title: 'First Steps',
                  description: 'Selesaikan tugas pertama Anda',
                  date: '10 Nov 2025',
                  isUnlocked: true,
                  color: Colors.orange,
                ),
                _buildAchievementCard(
                  context,
                  icon: LucideIcons.zap,
                  title: 'Productive Week',
                  description: 'Fokus selama 20 jam dalam seminggu',
                  date: '15 Nov 2025',
                  isUnlocked: true,
                  color: Colors.orange,
                ),
                _buildAchievementCard(
                  context,
                  icon: LucideIcons.users,
                  title: 'Team Player',
                  description: 'Kolaborasi dengan 5 pengguna',
                  date: '12 Nov 2025',
                  isUnlocked: true,
                  color: Colors.orange,
                ),
                _buildAchievementCard(
                  context,
                  icon: LucideIcons.dollarSign,
                  title: 'Budget Master',
                  description: 'Catat transaksi selama 30 hari berturut-turut',
                  date: '8 Nov 2025',
                  isUnlocked: true,
                  color: Colors.orange,
                ),
                _buildAchievementCard(
                  context,
                  icon: LucideIcons.folderOpen,
                  title: 'Organizer Pro',
                  description: 'Kelola 10 modul aktif sekaligus',
                  date: null,
                  progress: 0.7,
                  progressText: '7/10',
                  isUnlocked: false,
                  color: Colors.grey,
                ),
                _buildAchievementCard(
                  context,
                  icon: LucideIcons.award,
                  title: 'Century Club',
                  description: 'Selesaikan 100 tugas',
                  date: null,
                  progress: 0.85,
                  progressText: '85/100',
                  isUnlocked: false,
                  color: Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required String? date,
    required bool isUnlocked,
    required Color color,
    double? progress,
    String? progressText,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? color
                  : Theme.of(context).dividerColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isUnlocked ? icon : LucideIcons.lock,
              color: isUnlocked
                  ? Colors.white
                  : Theme.of(context).iconTheme.color?.withValues(alpha: 0.3),
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          if (isUnlocked && date != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                date,
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                ),
              ),
            ),
          if (!isUnlocked && progress != null)
            Column(
              children: [
                LinearPercentIndicator(
                  padding: EdgeInsets.zero,
                  lineHeight: 6,
                  percent: progress,
                  backgroundColor: Theme.of(
                    context,
                  ).dividerColor.withValues(alpha: 0.1),
                  progressColor: AppColors.primary,
                  barRadius: const Radius.circular(10),
                ),
                const SizedBox(height: 4),
                Text(
                  progressText ?? '',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
