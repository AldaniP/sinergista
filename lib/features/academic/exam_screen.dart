import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'quiz_model.dart';
import 'quiz_play_screen.dart';
import 'history_screen.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/gemini_service.dart';

class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  final _moduleController = TextEditingController();
  final _topicController = TextEditingController();
  final _countController = TextEditingController(text: '10');
  final List<Quiz> _quizzes = [];
  final GeminiService _geminiService = GeminiService();

  bool _isGenerating = false;
  File? _selectedPdfFile;
  List<int>? _selectedPdfBytes; // For web platform
  String? _pdfFileName;
  int _pdfFileSize = 0;

  final Set<QuestionType> _selectedQuestionTypes = {
    QuestionType.multipleChoice,
  };
  int _numberOfQuestions = 10;

  @override
  void dispose() {
    _moduleController.dispose();
    _topicController.dispose();
    _countController.dispose();
    super.dispose();
  }

  Future<void> _pickPdfFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: kIsWeb, // Get bytes for web, path for mobile
        withReadStream: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.first;

        setState(() {
          _pdfFileName = pickedFile.name;
          _pdfFileSize = pickedFile.size;

          // For web, use bytes; for mobile, use path
          if (kIsWeb && pickedFile.bytes != null) {
            _selectedPdfBytes = pickedFile.bytes;
            _selectedPdfFile = null;
          } else if (pickedFile.path != null) {
            _selectedPdfFile = File(pickedFile.path!);
            _selectedPdfBytes = null;
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF terpilih: $_pdfFileName'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error memilih file: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _generateQuiz() async {
    // Validation
    if (_selectedPdfFile == null && _selectedPdfBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon upload file PDF terlebih dahulu')),
      );
      return;
    }

    if (_selectedQuestionTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon pilih minimal satu tipe soal')),
      );
      return;
    }

    if (_moduleController.text.isEmpty || _topicController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon isi nama modul dan topik')),
      );
      return;
    }

    if (_countController.text.isEmpty ||
        int.tryParse(_countController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon isi jumlah soal dengan angka yang valid'),
        ),
      );
      return;
    }

    setState(() {
      _numberOfQuestions = int.parse(_countController.text);
    });

    setState(() => _isGenerating = true);

    try {
      // Extract text from PDF
      final String pdfText;

      if (_selectedPdfBytes != null) {
        // For web platform
        pdfText = await _geminiService.extractTextFromPdfBytes(
          _selectedPdfBytes!,
        );
      } else if (_selectedPdfFile != null) {
        // For mobile platform
        pdfText = await _geminiService.extractTextFromPdf(
          _selectedPdfFile!.path,
        );
      } else {
        throw Exception('No PDF file selected');
      }

      if (pdfText.trim().isEmpty) {
        throw Exception('Tidak dapat mengekstrak teks dari PDF');
      }

      // Generate questions using Gemini AI
      final questionTypes =
          _selectedQuestionTypes.map((type) => type.displayName).toList();

      final questionsData = await _geminiService.generateQuestions(
        text: pdfText,
        questionTypes: questionTypes,
        numberOfQuestions: _numberOfQuestions,
      );

      // Convert to QuizQuestion objects
      final questions = questionsData.map((data) {
        return QuizQuestion.fromMap(data);
      }).toList();

      if (questions.isEmpty) {
        throw Exception('Tidak ada soal yang berhasil dibuat');
      }

      // Create quiz
      final newQuiz = Quiz(
        moduleName: _moduleController.text,
        topic: _topicController.text,
        questions: questions,
        createdAt: DateTime.now(),
        sourceFile: _pdfFileName,
        questionTypes: _selectedQuestionTypes.toList(),
      );

      setState(() {
        _quizzes.insert(0, newQuiz);
        _isGenerating = false;

        // Reset form
        _selectedPdfFile = null;
        _selectedPdfBytes = null;
        _pdfFileName = null;
        _pdfFileSize = 0;
      });

      _moduleController.clear();
      _topicController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Quiz berhasil dibuat dengan ${questions.length} soal! 🎉',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _isGenerating = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error membuat quiz: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam & Quiz'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.info),
            onPressed: () => _showInfoDialog(),
          ),
          IconButton(
            icon: const Icon(LucideIcons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HistoryScreen(
                    initialFilterType: 'exam',
                    lockFilter: true,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
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
                  Icon(
                    LucideIcons.graduationCap,
                    color: Colors.white,
                    size: 40,
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Persiapan Ujian dengan AI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Upload PDF materi dan buat soal otomatis',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Form Section
            const Text(
              'Buat Quiz Baru',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // PDF Upload Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        LucideIcons.fileUp,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Upload Materi PDF',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_selectedPdfFile != null ||
                      _selectedPdfBytes != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.file,
                            color: AppColors.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _pdfFileName ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatFileSize(_pdfFileSize),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.x),
                            onPressed: () {
                              setState(() {
                                _selectedPdfFile = null;
                                _selectedPdfBytes = null;
                                _pdfFileName = null;
                                _pdfFileSize = 0;
                              });
                            },
                            iconSize: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isGenerating ? null : _pickPdfFile,
                      icon: Icon(
                        (_selectedPdfFile == null && _selectedPdfBytes == null)
                            ? LucideIcons.upload
                            : LucideIcons.refreshCw,
                      ),
                      label: Text(
                        (_selectedPdfFile == null && _selectedPdfBytes == null)
                            ? 'Pilih File PDF'
                            : 'Ganti File PDF',
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.primary),
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Question Type Selection
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        LucideIcons.listChecks,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Tipe Soal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: QuestionType.values.map((type) {
                      final isSelected = _selectedQuestionTypes.contains(type);
                      return FilterChip(
                        selected: isSelected,
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(type.icon, size: 16),
                            const SizedBox(width: 6),
                            Text(type.displayName),
                          ],
                        ),
                        onSelected: _isGenerating
                            ? null
                            : (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedQuestionTypes.add(type);
                                  } else {
                                    if (_selectedQuestionTypes.length > 1) {
                                      _selectedQuestionTypes.remove(type);
                                    }
                                  }
                                });
                              },
                        selectedColor: AppColors.primary.withValues(alpha: 0.2),
                        checkmarkColor: AppColors.primary,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Number of Questions Input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        LucideIcons.hash,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Jumlah Soal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Decrement Button
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(LucideIcons.minus),
                          onPressed: _isGenerating
                              ? null
                              : () {
                                  final current =
                                      int.tryParse(_countController.text) ?? 10;
                                  if (current > 1) {
                                    setState(() {
                                      _numberOfQuestions = current - 1;
                                      _countController.text =
                                          _numberOfQuestions.toString();
                                    });
                                  }
                                },
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Number Input
                      Expanded(
                        child: TextField(
                          controller: _countController,
                          enabled: !_isGenerating,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              final count = int.tryParse(value);
                              if (count != null) {
                                setState(() => _numberOfQuestions = count);
                              }
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Increment Button
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(LucideIcons.plus),
                          onPressed: _isGenerating
                              ? null
                              : () {
                                  final current =
                                      int.tryParse(_countController.text) ?? 10;
                                  setState(() {
                                    _numberOfQuestions = current + 1;
                                    _countController.text =
                                        _numberOfQuestions.toString();
                                  });
                                },
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Input Modul
            TextField(
              controller: _moduleController,
              enabled: !_isGenerating,
              decoration: InputDecoration(
                labelText: 'Nama Modul',
                hintText: 'contoh: Matematika, Fisika, dll',
                prefixIcon: const Icon(LucideIcons.book),
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

            // Input Topik
            TextField(
              controller: _topicController,
              enabled: !_isGenerating,
              decoration: InputDecoration(
                labelText: 'Topik Bahasan',
                hintText: 'contoh: Integral, Kinematika, dll',
                prefixIcon: const Icon(LucideIcons.fileText),
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

            // Generate Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateQuiz,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Icon(LucideIcons.sparkles),
                label: Text(
                  _isGenerating
                      ? 'Membuat Quiz dengan AI...'
                      : 'Generate Quiz dengan AI',
                ),
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

            // Quiz List
            if (_quizzes.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Quiz Saya',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_quizzes.length} quiz',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ..._quizzes.map((quiz) => _buildQuizCard(quiz)),
            ] else
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.fileQuestion,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada quiz',
                        style: TextStyle(
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withValues(alpha: 0.6),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload PDF dan buat quiz pertama Anda',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizCard(Quiz quiz) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _startQuiz(quiz),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        LucideIcons.clipboardList,
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
                            quiz.moduleName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            quiz.topic,
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                          if (quiz.sourceFile != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  LucideIcons.file,
                                  size: 12,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    quiz.sourceFile!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.color,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.trash2, size: 20),
                      color: Colors.red,
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Hapus Quiz?'),
                            content: Text(
                              'Quiz "${quiz.moduleName} - ${quiz.topic}" akan dihapus dari daftar.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Batal'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Hapus'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          setState(() {
                            _quizzes.remove(quiz);
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Quiz dihapus dari daftar'),
                              ),
                            );
                          }
                        }
                      },
                    ),
                    const Icon(LucideIcons.chevronRight, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildInfoChip(
                      LucideIcons.fileQuestion,
                      '${quiz.questions.length} soal',
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      LucideIcons.clock,
                      _formatDate(quiz.createdAt),
                    ),
                  ],
                ),
                if (quiz.questionTypes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: quiz.questionTypes.map((type) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(type.icon, size: 12, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              type.displayName,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7)
        : Colors.grey.shade600;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade800
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 12, color: textColor),
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

  void _startQuiz(Quiz quiz) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => QuizPlayScreen(
                quiz: quiz,
                assessmentType: 'exam',
              )),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(LucideIcons.info, color: AppColors.primary),
            SizedBox(width: 12),
            Text('Tentang Fitur Exam'),
          ],
        ),
        content: const Text(
          'Fitur Exam menggunakan AI Gemini untuk membuat soal otomatis dari materi PDF Anda. '
          'Upload file PDF materi kuliah, pilih tipe soal yang diinginkan, '
          'dan sistem akan membuat pertanyaan-pertanyaan relevan untuk latihan.\n\n'
          'Tipe soal yang tersedia:\n'
          '• Pilihan Ganda (4 opsi)\n'
          '• Essay (jawaban terbuka)\n'
          '• Benar/Salah\n'
          '• Isian (lengkapi kalimat)\n\n'
          'Quiz yang sudah dibuat dapat diakses kembali kapan saja.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }
}
