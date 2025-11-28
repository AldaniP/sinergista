import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/services/connection_service.dart';
import '../../core/models/connection_model.dart';
import '../../features/collaboration/search_user_screen.dart'; // Sesuaikan path foldernya

class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controller untuk Search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Service Supabase
  final _connectionService = ConnectionService();

  // State Data
  List<ConnectionModel> _connections = [];
  List<ConnectionModel> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData(); // Ambil data saat layar dibuka
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // --- LOGIC FUNCTIONS (SUPABASE) ---

  // 1. Fetch Data dari Database
  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final connections = await _connectionService.getConnections();
      final requests = await _connectionService.getIncomingRequests();

      if (mounted) {
        setState(() {
          _connections = connections;
          _requests = requests;
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

  // 2. Filter Search (Logic Lokal)
  List<ConnectionModel> get _filteredConnections {
    if (_searchQuery.isEmpty) return _connections;
    return _connections
        .where(
          (item) => item.friendProfile.fullName.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ),
        )
        .toList();
  }

  List<ConnectionModel> get _filteredRequests {
    if (_searchQuery.isEmpty) return _requests;
    return _requests
        .where(
          (item) => item.friendProfile.fullName.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ),
        )
        .toList();
  }

  // 3. Action: Terima Permintaan
  Future<void> _acceptRequest(ConnectionModel item) async {
    try {
      // Optimistic Update (Update UI duluan biar cepat)
      setState(() {
        _requests.remove(item);
        _connections.insert(0, item);
      });

      // Panggil Service
      await _connectionService.acceptRequest(item.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${item.friendProfile.fullName} ditambahkan ke koneksi',
            ),
          ),
        );
      }
    } catch (e) {
      _fetchData(); // Rollback jika error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menerima permintaan')),
        );
      }
    }
  }

  // 4. Action: Tolak Permintaan
  Future<void> _rejectRequest(ConnectionModel item) async {
    try {
      setState(() {
        _requests.remove(item);
      });
      await _connectionService.removeConnection(item.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Permintaan dari ${item.friendProfile.fullName} dihapus',
            ),
          ),
        );
      }
    } catch (e) {
      _fetchData();
    }
  }

  // 5. Action: Hapus Teman (Unfriend)
  Future<void> _removeConnection(ConnectionModel item) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Koneksi?'),
        content: Text(
          'Anda yakin ingin menghapus ${item.friendProfile.fullName} dari daftar teman?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Tutup dialog dulu

              // Hapus lokal
              setState(() {
                _connections.remove(item);
              });

              // Hapus di DB
              try {
                await _connectionService.removeConnection(item.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${item.friendProfile.fullName} dihapus'),
                    ),
                  );
                }
              } catch (e) {
                _fetchData(); // Rollback
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // 6. Action: Tambah Teman (Navigasi ke Search Screen)
  void _addNewConnection() async {
    // Navigasi ke halaman search
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchUserScreen()),
    );

    // Saat kembali dari halaman search, refresh data (siapa tahu ada yg di-add)
    _fetchData();
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
                hintText: 'Cari teman...',
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

          // TAB BAR
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
                Tab(text: 'Koneksi    ${_connections.length}'),
                Tab(text: 'Permintaan    ${_requests.length}'),
              ],
            ),
          ),

          // TAB VIEW
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // KONEKSI LIST
                      _filteredConnections.isEmpty
                          ? _buildEmptyState('Tidak ada koneksi ditemukan')
                          : ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemCount: _filteredConnections.length,
                              itemBuilder: (context, index) {
                                final item = _filteredConnections[index];
                                return _buildConnectionItem(
                                  item: item,
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
                                final item = _filteredRequests[index];
                                return _buildRequestItem(
                                  item: item,
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
        onPressed: _addNewConnection,
        backgroundColor: AppColors.primary,
        child: const Icon(LucideIcons.userPlus, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Text(message, style: const TextStyle(color: Colors.grey)),
    );
  }

  Widget _buildConnectionItem({
    required ConnectionModel item,
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
            backgroundColor: item.friendProfile.avatarColor,
            backgroundImage: item.friendProfile.avatarUrl != null
                ? NetworkImage(item.friendProfile.avatarUrl!)
                : null,
            child: item.friendProfile.avatarUrl == null
                ? Text(
                    item.friendProfile.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.friendProfile.fullName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '@${item.friendProfile.username}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => _removeConnection(item),
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
    required ConnectionModel item,
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
            backgroundColor: item.friendProfile.avatarColor,
            backgroundImage: item.friendProfile.avatarUrl != null
                ? NetworkImage(item.friendProfile.avatarUrl!)
                : null,
            child: item.friendProfile.avatarUrl == null
                ? Text(
                    item.friendProfile.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.friendProfile.fullName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '@${item.friendProfile.username}',
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
                onPressed: () => _acceptRequest(item),
                icon: const Icon(LucideIcons.check, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(8),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _rejectRequest(item),
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
