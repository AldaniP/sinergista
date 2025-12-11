import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/gemini_service.dart';

enum QuestionType { multipleChoice, essay, trueFalse, fillBlank }

extension QuestionTypeExtension on QuestionType {
  String get displayName {
    switch (this) {
      case QuestionType.multipleChoice:
        return 'Pilihan Ganda';
      case QuestionType.essay:
        return 'Essay';
      case QuestionType.trueFalse:
        return 'Benar/Salah';
      case QuestionType.fillBlank:
        return 'Isian';
    }
  }

  IconData get icon {
    switch (this) {
      case QuestionType.multipleChoice:
        return LucideIcons.listChecks;
      case QuestionType.essay:
        return LucideIcons.fileText;
      case QuestionType.trueFalse:
        return LucideIcons.checkCircle;
      case QuestionType.fillBlank:
        return LucideIcons.edit;
    }
  }

  String get apiValue {
    switch (this) {
      case QuestionType.multipleChoice:
        return 'multiple_choice';
      case QuestionType.essay:
        return 'essay';
      case QuestionType.trueFalse:
        return 'true_false';
      case QuestionType.fillBlank:
        return 'fill_blank';
    }
  }
}

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
                                    color: Colors.grey.shade600,
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
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
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
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
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
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload PDF dan buat quiz pertama Anda',
                        style: TextStyle(
                          color: Colors.grey.shade500,
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
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (quiz.sourceFile != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  LucideIcons.file,
                                  size: 12,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    quiz.sourceFile!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
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
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
      MaterialPageRoute(builder: (context) => QuizPlayScreen(quiz: quiz)),
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

// Models
class Quiz {
  final String moduleName;
  final String topic;
  final List<QuizQuestion> questions;
  final DateTime createdAt;
  final String? sourceFile;
  final List<QuestionType> questionTypes;

  Quiz({
    required this.moduleName,
    required this.topic,
    required this.questions,
    required this.createdAt,
    this.sourceFile,
    this.questionTypes = const [],
  });
}

class QuizQuestion {
  final QuestionType type;
  final String question;
  final List<String>? options;
  final dynamic correctAnswer;
  String? essayAnswer;

  QuizQuestion({
    required this.type,
    required this.question,
    this.options,
    this.correctAnswer,
    this.essayAnswer,
    this.userAnswer,
  });

  // Add this field
  dynamic userAnswer;

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    QuestionType type;
    switch (map['type']) {
      case 'multiple_choice':
        type = QuestionType.multipleChoice;
        break;
      case 'essay':
        type = QuestionType.essay;
        break;
      case 'true_false':
        type = QuestionType.trueFalse;
        break;
      case 'fill_blank':
        type = QuestionType.fillBlank;
        break;
      default:
        type = QuestionType.multipleChoice;
    }

    return QuizQuestion(
      type: type,
      question: map['question'] ?? '',
      options:
          map['options'] != null ? List<String>.from(map['options']) : null,
      correctAnswer: map['correctAnswer'],
    );
  }
}

// Quiz Play Screen
class QuizPlayScreen extends StatefulWidget {
  final Quiz quiz;

  const QuizPlayScreen({super.key, required this.quiz});

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  int _currentQuestionIndex = 0;
  int? _selectedAnswer;
  String _textAnswer = '';
  int _score = 0;
  bool _quizCompleted = false;
  bool _isChecking = false;
  final List<String> _essayAnswers = [];
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submitAnswer() async {
    final question = widget.quiz.questions[_currentQuestionIndex];

    if (question.type == QuestionType.essay ||
        question.type == QuestionType.fillBlank) {
      setState(() => _isChecking = true);

      // Check answer with AI
      final result = await GeminiService().checkAnswer(
        question: question.question,
        userAnswer: _textAnswer,
        questionType: question.type.displayName,
        correctAnswer: question.correctAnswer?.toString(),
      );

      setState(() => _isChecking = false);

      if (!mounted) return;

      // Show feedback
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                result['isCorrect'] == true
                    ? LucideIcons.checkCircle
                    : LucideIcons.xCircle,
                color: result['isCorrect'] == true
                    ? AppColors.success
                    : AppColors.error,
              ),
              const SizedBox(width: 12),
              Text(result['isCorrect'] == true ? 'Benar!' : 'Kurang Tepat'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result['feedback'] ?? 'Tidak ada feedback.',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _proceedToNextQuestion(
                  isCorrect: result['isCorrect'] == true,
                  saveEssay: question.type == QuestionType.essay,
                );
              },
              child: const Text('Lanjut'),
            ),
          ],
        ),
      );
    } else {
      // Multiple Choice / True False
      final isCorrect = _selectedAnswer == question.correctAnswer;
      _proceedToNextQuestion(isCorrect: isCorrect);
    }
  }

  void _proceedToNextQuestion({
    bool isCorrect = false,
    bool saveEssay = false,
  }) {
    final question = widget.quiz.questions[_currentQuestionIndex];

    // Save answer if not already saved (for AI check flow)
    if (question.type == QuestionType.essay ||
        question.type == QuestionType.fillBlank) {
      question.userAnswer = _textAnswer;
    } else {
      question.userAnswer = _selectedAnswer;
    }

    if (isCorrect) {
      _score++;
    }

    if (saveEssay) {
      _essayAnswers.add(_textAnswer);
      question.essayAnswer = _textAnswer;
    }

    if (_currentQuestionIndex < widget.quiz.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = null;
        _textAnswer = '';
        _textController.clear();
      });
    } else {
      setState(() => _quizCompleted = true);
    }
  }

  bool _canSubmit() {
    final question = widget.quiz.questions[_currentQuestionIndex];

    if (question.type == QuestionType.essay ||
        question.type == QuestionType.fillBlank) {
      return _textAnswer.trim().isNotEmpty;
    } else {
      return _selectedAnswer != null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_quizCompleted) {
      return _buildResultsScreen();
    }

    final question = widget.quiz.questions[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Soal ${_currentQuestionIndex + 1} / ${widget.quiz.questions.length}',
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / widget.quiz.questions.length,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(question.type.icon, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    question.type.displayName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              question.question,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Expanded(child: _buildAnswerWidget(question)),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canSubmit() && !_isChecking ? _submitAnswer : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _currentQuestionIndex < widget.quiz.questions.length - 1
                      ? (_isChecking ? 'Memeriksa...' : 'Lanjut')
                      : (_isChecking ? 'Memeriksa...' : 'Selesai'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerWidget(QuizQuestion question) {
    switch (question.type) {
      case QuestionType.multipleChoice:
      case QuestionType.trueFalse:
        return _buildMultipleChoiceWidget(question);
      case QuestionType.essay:
        return _buildEssayWidget();
      case QuestionType.fillBlank:
        return _buildFillBlankWidget();
    }
  }

  Widget _buildMultipleChoiceWidget(QuizQuestion question) {
    return ListView.builder(
      itemCount: question.options?.length ?? 0,
      itemBuilder: (context, index) {
        final isSelected = _selectedAnswer == index;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _selectedAnswer = index),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : Theme.of(context).dividerColor.withValues(alpha: 0.2),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            isSelected ? AppColors.primary : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.grey.shade400,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                              LucideIcons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        question.options![index],
                        style: TextStyle(
                          fontSize: 16,
                          color: isSelected
                              ? AppColors.primary
                              : Theme.of(context).textTheme.bodyLarge?.color,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEssayWidget() {
    return SingleChildScrollView(
      child: TextField(
        controller: _textController,
        maxLines: 10,
        onChanged: (value) => setState(() => _textAnswer = value),
        decoration: InputDecoration(
          hintText: 'Tulis jawaban Anda di sini...',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Theme.of(context).cardColor,
        ),
      ),
    );
  }

  Widget _buildFillBlankWidget() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lengkapi kalimat di atas dengan jawaban yang tepat:',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _textController,
            onChanged: (value) => setState(() => _textAnswer = value),
            decoration: InputDecoration(
              hintText: 'Jawaban Anda...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              prefixIcon: const Icon(LucideIcons.edit),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsScreen() {
    final totalQuestions = widget.quiz.questions.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hasil Quiz'),
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.trophy, size: 80, color: AppColors.warning),
            const SizedBox(height: 24),
            const Text(
              'Quiz Selesai!',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Text(
              'Skor Anda',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              '$_score / $totalQuestions',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            Text(
              '${((_score / totalQuestions) * 100).toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 20, color: Colors.grey.shade600),
            ),

            const SizedBox(height: 32),

            // Review Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.listChecks, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        'Review Jawaban',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Berikut adalah detail jawaban Anda:',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            ...widget.quiz.questions.asMap().entries.map((entry) {
              final index = entry.key;
              final question = entry.value;
              return _buildQuestionReviewCard(index, question);
            }),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(LucideIcons.checkCircle),
                label: const Text('Selesai'),
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
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionReviewCard(int index, QuizQuestion question) {
    bool isCorrect = false;
    if (question.type == QuestionType.multipleChoice ||
        question.type == QuestionType.trueFalse) {
      isCorrect = question.userAnswer == question.correctAnswer;
    } else if (question.type == QuestionType.fillBlank) {
      isCorrect = question.userAnswer.toString().trim().toLowerCase() ==
          question.correctAnswer.toString().toLowerCase();
    } else {
      // Essay is manually reviewed or AI checked
      isCorrect = true;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  question.question,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          if (question.type == QuestionType.multipleChoice ||
              question.type == QuestionType.trueFalse)
            ...List.generate(question.options?.length ?? 0, (i) {
              final isSelected = question.userAnswer == i;
              final isAnswerCorrect = question.correctAnswer == i;

              Color? cardColor;
              Color borderColor = Colors.transparent;

              if (isAnswerCorrect) {
                cardColor = AppColors.success.withValues(alpha: 0.1);
                borderColor = AppColors.success;
              } else if (isSelected && !isAnswerCorrect) {
                cardColor = AppColors.error.withValues(alpha: 0.1);
                borderColor = AppColors.error;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardColor ?? Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: borderColor != Colors.transparent
                        ? borderColor
                        : Colors.grey.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isAnswerCorrect
                          ? LucideIcons.checkCircle
                          : (isSelected
                              ? LucideIcons.xCircle
                              : LucideIcons.circle),
                      size: 16,
                      color: isAnswerCorrect
                          ? AppColors.success
                          : (isSelected ? AppColors.error : Colors.grey),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        question.options![i],
                        style: TextStyle(
                          color: isAnswerCorrect
                              ? AppColors.success
                              : (isSelected ? AppColors.error : null),
                          fontWeight: isAnswerCorrect || isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            })
          else if (question.type == QuestionType.fillBlank)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jawaban Anda:',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCorrect ? AppColors.success : AppColors.error,
                    ),
                  ),
                  child: Text(
                    question.userAnswer?.toString() ?? '-',
                    style: TextStyle(
                      color: isCorrect ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!isCorrect) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Jawaban Benar:',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.success),
                    ),
                    child: Text(
                      question.correctAnswer.toString(),
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            )
          else // Essay
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jawaban Anda:',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(question.userAnswer?.toString() ?? '-'),
                ),
                const SizedBox(height: 12),
                Text(
                  'Poin Kunci Jawaban:',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    question.correctAnswer?.toString() ??
                        'Tidak ada kunci jawaban.',
                    style: const TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
