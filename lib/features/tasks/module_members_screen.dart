import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/supabase_service.dart';
import '../../core/models/connection_model.dart';
import 'module_model.dart';
import 'invite_member_screen.dart';

class ModuleMembersScreen extends StatefulWidget {
  final Module module;

  const ModuleMembersScreen({super.key, required this.module});

  @override
  State<ModuleMembersScreen> createState() => _ModuleMembersScreenState();
}

class _ModuleMembersScreenState extends State<ModuleMembersScreen> {
  final _supabaseService = SupabaseService();
  final _currentUserId = Supabase.instance.client.auth.currentUser?.id;

  List<Map<String, dynamic>> _members = [];
  ProfileModel? _ownerProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch Owner Profile
      final owner = await _supabaseService.getProfile(widget.module.userId);

      // 2. Fetch Members
      final members = await _supabaseService.getModuleMembers(widget.module.id);

      if (mounted) {
        setState(() {
          _ownerProfile = owner;
          _members = members.where((m) {
            final profile = m['profile'] as ProfileModel;
            return profile.id != widget.module.userId;
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
      }
    }
  }

  Future<void> _removeMember(String userId, String userName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Anggota'),
        content: Text(
          'Apakah Anda yakin ingin menghapus $userName dari modul ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _supabaseService.removeModuleMember(widget.module.id, userId);
      _fetchData(); // Refresh list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anggota berhasil dihapus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menghapus anggota: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final isOwner = _currentUserId == widget.module.userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Anggota Modul'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(LucideIcons.userPlus),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InviteMemberScreen(
                      moduleId: widget.module.id,
                      moduleTitle: widget.module.title,
                    ),
                  ),
                ).then((_) => _fetchData()); // Refresh after invite
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Owner Section
                if (_ownerProfile != null) ...[
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8, left: 4),
                    child: Text(
                      'Pemilik',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  _buildMemberTile(
                    _ownerProfile!,
                    role: 'Owner',
                    isOwnerBadge: true,
                  ),
                  const SizedBox(height: 24),
                ],

                // Members Section
                const Padding(
                  padding: EdgeInsets.only(bottom: 8, left: 4),
                  child: Text(
                    'Anggota',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                if (_members.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E1E1E)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF333333)
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'Belum ada anggota lain',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ..._members.map((memberData) {
                    final profile = memberData['profile'] as ProfileModel;
                    final role = memberData['role'] as String;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildMemberTile(
                        profile,
                        role: role,
                        showDelete: isOwner, // Only owner can delete
                        onDelete: () =>
                            _removeMember(profile.id, profile.fullName),
                      ),
                    );
                  }),
              ],
            ),
    );
  }

  Widget _buildMemberTile(
    ProfileModel profile, {
    required String role,
    bool isOwnerBadge = false,
    bool showDelete = false,
    VoidCallback? onDelete,
  }) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF333333) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: profile.avatarColor,
            backgroundImage: profile.avatarUrl != null
                ? NetworkImage(profile.avatarUrl!)
                : null,
            child: profile.avatarUrl == null
                ? Text(
                    profile.initials,
                    style: const TextStyle(color: Colors.white),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      profile.fullName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    if (isOwnerBadge) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Text(
                          'Owner',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '@${profile.username}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          if (showDelete)
            IconButton(
              icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.red),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}
