import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final SupabaseClient _client = Supabase.instance.client;

  String get _userId => _client.auth.currentUser!.id;

  /// Mengambil statistik user (Jumlah modul, tugas selesai, koneksi)
  Future<Map<String, int>> getProfileStats() async {
    try {
      // 1. Hitung Modul
      final modulesCount = await _client
          .from('modules')
          .count(CountOption.exact)
          .eq('user_id', _userId);

      // 2. Hitung Tugas Selesai
      final completedTasksCount = await _client
          .from('tasks')
          .count(CountOption.exact)
          .eq('user_id', _userId)
          .eq('is_completed', true);

      // 3. Hitung Koneksi (Accepted)
      // Logika: requester_id SAYA atau receiver_id SAYA, dan status ACCEPTED
      final connectionsCount = await _client
          .from('connections')
          .count(CountOption.exact)
          .eq('status', 'accepted')
          .or('requester_id.eq.$_userId,receiver_id.eq.$_userId');

      // 4. Hitung Jurnal (Opsional, untuk badge/info tambahan)
      final journalsCount = await _client
          .from('journals')
          .count(CountOption.exact)
          .eq('user_id', _userId);

      return {
        'modules': modulesCount,
        'completed_tasks': completedTasksCount,
        'connections': connectionsCount,
        'journals': journalsCount,
      };
    } catch (e) {
      // Jika error (misal tabel belum dibuat), return 0 semua
      return {
        'modules': 0,
        'completed_tasks': 0,
        'connections': 0,
        'journals': 0,
      };
    }
  }
}
