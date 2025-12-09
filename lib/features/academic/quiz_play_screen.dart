import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/gemini_service.dart';
import 'quiz_model.dart';

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
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
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
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
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
      isCorrect =
          question.userAnswer.toString().trim().toLowerCase() ==
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
                  color: cardColor,
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
                          ? LucideIcons.check
                          : isSelected
                          ? LucideIcons.x
                          : LucideIcons.circle,
                      size: 16,
                      color: isAnswerCorrect
                          ? AppColors.success
                          : isSelected
                          ? AppColors.error
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        question.options![i],
                        style: TextStyle(
                          color: isAnswerCorrect
                              ? AppColors.success
                              : isSelected
                              ? AppColors.error
                              : null,
                          fontWeight: isAnswerCorrect || isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

          if (question.type == QuestionType.fillBlank ||
              question.type == QuestionType.essay) ...[
            const Text(
              'Jawaban Anda:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              question.userAnswer?.toString() ?? '-',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Kunci Jawaban / Referensi:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              question.correctAnswer?.toString() ?? question.essayAnswer ?? '-',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
