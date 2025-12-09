import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY not found in .env file');
    }

    _model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: apiKey);
  }

  /// Extract text from PDF file
  Future<String> extractTextFromPdf(String filePath) async {
    try {
      final File file = File(filePath);
      final List<int> bytes = await file.readAsBytes();
      return await extractTextFromPdfBytes(bytes);
    } catch (e) {
      debugPrint('Error extracting text from PDF: $e');
      rethrow;
    }
  }

  /// Extract text from PDF bytes (for web platform)
  Future<String> extractTextFromPdfBytes(List<int> bytes) async {
    try {
      // Load PDF document
      final PdfDocument document = PdfDocument(inputBytes: bytes);

      // Extract text from all pages
      final StringBuffer text = StringBuffer();
      final PdfTextExtractor extractor = PdfTextExtractor(document);

      for (int i = 0; i < document.pages.count; i++) {
        final String pageText = extractor.extractText(startPageIndex: i);
        text.writeln(pageText);
      }

      document.dispose();

      return text.toString();
    } catch (e) {
      debugPrint('Error extracting text from PDF bytes: $e');
      rethrow;
    }
  }

  /// Generate quiz questions from text using Gemini AI
  Future<List<Map<String, dynamic>>> generateQuestions({
    required String text,
    required List<String> questionTypes,
    required int numberOfQuestions,
  }) async {
    try {
      // Build the prompt
      final prompt = _buildPrompt(text, questionTypes, numberOfQuestions);

      debugPrint('Sending prompt to Gemini AI...');

      // Generate content
      final response = await _model.generateContent([Content.text(prompt)]);

      if (response.text == null) {
        throw Exception('No response from Gemini AI');
      }

      debugPrint('Received response from Gemini AI');

      // Parse the response
      final questions = _parseResponse(response.text!);

      // Enforce exact number of questions if AI generated too many
      if (questions.length > numberOfQuestions) {
        return questions.sublist(0, numberOfQuestions);
      }

      return questions;
    } catch (e) {
      debugPrint('Error generating questions: $e');
      rethrow;
    }
  }

  /// Generate quiz questions from topic using Gemini AI
  Future<List<Map<String, dynamic>>> generateQuestionsFromTopic({
    required String topic,
    required List<String> questionTypes,
    required int numberOfQuestions,
  }) async {
    try {
      final prompt = _buildTopicPrompt(topic, questionTypes, numberOfQuestions);
      debugPrint('Sending topic prompt to Gemini AI...');
      final response = await _model.generateContent([Content.text(prompt)]);

      if (response.text == null) {
        throw Exception('No response from Gemini AI');
      }

      final questions = _parseResponse(response.text!);

      if (questions.length > numberOfQuestions) {
        return questions.sublist(0, numberOfQuestions);
      }

      return questions;
    } catch (e) {
      debugPrint('Error generating questions from topic: $e');
      rethrow;
    }
  }

  /// Check answer using Gemini AI
  Future<Map<String, dynamic>> checkAnswer({
    required String question,
    required String userAnswer,
    required String questionType,
    String? correctAnswer,
  }) async {
    try {
      final prompt = _buildCheckAnswerPrompt(
        question,
        userAnswer,
        questionType,
        correctAnswer,
      );

      final response = await _model.generateContent([Content.text(prompt)]);

      if (response.text == null) {
        throw Exception('No response from Gemini AI');
      }

      return _parseCheckAnswerResponse(response.text!);
    } catch (e) {
      debugPrint('Error checking answer: $e');
      // Fallback if AI fails
      return {
        'isCorrect': false,
        'feedback':
            'Gagal memverifikasi jawaban dengan AI. Silakan cek koneksi internet Anda.',
      };
    }
  }

  String _buildCheckAnswerPrompt(
    String question,
    String userAnswer,
    String type,
    String? context,
  ) {
    return '''
Anda adalah asisten dosen yang sedang mengoreksi ujian.
Tugas Anda adalah menilai jawaban berdasarkan pertanyaan dan kunci jawaban (jika ada).

PERTANYAAN: $question
TIPE SOAL: $type
JAWABAN ANDA: $userAnswer
${context != null ? 'KUNCI JAWABAN / KONTEKS: $context' : ''}

INSTRUKSI:
1. Tentukan apakah jawaban user BENAR atau SALAH.
   - Untuk Essay: Jawaban dianggap benar jika mencakup poin-poin penting yang relevan.
   - Untuk Isian: Jawaban harus tepat atau sinonim yang sangat dekat.
2. Berikan penjelasan singkat (feedback) mengapa jawaban tersebut benar atau salah.
3. Berikan output dalam format JSON STRICT.

FORMAT OUTPUT (JSON):
{
  "isCorrect": true/false,
  "feedback": "Penjelasan singkat..."
}
''';
  }

  Map<String, dynamic> _parseCheckAnswerResponse(String response) {
    try {
      String cleaned = response.trim();
      if (cleaned.startsWith('```json')) {
        cleaned = cleaned.substring(7);
      } else if (cleaned.startsWith('```')) {
        cleaned = cleaned.substring(3);
      }
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }
      return jsonDecode(cleaned.trim());
    } catch (e) {
      return {'isCorrect': false, 'feedback': 'Format respons AI tidak valid.'};
    }
  }

  String _buildTopicPrompt(
    String topic,
    List<String> questionTypes,
    int count,
  ) {
    final typesStr = questionTypes.join(', ');

    // Reuse the same JSON examples logic, simplified for brevity here or copied
    // For simplicity, let's just reuse the structure but strictly for topic
    // We can actually reuse _buildPrompt logic but replace "Berdasarkan teks berikut" with "Berdasarkan topik berikut"
    // To avoid duplication, we could refactor _buildPrompt, but for now I will duplicate the relevant parts for safety.

    final List<String> jsonExamples = [];

    if (questionTypes.contains('Pilihan Ganda')) {
      jsonExamples.add('''
  {
    "type": "multiple_choice",
    "question": "Pertanyaan pilihan ganda tentang topik?",
    "options": ["A. Opsi 1", "B. Opsi 2", "C. Opsi 3", "D. Opsi 4"],
    "correctAnswer": 0
  }''');
    }

    if (questionTypes.contains('Benar/Salah')) {
      jsonExamples.add('''
  {
    "type": "true_false",
    "question": "Pertanyaan benar/salah?",
    "options": ["Benar", "Salah"],
    "correctAnswer": 0
  }''');
    }

    if (questionTypes.contains('Essay')) {
      jsonExamples.add('''
  {
    "type": "essay",
    "question": "Pertanyaan essay?",
    "correctAnswer": "Poin-poin kunci jawaban singkat"
  }''');
    }

    if (questionTypes.contains('Isian')) {
      jsonExamples.add('''
  {
    "type": "fill_blank",
    "question": "Pertanyaan isian dengan ___ kosong?",
    "correctAnswer": "jawaban yang benar"
  }''');
    }

    final jsonExampleStr = jsonExamples.join(',\\n');

    return '''
Buatlah $count soal latihan produktivitas / akademik dalam bahasa Indonesia.

TOPIK: $topic

INSTRUKSI:
1. Buat soal yang RELEVAN dengan TOPIK di atas.
2. Tipe soal: $typesStr
3. TOTAL soal harus TEPAT $count buah.
4. Distribusikan soal secara merata.
5. Format output harus STRICT JSON array.

FORMAT OUTPUT (STRICT JSON):
[
$jsonExampleStr
]

PENTING:
- Berikan HANYA JSON array.
- correctAnswer adalah INDEX (0-based) untuk multiple_choice dan true_false.
- correctAnswer adalah STRING untuk fill_blank dan essay.
''';
  }

  String _buildPrompt(String text, List<String> questionTypes, int count) {
    final typesStr = questionTypes.join(', ');

    // Build dynamic JSON examples based on selected types
    final List<String> jsonExamples = [];

    if (questionTypes.contains('Pilihan Ganda')) {
      jsonExamples.add('''
  {
    "type": "multiple_choice",
    "question": "Pertanyaan pilihan ganda?",
    "options": ["A. Opsi 1", "B. Opsi 2", "C. Opsi 3", "D. Opsi 4"],
    "correctAnswer": 0
  }''');
    }

    if (questionTypes.contains('Benar/Salah')) {
      jsonExamples.add('''
  {
    "type": "true_false",
    "question": "Pertanyaan benar/salah?",
    "options": ["Benar", "Salah"],
    "correctAnswer": 0
  }''');
    }

    if (questionTypes.contains('Essay')) {
      jsonExamples.add('''
  {
    "type": "essay",
    "question": "Pertanyaan essay?",
    "correctAnswer": "Poin-poin kunci jawaban singkat"
  }''');
    }

    if (questionTypes.contains('Isian')) {
      jsonExamples.add('''
  {
    "type": "fill_blank",
    "question": "Pertanyaan isian dengan ___ kosong?",
    "correctAnswer": "jawaban yang benar"
  }''');
    }

    final jsonExampleStr = jsonExamples.join(',\n');

    return '''
Berdasarkan teks berikut, buatlah $count soal ujian dalam bahasa Indonesia.

TEKS:
$text

INSTRUKSI:
1. Buat soal dengan tipe: $typesStr
2. TOTAL soal harus TEPAT $count buah. JANGAN LEBIH, JANGAN KURANG.
3. Distribusikan soal secara merata di antara tipe-tipe yang diminta ($typesStr)
4. Soal harus relevan dengan konten teks
5. Format output harus STRICT JSON array seperti contoh di bawah
6. JANGAN membuat soal dengan tipe yang tidak diminta!

FORMAT OUTPUT (STRICT JSON):
[
$jsonExampleStr
]

PENTING: 
- Berikan HANYA JSON array, tanpa teks tambahan
- Gunakan format JSON persis seperti contoh di atas untuk setiap tipe soal yang diminta
- correctAnswer adalah INDEX (0-based) untuk multiple_choice dan true_false
- correctAnswer adalah STRING untuk fill_blank dan essay
''';
  }

  List<Map<String, dynamic>> _parseResponse(String response) {
    try {
      // Clean the response - remove markdown code blocks if present
      String cleaned = response.trim();

      // Remove ```json and ``` if present
      if (cleaned.startsWith('```json')) {
        cleaned = cleaned.substring(7);
      } else if (cleaned.startsWith('```')) {
        cleaned = cleaned.substring(3);
      }

      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }

      cleaned = cleaned.trim();

      // Parse JSON using dart:convert
      final dynamic parsed = jsonDecode(cleaned);

      if (parsed is! List) {
        throw Exception('Response is not a JSON array');
      }

      final List<Map<String, dynamic>> questions = [];

      for (var item in parsed) {
        if (item is Map) {
          // Convert to Map<String, dynamic>
          final Map<String, dynamic> question = {};
          item.forEach((key, value) {
            question[key.toString()] = value;
          });
          questions.add(question);
        }
      }

      return questions;
    } catch (e) {
      debugPrint('Error parsing response: $e');
      debugPrint('Response was: $response');
      rethrow;
    }
  }
}
