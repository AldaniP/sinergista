import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_colors.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final List<Note> _notes = [];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _addNote() {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon isi judul dan isi catatan')),
      );
      return;
    }

    final newNote = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      content: _contentController.text,
      createdAt: DateTime.now(),
    );

    setState(() {
      _notes.insert(0, newNote);
    });

    _titleController.clear();
    _contentController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Catatan berhasil ditambahkan! ✨'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showNoteDetail(Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                note.title,
                style: const TextStyle(fontSize: 18),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.edit, size: 20),
                  onPressed: () {
                    Navigator.pop(context);
                    _showEditDialog(note);
                  },
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(LucideIcons.trash2, size: 20),
                  color: Colors.red,
                  onPressed: () {
                    Navigator.pop(context);
                    _confirmDelete(note);
                  },
                  tooltip: 'Hapus',
                ),
              ],
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 400),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.content,
                  style: const TextStyle(fontSize: 15, height: 1.4),
                ),
                const SizedBox(height: 16),
                Text(
                  'Dibuat: ${_formatDate(note.createdAt)}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup"),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Note note) {
    final editTitleController = TextEditingController(text: note.title);
    final editContentController = TextEditingController(text: note.content);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(LucideIcons.edit, color: AppColors.primary),
            SizedBox(width: 12),
            Text("Edit Catatan"),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: editTitleController,
                decoration: InputDecoration(
                  labelText: "Judul",
                  prefixIcon: const Icon(LucideIcons.type),
                  filled: true,
                  fillColor: Colors.grey.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: editContentController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: "Isi Catatan",
                  prefixIcon: const Icon(LucideIcons.fileText),
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: Colors.grey.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              editTitleController.dispose();
              editContentController.dispose();
              Navigator.pop(context);
            },
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              if (editTitleController.text.isEmpty ||
                  editContentController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mohon isi judul dan isi catatan'),
                  ),
                );
                return;
              }

              _updateNote(
                note,
                editTitleController.text,
                editContentController.text,
              );

              editTitleController.dispose();
              editContentController.dispose();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  void _updateNote(Note note, String newTitle, String newContent) {
    setState(() {
      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _notes[index] = Note(
          id: note.id,
          title: newTitle,
          content: newContent,
          createdAt: note.createdAt,
          updatedAt: DateTime.now(),
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Catatan berhasil diperbarui! ✨'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _confirmDelete(Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(LucideIcons.alertTriangle, color: Colors.red),
            SizedBox(width: 12),
            Text("Hapus Catatan?"),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus catatan "${note.title}"? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteNote(note);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }

  void _deleteNote(Note note) {
    setState(() {
      _notes.removeWhere((n) => n.id == note.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Catatan berhasil dihapus'),
        backgroundColor: Colors.red.shade600,
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(LucideIcons.stickyNote, color: AppColors.primary),
            SizedBox(width: 12),
            Text("Tentang Notes"),
          ],
        ),
        content: const Text(
          "Fitur Notes memungkinkan Anda menyimpan catatan penting, rangkuman materi, dan ide. Anda dapat menambah, membaca, mengedit, dan menghapus catatan kapan saja.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Mengerti"),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inHours < 1) return '${diff.inMinutes} menit lalu';
    if (diff.inDays < 1) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';

    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notes"),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.info),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(LucideIcons.stickyNote, color: Colors.white, size: 40),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Catatan Belajar",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Simpan ide, rangkuman, dan notes penting",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Buat Catatan Baru",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: "Judul",
                prefixIcon: const Icon(LucideIcons.type),
                filled: true,
                fillColor: Theme.of(context).inputDecorationTheme.fillColor ??
                    Colors.grey.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: "Isi Catatan",
                prefixIcon: const Icon(LucideIcons.fileText),
                alignLabelWithHint: true,
                filled: true,
                fillColor: Theme.of(context).inputDecorationTheme.fillColor ??
                    Colors.grey.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addNote,
                icon: const Icon(LucideIcons.plus),
                label: const Text("Tambah Catatan"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (_notes.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Catatan Saya',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_notes.length} catatan',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ..._notes.map((note) => _buildNoteCard(note)),
            ] else ...[
              const SizedBox(height: 60),
              Center(
                child: Column(
                  children: [
                    Icon(
                      LucideIcons.stickyNote,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Belum ada catatan",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard(Note note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: InkWell(
        onTap: () => _showNoteDetail(note),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.stickyNote,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      note.updatedAt != null
                          ? 'Diperbarui ${_formatDate(note.updatedAt!)}'
                          : _formatDate(note.createdAt),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(LucideIcons.moreVertical),
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditDialog(note);
                  } else if (value == 'delete') {
                    _confirmDelete(note);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(LucideIcons.edit, size: 18),
                        SizedBox(width: 12),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(LucideIcons.trash2, size: 18, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Hapus', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.updatedAt,
  });
}
