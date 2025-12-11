import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/supabase_service.dart';
import 'block_model.dart';
import 'module_model.dart';
import 'module_members_screen.dart';
import 'kanban_board_screen.dart';

class ModuleEditorScreen extends StatefulWidget {
  final Module module;

  const ModuleEditorScreen({super.key, required this.module});

  @override
  State<ModuleEditorScreen> createState() => _ModuleEditorScreenState();
}

class _ModuleEditorScreenState extends State<ModuleEditorScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  late List<BlockModel> _blocks;
  final ScrollController _scrollController = ScrollController();
  bool _isSaving = false;
  Timer? _autoSaveTimer;
  late Module _module;

  int? _focusedBlockIndex;

  @override
  void initState() {
    super.initState();
    _module = widget.module;
    _loadContent();
    _refreshModuleData();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    for (var block in _blocks) {
      block.focusNode.dispose();
      block.controller.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshModuleData() async {
    try {
      final freshModule = await _supabaseService.getModule(_module.id);
      if (mounted) {
        setState(() {
          _module = freshModule;
          _loadContent();
        });
      }
    } catch (e) {
      debugPrint('Error refreshing module: $e');
    }
  }

  void _loadContent() {
    if (_module.content != null) {
      _blocks =
          (_module.content as List).map((e) => BlockModel.fromMap(e)).toList();
      for (var i = 0; i < _blocks.length; i++) {
        _addFocusListener(_blocks[i], i);
      }
    } else {
      // Default empty block
      _blocks = [];
      final newBlock = BlockModel(id: const Uuid().v4(), type: BlockType.text);
      _blocks.add(newBlock);
      _addFocusListener(newBlock, 0);
    }
  }

  void _addFocusListener(BlockModel block, int index) {
    block.focusNode.addListener(() {
      if (block.focusNode.hasFocus) {
        setState(() {
          _focusedBlockIndex = index;
        });
      }
    });
  }

  void _addBlock(BlockType type) {
    setState(() {
      final newBlock = BlockModel(id: const Uuid().v4(), type: type);
      _blocks.add(newBlock);
      _addFocusListener(newBlock, _blocks.length - 1);

      // Schedule focus request for the next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        newBlock.focusNode.requestFocus();
      });
    });
    _onContentChanged();
  }

  void _deleteBlock(int index) {
    if (index < 0 || index >= _blocks.length) return;

    setState(() {
      final block = _blocks[index];
      block.focusNode.dispose();
      block.controller.dispose();
      _blocks.removeAt(index);
      _focusedBlockIndex = null;
    });
    _onContentChanged();
  }

  void _deleteFocusedBlock() {
    if (_focusedBlockIndex != null) {
      _deleteBlock(_focusedBlockIndex!);
    }
  }

  void _onContentChanged() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), _saveContent);
  }

  Future<void> _saveContent() async {
    if (!mounted) return;
    setState(() => _isSaving = true);
    try {
      debugPrint('Saving content: ${_blocks.map((e) => e.toMap()).toList()}');

      await _supabaseService.updateModuleContent(
        widget.module.id,
        _blocks.map((e) => e.toMap()).toList(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perubahan berhasil disimpan'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _handleBackgroundTap() {
    if (_blocks.isEmpty) {
      _addBlock(BlockType.text);
    } else {
      final lastBlock = _blocks.last;
      if (lastBlock.content.isEmpty && lastBlock.type == BlockType.text) {
        lastBlock.focusNode.requestFocus();
      } else {
        _addBlock(BlockType.text);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.module.title),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.layoutGrid, size: 20),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      KanbanBoardScreen(module: widget.module),
                ),
              );
            },
            tooltip: 'Kanban Board',
          ),
          IconButton(
            icon: const Icon(LucideIcons.users, size: 20),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ModuleMembersScreen(module: widget.module),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.save, size: 20, color: Colors.grey),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: _handleBackgroundTap,
        behavior: HitTestBehavior.translucent,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _blocks.length,
                itemBuilder: (context, index) {
                  return _buildBlock(_blocks[index], index);
                },
              ),
            ),
            _buildToolbar(),
          ],
        ),
      ),
    );
  }

  Widget _buildBlock(BlockModel block, int index) {
    Widget content;
    switch (block.type) {
      case BlockType.heading1:
        content = _buildTextField(
          block,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        );
        break;
      case BlockType.heading2:
        content = _buildTextField(
          block,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        );
        break;
      case BlockType.bullet:
        content = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 12, right: 8),
              child: Icon(Icons.circle, size: 8),
            ),
            Expanded(child: _buildTextField(block)),
          ],
        );
        break;
      case BlockType.todo:
        content = Row(
          children: [
            Checkbox(
              value: block.isChecked,
              onChanged: (val) {
                setState(() {
                  block.isChecked = val ?? false;
                });
                _onContentChanged();
              },
            ),
            Expanded(
              child: _buildTextField(
                block,
                decoration: block.isChecked
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                color: block.isChecked ? Colors.grey : null,
              ),
            ),
          ],
        );
        break;
      case BlockType.link:
        content = InkWell(
          onTap: () async {
            if (block.url != null) {
              final uri = Uri.parse(block.url!);
              final canLaunch = await canLaunchUrl(uri);

              if (canLaunch) {
                await launchUrl(uri);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tidak dapat membuka link')),
                  );
                }
              }
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.link2, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        block.content.isNotEmpty ? block.content : 'Link',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (block.url != null)
                        Text(
                          block.url!,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary.withValues(alpha: 0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
        break;
      default:
        content = _buildTextField(block);
    }

    return Dismissible(
      key: ValueKey(block.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(LucideIcons.trash2, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _deleteBlock(index);
      },
      child: content,
    );
  }

  Widget _buildTextField(
    BlockModel block, {
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.normal,
    TextDecoration decoration = TextDecoration.none,
    Color? color,
  }) {
    return TextField(
      controller: block.controller,
      focusNode: block.focusNode,
      maxLines: null,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        decoration: decoration,
        color: color,
      ),
      decoration: const InputDecoration(
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 8),
      ),
      onChanged: (val) {
        block.content = val;
        _onContentChanged();
      },
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(LucideIcons.type),
            onPressed: () => _addBlock(BlockType.text),
          ),
          IconButton(
            icon: const Icon(LucideIcons.heading1),
            onPressed: () => _addBlock(BlockType.heading1),
          ),
          IconButton(
            icon: const Icon(LucideIcons.heading2),
            onPressed: () => _addBlock(BlockType.heading2),
          ),
          IconButton(
            icon: const Icon(LucideIcons.list),
            onPressed: () => _addBlock(BlockType.bullet),
          ),
          IconButton(
            icon: const Icon(LucideIcons.checkSquare),
            onPressed: () => _addBlock(BlockType.todo),
          ),
          IconButton(
            icon: const Icon(LucideIcons.link2),
            onPressed: _showAddLinkDialog,
          ),
          IconButton(
            icon: const Icon(LucideIcons.trash2, color: Colors.red),
            onPressed: _deleteFocusedBlock,
          ),
        ],
      ),
    );
  }

  Future<void> _showAddLinkDialog() async {
    final titleController = TextEditingController();
    final urlController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambahkan Link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Nama Link',
                hintText: 'Contoh: Materi Kuliah',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'URL Link',
                hintText: 'https://...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty &&
                  urlController.text.isNotEmpty) {
                _addLinkBlock(titleController.text, urlController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _addLinkBlock(String title, String url) {
    setState(() {
      final newBlock = BlockModel(
        id: const Uuid().v4(),
        type: BlockType.link,
        content: title,
        url: url,
      );
      _blocks.add(newBlock);
    });
    _onContentChanged();
  }
}
