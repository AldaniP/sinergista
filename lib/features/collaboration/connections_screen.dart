import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/theme_provider.dart';

class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Koneksi'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari atau tambah teman...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                ),
                prefixIcon: Icon(
                  LucideIcons.search,
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                ),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF2C2C2C)
                    : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Container(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
            child: TabBar(
              controller: _tabController,
              labelColor: isDark ? Colors.white : Colors.black,
              unselectedLabelColor: isDark
                  ? Colors.grey.shade600
                  : Colors.grey.shade400,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: 'Koneksi     5'),
                Tab(text: 'Permintaan     3'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Koneksi Tab
                ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildConnectionItem(
                      name: 'Jane Smith',
                      email: 'jane@email.com',
                      projects: '3 proyek bersama',
                      initial: 'JS',
                      color: AppColors.primary,
                      isDark: isDark,
                    ),
                    _buildConnectionItem(
                      name: 'Bob Wilson',
                      email: 'bob@email.com',
                      projects: '1 proyek bersama',
                      initial: 'BW',
                      color: AppColors.primary,
                      isDark: isDark,
                    ),
                    _buildConnectionItem(
                      name: 'Alice Johnson',
                      email: 'alice@email.com',
                      projects: '2 proyek bersama',
                      initial: 'AJ',
                      color: AppColors.primary,
                      isDark: isDark,
                    ),
                    _buildConnectionItem(
                      name: 'Charlie Brown',
                      email: 'charlie@email.com',
                      projects: '5 proyek bersama',
                      initial: 'CB',
                      color: AppColors.primary,
                      isDark: isDark,
                    ),
                    _buildConnectionItem(
                      name: 'Diana Prince',
                      email: 'diana@email.com',
                      projects: '1 proyek bersama',
                      initial: 'DP',
                      color: AppColors.primary,
                      isDark: isDark,
                    ),
                  ],
                ),
                // Permintaan Tab
                ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildRequestItem(
                      name: 'Emma Watson',
                      email: 'emma@email.com',
                      initial: 'EW',
                      color: Colors.orange,
                      isDark: isDark,
                    ),
                    _buildRequestItem(
                      name: 'Tom Hardy',
                      email: 'tom@email.com',
                      initial: 'TH',
                      color: Colors.green,
                      isDark: isDark,
                    ),
                    _buildRequestItem(
                      name: 'Sarah Connor',
                      email: 'sarah@email.com',
                      initial: 'SC',
                      color: Colors.purple,
                      isDark: isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        child: const Icon(LucideIcons.userPlus, color: Colors.white),
      ),
    );
  }

  Widget _buildConnectionItem({
    required String name,
    required String email,
    required String projects,
    required String initial,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  projects,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(LucideIcons.userCheck, size: 16),
            label: const Text('Terhubung'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              side: BorderSide(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
              foregroundColor: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestItem({
    required String name,
    required String email,
    required String initial,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(LucideIcons.check, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(8),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {},
                icon: const Icon(LucideIcons.x, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: isDark
                      ? const Color(0xFF2C2C2C)
                      : Colors.grey.shade200,
                  foregroundColor: isDark ? Colors.white : Colors.black,
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
