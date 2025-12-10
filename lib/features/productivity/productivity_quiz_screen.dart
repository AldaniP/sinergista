import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/gemini_service.dart';
import '../academic/quiz_model.dart';
import '../academic/quiz_play_screen.dart';

class ProductivityQuizScreen extends StatefulWidget {
  const ProductivityQuizScreen({super.key});

  @override
  State<ProductivityQuizScreen> createState() => _ProductivityQuizScreenState();
}

class _ProductivityQuizScreenState extends State<ProductivityQuizScreen> {
  final _topicController = TextEditingController();
  final _countController = TextEditingController(text: '5');
  final GeminiService _geminiService = GeminiService();

  bool _isGenerating = false;
  final Set<QuestionType> _selectedQuestionTypes = {
    QuestionType.multipleChoice,
    QuestionType.trueFalse,
  };
  int _numberOfQuestions = 5;

  @override
  void dispose() {
    _topicController.dispose();
    _countController.dispose();
    super.dispose();
  }

  Future<void> _generateQuiz() async {
    if (_topicController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon isi topik challenge')),
      );
      return;
    }

    if (_selectedQuestionTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon pilih minimal satu tipe soal')),
      );
      return;
    }

    setState(() => _isGenerating = true);
    FocusScope.of(context).unfocus();

    try {
      final questionTypes = _selectedQuestionTypes
          .map((type) => type.displayName)
          .toList();

      final questionsData = await _geminiService.generateQuestionsFromTopic(
        topic: _topicController.text,
        questionTypes: questionTypes,
        numberOfQuestions: _numberOfQuestions,
      );

      final questions = questionsData
          .map((data) => QuizQuestion.fromMap(data))
          .toList();

      final quiz = Quiz(
        moduleName: 'Productivity Challenge',
        topic: _topicController.text,
        questions: questions,
        createdAt: DateTime.now(),
        questionTypes: _selectedQuestionTypes.toList(),
      );

      if (mounted) {
        setState(() => _isGenerating = false);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => QuizPlayScreen(quiz: quiz)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat quiz: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Produktivitas'), elevation: 0),
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
                  colors: [AppColors.success, Colors.teal],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(LucideIcons.zap, color: Colors.white, size: 40),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tantangan Harian',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Uji pengetahuanmu tentang produktivitas, manajemen waktu, atau topik apapun!',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Topic Input
            const Text(
              'Topik Challenge',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _topicController,
              enabled: !_isGenerating,
              decoration: InputDecoration(
                hintText: 'Misal: Time Blocking, Pomodoro, Leadership...',
                prefixIcon: const Icon(LucideIcons.search),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Settings Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pengaturan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Question Count
                  Row(
                    children: [
                      const Expanded(child: Text('Jumlah Soal')),
                      IconButton(
                        onPressed: _isGenerating || _numberOfQuestions <= 3
                            ? null
                            : () => setState(() {
                                _numberOfQuestions--;
                                _countController.text = _numberOfQuestions
                                    .toString();
                              }),
                        icon: const Icon(LucideIcons.minus),
                      ),
                      SizedBox(
                        width: 40,
                        child: Text(
                          _numberOfQuestions.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        onPressed: _isGenerating || _numberOfQuestions >= 20
                            ? null
                            : () => setState(() {
                                _numberOfQuestions++;
                                _countController.text = _numberOfQuestions
                                    .toString();
                              }),
                        icon: const Icon(LucideIcons.plus),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Question Types
                  const Text('Tipe Soal'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: QuestionType.values.map((type) {
                      final isSelected = _selectedQuestionTypes.contains(type);
                      return FilterChip(
                        selected: isSelected,
                        label: Text(type.displayName),
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
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Action Button
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
                    : const Icon(LucideIcons.swords),
                label: Text(
                  _isGenerating ? 'Sedang Membuat...' : 'Mulai Challenge',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
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
