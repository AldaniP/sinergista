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

    _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
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

      return questions;
    } catch (e) {
      debugPrint('Error generating questions: $e');
      rethrow;
    }
  }

  String _buildPrompt(String text, List<String> questionTypes, int count) {
    final typesStr = questionTypes.join(', ');

    return '''
Berdasarkan teks berikut, buatlah $count soal ujian dalam bahasa Indonesia.

TEKS:
$text

INSTRUKSI:
1. Buat soal dengan tipe: $typesStr
2. Distribusikan soal secara merata di antara tipe-tipe yang diminta
3. Soal harus relevan dengan konten teks
4. Format output harus STRICT JSON array seperti contoh di bawah

FORMAT OUTPUT (STRICT JSON):
[
  {
    "type": "multiple_choice",
    "question": "Pertanyaan pilihan ganda?",
    "options": ["A. Opsi 1", "B. Opsi 2", "C. Opsi 3", "D. Opsi 4"],
    "correctAnswer": 0
  },
  {
    "type": "true_false",
    "question": "Pertanyaan benar/salah?",
    "options": ["Benar", "Salah"],
    "correctAnswer": 0
  },
  {
    "type": "essay",
    "question": "Pertanyaan essay?"
  },
  {
    "type": "fill_blank",
    "question": "Pertanyaan isian dengan ___ kosong?",
    "correctAnswer": "jawaban yang benar"
  }
]

PENTING: 
- Berikan HANYA JSON array, tanpa teks tambahan
- Untuk multiple_choice: gunakan 4 opsi (A, B, C, D)
- Untuk true_false: gunakan 2 opsi (Benar, Salah)
- Untuk essay: TIDAK perlu field "options" atau "correctAnswer"
- Untuk fill_blank: gunakan ___ untuk menandai tempat kosong
- correctAnswer adalah INDEX (0-based) untuk multiple_choice dan true_false
- correctAnswer adalah STRING untuk fill_blank
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
