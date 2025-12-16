import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/supabase_service.dart';

class HistoryScreen extends StatefulWidget {
  final String? initialFilterType; // 'exam' or 'productivity_quiz' or null
  final bool lockFilter;

  const HistoryScreen(
      {super.key, this.initialFilterType, this.lockFilter = false});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;
  String? _filterType;

  @override
  void initState() {
    super.initState();
    _filterType = widget.initialFilterType;
    _fetchHistory();
    // Trigger cleanup on load
    _supabaseService.cleanupOldHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    try {
      final data =
          await _supabaseService.getAssessmentHistory(type: _filterType);
      if (mounted) {
        setState(() {
          _history = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteHistory(String id) async {
    try {
      await _supabaseService.deleteAssessmentHistory(id);
      if (mounted) {
        setState(() {
          _history.removeWhere((item) => item['id'] == id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Riwayat dihapus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus: $e')),
        );
      }
    }
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString).toLocal();
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lockFilter
            ? (widget.initialFilterType == 'exam'
                ? 'Riwayat Exam'
                : 'Riwayat Quiz')
            : 'Riwayat Aktivitas'),
        actions: widget.lockFilter
            ? []
            : [
                PopupMenuButton<String?>(
                  initialValue: _filterType,
                  onSelected: (value) {
                    setState(() {
                      _filterType = value;
                    });
                    _fetchHistory();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: null,
                      child: Text('Semua'),
                    ),
                    const PopupMenuItem(
                      value: 'exam',
                      child: Text('Exam'),
                    ),
                    const PopupMenuItem(
                      value: 'productivity_quiz',
                      child: Text('Quiz Produktivitas'),
                    ),
                  ],
                  icon: const Icon(LucideIcons.filter),
                ),
              ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.history,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada riwayat',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final item = _history[index];
                    final score = item['score'] ?? 0;
                    final total = item['total_questions'] ?? 0;
                    final type = item['type'] ?? 'exam';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: type == 'exam'
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : AppColors.success.withValues(alpha: 0.1),
                          child: Icon(
                            type == 'exam'
                                ? LucideIcons.graduationCap
                                : LucideIcons.zap,
                            color: type == 'exam'
                                ? AppColors.primary
                                : AppColors.success,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          item['title'] ?? 'Tanpa Judul',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(_formatDate(item['created_at'])),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(LucideIcons.checkCircle,
                                    size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  'Skor: ${num.parse(score.toString()).toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 12),
                                Icon(LucideIcons.list,
                                    size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  '$total Soal',
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon:
                              const Icon(LucideIcons.trash2, color: Colors.red),
                          onPressed: () => showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Hapus Riwayat?'),
                              content: const Text(
                                  'Data ini tidak dapat dikembalikan.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Batal'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _deleteHistory(item['id']);
                                  },
                                  style: TextButton.styleFrom(
                                      foregroundColor: Colors.red),
                                  child: const Text('Hapus'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
