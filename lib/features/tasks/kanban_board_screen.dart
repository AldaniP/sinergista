import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sinergista/features/tasks/models/kanban_task_model.dart';
import 'package:sinergista/features/tasks/services/kanban_service.dart';
import 'module_model.dart';

class KanbanBoardScreen extends StatefulWidget {
  final Module module;

  const KanbanBoardScreen({super.key, required this.module});

  @override
  State<KanbanBoardScreen> createState() => _KanbanBoardScreenState();
}

class _KanbanBoardScreenState extends State<KanbanBoardScreen> {
  final KanbanService _kanbanService = KanbanService();
  late Map<String, List<KanbanTask>> _columns;
  final TextEditingController _cardController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeColumns();
    _fetchTasks();
  }

  void _initializeColumns() {
    _columns = {'To Do': [], 'In Progress': [], 'Review': [], 'Done': []};
  }

  Future<void> _fetchTasks() async {
    setState(() => _isLoading = true);
    try {
      final tasks = await _kanbanService.fetchTasks(widget.module.id);

      _initializeColumns(); // Reset columns
      for (var task in tasks) {
        if (_columns.containsKey(task.status)) {
          _columns[task.status]!.add(task);
        } else {
          // Fallback if status is unknown, maybe add to To Do or ignore
          if (_columns['To Do'] != null) {
            _columns['To Do']!.add(task);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat kartu: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addCard(String columnName) async {
    if (_cardController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Teks kartu tidak boleh kosong')),
      );
      return;
    }

    final title = _cardController.text.trim();
    _cardController.clear();
    Navigator.pop(context);

    try {
      final newTask = await _kanbanService.addTask(
        widget.module.id,
        title,
        columnName,
      );

      setState(() {
        _columns[columnName]!.add(newTask);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kartu berhasil ditambahkan')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menambahkan kartu: $e')));
      }
    }
  }

  void _showAddCardDialog(String columnName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tambah Kartu ke $columnName'),
        content: TextField(
          controller: _cardController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Deskripsi tugas...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => _addCard(columnName),
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  Future<void> _editTask(KanbanTask task, String newTitle) async {
    final oldTitle = task.title;

    // Optimistic update
    setState(() {
      final taskIndex = _columns[task.status]!.indexWhere(
        (t) => t.id == task.id,
      );
      if (taskIndex != -1) {
        _columns[task.status]![taskIndex] = KanbanTask(
          id: task.id,
          moduleId: task.moduleId,
          title: newTitle, // Update title
          status: task.status,
          createdAt: task.createdAt,
        );
      }
    });

    try {
      await _kanbanService.updateTaskTitle(task.id, newTitle);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kartu berhasil diperbarui')),
        );
      }
    } catch (e) {
      // Revert if failed
      if (mounted) {
        setState(() {
          final taskIndex = _columns[task.status]!.indexWhere(
            (t) => t.id == task.id,
          );
          if (taskIndex != -1) {
            _columns[task.status]![taskIndex] = KanbanTask(
              id: task.id,
              moduleId: task.moduleId,
              title: oldTitle, // Revert title
              status: task.status,
              createdAt: task.createdAt,
            );
          }
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memperbarui kartu: $e')));
      }
    }
  }

  void _showEditTaskDialog(KanbanTask task) {
    _cardController.text = task.title;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Kartu'),
        content: TextField(
          controller: _cardController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Deskripsi tugas...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_cardController.text.trim().isNotEmpty) {
                _editTask(task, _cardController.text.trim());
                _cardController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCard(String columnName, int index) async {
    final task = _columns[columnName]![index];

    // Optimistic update
    setState(() {
      _columns[columnName]!.removeAt(index);
    });

    try {
      await _kanbanService.deleteTask(task.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Kartu berhasil dihapus')));
      }
    } catch (e) {
      // Revert if failed
      if (mounted) {
        setState(() {
          _columns[columnName]!.insert(index, task);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menghapus kartu: $e')));
      }
    }
  }

  @override
  void dispose() {
    _cardController.dispose();
    super.dispose();
  }

  Future<void> _moveTask(KanbanTask task, String newStatus) async {
    if (task.status == newStatus) return;

    final oldStatus = task.status;

    // Optimistic update
    setState(() {
      _columns[oldStatus]?.removeWhere((t) => t.id == task.id);

      final updatedTask = KanbanTask(
        id: task.id,
        moduleId: task.moduleId,
        title: task.title,
        status: newStatus,
        createdAt: task.createdAt,
      );

      _columns[newStatus]?.add(updatedTask);
    });

    try {
      await _kanbanService.updateTaskStatus(task.id, newStatus);
    } catch (e) {
      // Revert if failed
      if (mounted) {
        setState(() {
          _columns[newStatus]?.removeWhere((t) => t.id == task.id);
          _columns[oldStatus]?.add(task);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memindahkan kartu: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kanban Board', style: Theme.of(context).textTheme.titleLarge),
            Text(
              widget.module.title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ..._columns.entries.map((entry) {
                    final columnName = entry.key;
                    final cards = entry.value;

                    return DragTarget<KanbanTask>(
                      onWillAcceptWithDetails: (details) =>
                          details.data.status != columnName,
                      onAcceptWithDetails: (details) =>
                          _moveTask(details.data, columnName),
                      builder: (context, candidateData, rejectedData) {
                        return Container(
                          width: 320,
                          margin: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: candidateData.isNotEmpty
                                ? Border.all(
                                    color: _getColumnColor(columnName),
                                    width: 2,
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Column Header
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _getColumnColor(
                                    columnName,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '$columnName (${cards.length})',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _getColumnColor(columnName),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () =>
                                          _showAddCardDialog(columnName),
                                      icon: const Icon(
                                        LucideIcons.plus,
                                        size: 18,
                                      ),
                                      iconSize: 18,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Cards List
                              Expanded(
                                child: ListView.builder(
                                  itemCount: cards.length,
                                  itemBuilder: (context, index) {
                                    final card = cards[index];
                                    return LongPressDraggable<KanbanTask>(
                                      data: card,
                                      feedback: Material(
                                        elevation: 4,
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          width: 300,
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).cardColor,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            card.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                      childWhenDragging: Opacity(
                                        opacity: 0.5,
                                        child: _buildCardItem(
                                          context,
                                          card,
                                          columnName,
                                          index,
                                        ),
                                      ),
                                      child: _buildCardItem(
                                        context,
                                        card,
                                        columnName,
                                        index,
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
                  }),
                ],
              ),
            ),
    );
  }

  Widget _buildCardItem(
    BuildContext context,
    KanbanTask card,
    String columnName,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  card.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _showEditTaskDialog(card),
                    icon: const Icon(LucideIcons.pencil, size: 16),
                    iconSize: 16,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Edit',
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _deleteCard(columnName, index),
                    icon: const Icon(
                      LucideIcons.trash2,
                      size: 16,
                      color: Colors.red,
                    ),
                    iconSize: 16,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Dibuat: ${_formatDate(card.createdAt)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColumnColor(String columnName) {
    switch (columnName) {
      case 'To Do':
        return Colors.grey;
      case 'In Progress':
        return Colors.blue;
      case 'Review':
        return Colors.orange;
      case 'Done':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
