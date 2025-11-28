import 'package:image_picker/image_picker.dart';
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

  /// Update Profile (Full Name & Avatar URL)
  Future<void> updateProfile({String? fullName, String? avatarUrl}) async {
    try {
      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      if (updates.isNotEmpty) {
        await _client.auth.updateUser(UserAttributes(data: updates));
      }
    } catch (e) {
      throw 'Gagal update profil: $e';
    }
  }

  /// Upload Avatar to Supabase Storage
  Future<String> uploadAvatar(XFile file) async {
    try {
      final fileExt = file.name.split('.').last;
      final fileName =
          '$_userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = fileName;
      final bytes = await file.readAsBytes();

      try {
        // Upload file
        await _client.storage
            .from('avatars')
            .uploadBinary(
              filePath,
              bytes,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: false,
              ),
            );
      } on StorageException catch (e) {
        if (e.statusCode == '404' || e.message.contains('Bucket not found')) {
          try {
            // Try creating the bucket if it doesn't exist
            await _client.storage.createBucket(
              'avatars',
              const BucketOptions(public: true),
            );

            // Retry upload
            await _client.storage
                .from('avatars')
                .uploadBinary(
                  filePath,
                  bytes,
                  fileOptions: const FileOptions(
                    cacheControl: '3600',
                    upsert: false,
                  ),
                );
          } catch (_) {
            throw 'Bucket "avatars" tidak ditemukan. Silakan buat Storage Bucket bernama "avatars" (Public) di Supabase Dashboard.';
          }
        } else {
          rethrow;
        }
      }

      // Get Public URL
      final imageUrl = _client.storage.from('avatars').getPublicUrl(filePath);
      return imageUrl;
    } catch (e) {
      throw 'Gagal upload foto: $e';
    }
  }

  /// Verify Password (by re-authenticating)
  Future<bool> verifyPassword(String password) async {
    try {
      final email = _client.auth.currentUser?.email;
      if (email == null) return false;

      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      return response.user != null;
    } catch (e) {
      return false;
    }
  }

  /// Update Password
  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } catch (e) {
      throw 'Gagal update password: $e';
    }
  }
}
