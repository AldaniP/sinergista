import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_colors.dart';

class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  final _moduleController = TextEditingController();
  final _topicController = TextEditingController();
  final List<Quiz> _quizzes = [];
  bool _isGenerating = false;

  @override
  void dispose() {
    _moduleController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _generateQuiz() async {
    if (_moduleController.text.isEmpty || _topicController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon isi nama modul dan topik')),
      );
      return;
    }

    setState(() => _isGenerating = true);

    // Simulasi generate quiz (dalam implementasi real, ini bisa menggunakan API AI)
    await Future.delayed(const Duration(seconds: 2));

    final newQuiz = Quiz(
      moduleName: _moduleController.text,
      topic: _topicController.text,
      questions: _generateSampleQuestions(_moduleController.text, _topicController.text),
      createdAt: DateTime.now(),
    );

    setState(() {
      _quizzes.insert(0, newQuiz);
      _isGenerating = false;
    });

    _moduleController.clear();
    _topicController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quiz berhasil dibuat! 🎉'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  List<QuizQuestion> _generateSampleQuestions(String module, String topic) {
    // Ini adalah placeholder - dalam implementasi real bisa menggunakan AI
    return [
      QuizQuestion(
        question: 'Apa yang dimaksud dengan $topic dalam konteks $module?',
        options: [
          'Opsi A: Definisi 1',
          'Opsi B: Definisi 2',
          'Opsi C: Definisi 3',
          'Opsi D: Definisi 4',
        ],
        correctAnswer: 0,
      ),
      QuizQuestion(
        question: 'Sebutkan contoh penerapan $topic di $module!',
        options: [
          'Opsi A: Contoh 1',
          'Opsi B: Contoh 2',
          'Opsi C: Contoh 3',
          'Opsi D: Contoh 4',
        ],
        correctAnswer: 1,
      ),
      QuizQuestion(
        question: 'Mengapa $topic penting dalam $module?',
        options: [
          'Opsi A: Alasan 1',
          'Opsi B: Alasan 2',
          'Opsi C: Alasan 3',
          'Opsi D: Alasan 4',
        ],
        correctAnswer: 2,
      ),
    ];
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
                  Icon(LucideIcons.graduationCap, color: Colors.white, size: 40),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Persiapan Ujian',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Buat quiz otomatis untuk persiapan ujian',
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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Input Modul
            TextField(
              controller: _moduleController,
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
                label: Text(_isGenerating ? 'Membuat Quiz...' : 'Generate Quiz'),
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_quizzes.length} quiz',
                    style: TextStyle(
                      color: Colors.grey.shade600,
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
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Buat quiz pertama Anda di atas',
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
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
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
        builder: (context) => QuizPlayScreen(quiz: quiz),
      ),
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
          'Fitur Exam membantu Anda mempersiapkan ujian dengan membuat quiz otomatis. '
          'Masukkan nama modul dan topik, lalu sistem akan membuat pertanyaan-pertanyaan '
          'yang relevan untuk latihan.\n\n'
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

  Quiz({
    required this.moduleName,
    required this.topic,
    required this.questions,
    required this.createdAt,
  });
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctAnswer;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
  });
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
  int _score = 0;
  bool _quizCompleted = false;

  void _submitAnswer() {
    if (_selectedAnswer == null) return;

    if (_selectedAnswer == widget.quiz.questions[_currentQuestionIndex].correctAnswer) {
      _score++;
    }

    if (_currentQuestionIndex < widget.quiz.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = null;
      });
    } else {
      setState(() => _quizCompleted = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_quizCompleted) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Hasil Quiz'),
          leading: IconButton(
            icon: const Icon(LucideIcons.x),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.trophy,
                    size: 80,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Quiz Selesai!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Skor Anda',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$_score / ${widget.quiz.questions.length}',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
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
        ),
      );
    }

    final question = widget.quiz.questions[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Soal ${_currentQuestionIndex + 1} / ${widget.quiz.questions.length}'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / widget.quiz.questions.length,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
            const SizedBox(height: 32),

            // Question
            Text(
              question.question,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),

            // Options
            Expanded(
              child: ListView.builder(
                itemCount: question.options.length,
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
                                  color: isSelected ? AppColors.primary : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : Colors.grey.shade400,
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(LucideIcons.check, size: 16, color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  question.options[index],
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isSelected
                                        ? AppColors.primary
                                        : Theme.of(context).textTheme.bodyLarge?.color,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
              ),
            ),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedAnswer != null ? _submitAnswer : null,
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
                      ? 'Lanjut'
                      : 'Selesai',
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
}
