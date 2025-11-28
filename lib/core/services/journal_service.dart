import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/journal_model.dart';

class JournalService {
  final SupabaseClient _client = Supabase.instance.client;

  String get _currentUserId => _client.auth.currentUser!.id;

  // 1. Ambil semua jurnal user
  Future<List<JournalModel>> getJournals() async {
    final response = await _client
        .from('journals')
        .select()
        .eq('user_id', _currentUserId)
        .order('created_at', ascending: false); // Terbaru di atas

    return (response as List).map((e) => JournalModel.fromJson(e)).toList();
  }

  // 2. Tambah jurnal baru
  Future<void> addJournal({
    required String title,
    required String content,
    required String mood,
    required List<String> tags,
  }) async {
    await _client.from('journals').insert({
      'user_id': _currentUserId,
      'title': title,
      'content': content,
      'mood': mood,
      'tags': tags,
    });
  }

  // 3. Hapus jurnal
  Future<void> deleteJournal(String id) async {
    await _client.from('journals').delete().eq('id', id);
  }
}
