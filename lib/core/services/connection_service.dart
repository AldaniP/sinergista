import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/connection_model.dart';

class ConnectionService {
  final SupabaseClient _client = Supabase.instance.client;

  String get _currentUserId => _client.auth.currentUser!.id;

  // 1. Cari User (Untuk fitur Search)
  Future<List<ProfileModel>> searchUsers(String query) async {
    if (query.isEmpty) return [];

    final response = await _client
        .from('profiles')
        .select()
        .ilike('full_name', '%$query%') // Case insensitive search
        .neq('id', _currentUserId) // Jangan tampilkan diri sendiri
        .limit(10);

    return (response as List).map((e) => ProfileModel.fromJson(e)).toList();
  }

  // 2. Ambil Daftar Koneksi (Teman yang sudah Accepted)
  Future<List<ConnectionModel>> getConnections() async {
    final response = await _client
        .from('connections')
        .select('''
          *,
          requester_profile:profiles!requester_id(*),
          receiver_profile:profiles!receiver_id(*)
        ''')
        .or('requester_id.eq.$_currentUserId,receiver_id.eq.$_currentUserId')
        .eq('status', 'accepted');

    return (response as List)
        .map((e) => ConnectionModel.fromSupabase(e, _currentUserId))
        .toList();
  }

  // 3. Ambil Permintaan Masuk (Incoming Requests)
  Future<List<ConnectionModel>> getIncomingRequests() async {
    final response = await _client.from('connections').select('''
          *,
          requester_profile:profiles!requester_id(*), 
          receiver_profile:profiles!receiver_id(*) 
        ''').eq('receiver_id', _currentUserId).eq('status', 'pending');

    // Note: receiver_profile sebenarnya tidak perlu diload full karena itu saya sendiri,
    // tapi diperlukan agar parsing di Model.fromSupabase tidak error null.

    return (response as List)
        .map((e) => ConnectionModel.fromSupabase(e, _currentUserId))
        .toList();
  }

  // 4. Kirim Permintaan Berteman
  Future<void> sendRequest(String targetUserId) async {
    // Cek dulu apakah koneksi sudah ada (opsional, karena constraint DB sudah handle)
    await _client.from('connections').insert({
      'requester_id': _currentUserId,
      'receiver_id': targetUserId,
      'status': 'pending',
    });
  }

  // 5. Terima Permintaan
  Future<void> acceptRequest(String connectionId) async {
    await _client
        .from('connections')
        .update({'status': 'accepted'}).eq('id', connectionId);
  }

  // 6. Tolak / Hapus / Batalkan Permintaan
  Future<void> removeConnection(String connectionId) async {
    await _client.from('connections').delete().eq('id', connectionId);
  }
}
