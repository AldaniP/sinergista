import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/models/journal_model.dart';

class JournalDetailScreen extends StatelessWidget {
  final JournalModel journal;

  const JournalDetailScreen({super.key, required this.journal});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Jurnal'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Tanggal & Mood
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.calendar,
                      size: 16,
                      color:
                          isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      journal.formattedDate,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: journal.moodColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: journal.moodColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(journal.mood, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 6),
                      Text(
                        _getMoodLabel(journal.mood),
                        style: TextStyle(
                          color: journal.moodColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Judul
            Text(
              journal.title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
                height: 1.2,
              ),
            ),

            const SizedBox(height: 24),

            // Garis Pembatas
            Divider(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            ),

            const SizedBox(height: 24),

            // Isi Konten (Full Text)
            Text(
              journal.content,
              style: TextStyle(
                fontSize: 16,
                height: 1.6, // Spasi antar baris biar enak dibaca
                color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
              ),
            ),

            const SizedBox(height: 32),

            // Tags
            if (journal.tags.isNotEmpty) ...[
              Text(
                'Tags'.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: journal.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2C2C2C)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#$tag',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? Colors.grey.shade300
                            : Colors.grey.shade700,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper kecil untuk label mood
  String _getMoodLabel(String mood) {
    switch (mood) {
      case '😊':
        return 'Senang';
      case '😁':
        return 'Bahagia';
      case '😐':
        return 'Biasa';
      case '🤔':
        return 'Berpikir';
      case '😢':
        return 'Sedih';
      case '😠':
        return 'Marah';
      default:
        return 'Mood';
    }
  }
}
