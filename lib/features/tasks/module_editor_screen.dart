import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/supabase_service.dart';
import 'block_model.dart';
import 'module_model.dart';
import 'module_members_screen.dart';

class ModuleEditorScreen extends StatefulWidget {
  final Module module;

  const ModuleEditorScreen({super.key, required this.module});

  @override
  State<ModuleEditorScreen> createState() => _ModuleEditorScreenState();
}

class _ModuleEditorScreenState extends State<ModuleEditorScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<BlockModel> _blocks = [];
  bool _isSaving = false;
  Timer? _autoSaveTimer;

  int? _focusedBlockIndex;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    for (var block in _blocks) {
      block.focusNode.dispose();
      block.controller.dispose();
    }
    super.dispose();
  }

  void _loadContent() {
    if (widget.module.content != null) {
      _blocks = (widget.module.content as List)
          .map((e) => BlockModel.fromMap(e))
          .toList();
      for (var i = 0; i < _blocks.length; i++) {
        _addFocusListener(_blocks[i], i);
      }
    } else {
      // Default empty block
      _addBlock(BlockType.text);
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
            icon: const Icon(LucideIcons.trash2, color: Colors.red),
            onPressed: _deleteFocusedBlock,
          ),
        ],
      ),
    );
  }
}
