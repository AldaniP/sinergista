import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/profile_service.dart';
import '../gamification/achievement_screen.dart';
import '../collaboration/connections_screen.dart';
import '../academic/journal_screen.dart';
import '../tasks/archive_screen.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileService = ProfileService();
  bool _notificationsEnabled = true;
  bool _isLoadingStats = true;

  // Variabel untuk menyimpan statistik
  Map<String, int> _stats = {
    'modules': 0,
    'completed_tasks': 0,
    'connections': 0,
    'journals': 0,
  };

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  // Fungsi ambil data
  Future<void> _fetchStats() async {
    final stats = await _profileService.getProfileStats();
    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoadingStats = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final user =
            snapshot.data?.session?.user ??
            Supabase.instance.client.auth.currentUser;
        final isAnonymous = user?.isAnonymous ?? false;
        final fullName = isAnonymous
            ? 'Tamu'
            : (user?.userMetadata?['full_name'] ?? 'Pengguna');
        final email = isAnonymous
            ? 'Mode Tamu'
            : (user?.email ?? 'email@example.com');

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: _fetchStats, // Tarik ke bawah untuk refresh angka
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Profile Header
                  Container(
                    padding: const EdgeInsets.only(
                      top: 60,
                      bottom: 32,
                      left: 20,
                      right: 20,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Avatar
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                            image: user?.userMetadata?['avatar_url'] != null
                                ? DecorationImage(
                                    image: NetworkImage(
                                      user!.userMetadata!['avatar_url'],
                                    ),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: user?.userMetadata?['avatar_url'] == null
                              ? const Icon(
                                  LucideIcons.user,
                                  color: Colors.white,
                                  size: 40,
                                )
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          fullName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Stats Row (Data Dinamis)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStat(
                              _isLoadingStats ? '-' : '${_stats['modules']}',
                              'Modul',
                            ),
                            _buildStat(
                              _isLoadingStats
                                  ? '-'
                                  : '${_stats['completed_tasks']}',
                              'Tugas Selesai',
                            ),
                            _buildStat(
                              _isLoadingStats
                                  ? '-'
                                  : '${_stats['connections']}',
                              'Koneksi',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Menu Items
                  Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildMenuItem(
                          context,
                          icon: LucideIcons.award,
                          title: 'Galeri Achievement',
                          subtitle:
                              'Lihat pencapaianmu', // Sementara statis krn belum ada service achievement
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AchievementScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildMenuItem(
                          context,
                          icon: LucideIcons.users,
                          title: 'Koneksi Pengguna',
                          // Update Subtitle Koneksi Dinamis
                          subtitle: _isLoadingStats
                              ? 'Memuat...'
                              : '${_stats['connections']} koneksi aktif',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ConnectionsScreen(),
                              ),
                            ).then(
                              (_) => _fetchStats(),
                            ); // Refresh saat kembali
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildMenuItem(
                          context,
                          icon: LucideIcons.bookOpen,
                          title: 'Modul Jurnal',
                          // Update Subtitle Jurnal Dinamis
                          subtitle: _isLoadingStats
                              ? 'Catatan harian'
                              : '${_stats['journals']} entri jurnal',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const JournalScreen(),
                              ),
                            ).then(
                              (_) => _fetchStats(),
                            ); // Refresh saat kembali
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildMenuItem(
                          context,
                          icon: LucideIcons.archive,
                          title: 'Arsip',
                          subtitle: 'Modul & tugas selesai',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ArchiveScreen(),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 32),

                        // Settings Section
                        Row(
                          children: [
                            Icon(
                              LucideIcons.settings,
                              size: 20,
                              color: Theme.of(context).iconTheme.color,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Pengaturan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.color,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        _buildSettingTile(
                          context,
                          icon: LucideIcons.sun,
                          title: 'Mode Gelap',
                          subtitle: themeProvider.isDarkMode
                              ? 'Aktif'
                              : 'Nonaktif',
                          trailing: Switch(
                            value: themeProvider.isDarkMode,
                            onChanged: (value) => themeProvider.toggleTheme(),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Notifications Toggle
                        _buildSettingTile(
                          context,
                          icon: LucideIcons.bell,
                          title: 'Notifikasi',
                          subtitle: 'Push & Email',
                          trailing: Switch(
                            value: _notificationsEnabled,
                            onChanged: (value) {
                              setState(() => _notificationsEnabled = value);
                            },
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Change Password
                        _buildMenuItem(
                          context,
                          icon: LucideIcons.lock,
                          title: 'Ganti Password',
                          subtitle: 'Ubah kata sandi akun',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ChangePasswordScreen(),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 32),

                        // Edit Profile
                        _buildMenuItem(
                          context,
                          icon: LucideIcons.user,
                          title: 'Edit Profil',
                          subtitle: null,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const EditProfileScreen(),
                              ),
                            ).then((updated) {
                              if (updated == true) {
                                setState(
                                  () {},
                                ); // Refresh UI to show new name/avatar
                              }
                            });
                          },
                        ),

                        const SizedBox(height: 12),

                        // Logout
                        InkWell(
                          onTap: _handleLogout,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 16,
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  LucideIcons.logOut,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Keluar',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Footer
                        Text(
                          'Sinergista v1.0.0',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  // ... (Widget _buildMenuItem dan _buildSettingTile sama persis seperti sebelumnya)
  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: Theme.of(context).iconTheme.color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).iconTheme.color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
