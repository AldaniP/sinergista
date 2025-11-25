import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/theme_provider.dart';

// Model data sederhana untuk User
class UserModel {
  final String id;
  final String name;
  final String email;
  final String projects;
  final String initial;
  final Color color;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.projects,
    required this.initial,
    required this.color,
  });
}

class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // --- DATA DUMMY (STATE) ---
  final List<UserModel> _connections = [
    UserModel(id: '1', name: 'Jane Smith', email: 'jane@email.com', projects: '3 proyek bersama', initial: 'JS', color: AppColors.primary),
    UserModel(id: '2', name: 'Bob Wilson', email: 'bob@email.com', projects: '1 proyek bersama', initial: 'BW', color: AppColors.primary),
    UserModel(id: '3', name: 'Alice Johnson', email: 'alice@email.com', projects: '2 proyek bersama', initial: 'AJ', color: AppColors.primary),
    UserModel(id: '4', name: 'Charlie Brown', email: 'charlie@email.com', projects: '5 proyek bersama', initial: 'CB', color: AppColors.primary),
    UserModel(id: '5', name: 'Diana Prince', email: 'diana@email.com', projects: '1 proyek bersama', initial: 'DP', color: AppColors.primary),
  ];

  final List<UserModel> _requests = [
    UserModel(id: '6', name: 'Emma Watson', email: 'emma@email.com', projects: '0 proyek bersama', initial: 'EW', color: Colors.orange),
    UserModel(id: '7', name: 'Tom Hardy', email: 'tom@email.com', projects: '0 proyek bersama', initial: 'TH', color: Colors.green),
    UserModel(id: '8', name: 'Sarah Connor', email: 'sarah@email.com', projects: '0 proyek bersama', initial: 'SC', color: Colors.purple),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // --- LOGIC FUNCTIONS ---

  // Filter list berdasarkan query pencarian
  List<UserModel> get _filteredConnections {
    if (_searchQuery.isEmpty) return _connections;
    return _connections.where((user) =>
        user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        user.email.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  List<UserModel> get _filteredRequests {
    if (_searchQuery.isEmpty) return _requests;
    return _requests.where((user) =>
        user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        user.email.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  // Terima permintaan: Pindah dari request ke connections
  void _acceptRequest(UserModel user) {
    setState(() {
      _requests.remove(user);
      _connections.insert(0, user); // Tambah ke paling atas
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${user.name} ditambahkan ke koneksi')),
    );
  }

  // Tolak permintaan: Hapus dari list
  void _rejectRequest(UserModel user) {
    setState(() {
      _requests.remove(user);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Permintaan dari ${user.name} dihapus')),
    );
  }

  // Hapus koneksi (Unfriend)
  void _removeConnection(UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Koneksi?'),
        content: Text('Anda yakin ingin menghapus ${user.name} dari daftar teman?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              setState(() {
                _connections.remove(user);
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${user.name} dihapus')),
              );
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Simulasi tambah teman baru lewat FAB
  void _addNewRandomRequest() {
    setState(() {
      _requests.add(UserModel(
        id: DateTime.now().toString(),
        name: 'New User ${_requests.length + 1}',
        email: 'newuser${_requests.length}@mail.com',
        projects: '0 proyek bersama',
        initial: 'NU',
        color: Colors.blueAccent,
      ));
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Simulasi: Permintaan baru diterima')),
    );
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
          // SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Cari atau tambah teman...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                ),
                prefixIcon: Icon(
                  LucideIcons.search,
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
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
          
          // TAB BAR (Dynamic Count)
          Container(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
            child: TabBar(
              controller: _tabController,
              labelColor: isDark ? Colors.white : Colors.black,
              unselectedLabelColor: isDark
                  ? Colors.grey.shade600
                  : Colors.grey.shade400,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(text: 'Koneksi    ${_connections.length}'), // Dynamic Count
                Tab(text: 'Permintaan    ${_requests.length}'), // Dynamic Count
              ],
            ),
          ),
          
          // TAB VIEW
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // KONEKSI LIST
                _filteredConnections.isEmpty 
                  ? _buildEmptyState('Tidak ada koneksi ditemukan') 
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _filteredConnections.length,
                      itemBuilder: (context, index) {
                        final user = _filteredConnections[index];
                        return _buildConnectionItem(
                          user: user,
                          isDark: isDark,
                        );
                      },
                    ),

                // PERMINTAAN LIST
                _filteredRequests.isEmpty 
                  ? _buildEmptyState('Tidak ada permintaan saat ini') 
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _filteredRequests.length,
                      itemBuilder: (context, index) {
                        final user = _filteredRequests[index];
                        return _buildRequestItem(
                          user: user,
                          isDark: isDark,
                        );
                      },
                    ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewRandomRequest,
        backgroundColor: AppColors.primary,
        child: const Icon(LucideIcons.userPlus, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _buildConnectionItem({
    required UserModel user,
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
            backgroundColor: user.color,
            child: Text(
              user.initial,
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
                  user.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.projects,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => _removeConnection(user), // Action Unfriend
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
    required UserModel user,
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
            backgroundColor: user.color,
            child: Text(
              user.initial,
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
                  user.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
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
                onPressed: () => _acceptRequest(user), // Action Accept
                icon: const Icon(LucideIcons.check, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(8),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _rejectRequest(user), // Action Reject
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