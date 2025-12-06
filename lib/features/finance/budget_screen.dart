import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';

// Layar Budget
class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

// State Layar Budget
class _BudgetScreenState extends State<BudgetScreen> {
  final supabase = Supabase.instance.client;

  bool _loading = true;
  List<BudgetItem> _items = [];

  double _income = 0;
  double _expenses = 0;
  double _remaining = 0;

  Map<String, double> _categoryTotals = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Membaca data
  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        debugPrint('No user');
        _items = [];
        _calculateStats();
        return;
      }

      try {
        debugPrint('Fetching data for user ID: ${user.id}');
        final List<dynamic> rows = await supabase
            .from('budgets')
            .select()
            .eq('user_id', user.id)
            .order('date', ascending: false);

        _items = rows.map<BudgetItem>((r) {
          final Map<String, dynamic> row = Map<String, dynamic>.from(r as Map);
          return BudgetItem(
            id: row['id'] as String,
            amount: (row['amount'] as num).toDouble(),
            category: (row['category'] ?? 'Lainnya').toString(),
            type: (row['type'] ?? 'Kebutuhan').toString(),
            date:
                DateTime.tryParse(row['date']?.toString() ?? '') ??
                DateTime.now(),
            createdAt: row['created_at'] != null
                ? DateTime.tryParse(row['created_at'].toString())
                : null,
          );
        }).toList();
      } catch (e, st) {
        debugPrint('Supabase fetch error: $e\n$st');
        _items = [];
      }

      _calculateStats();
    } finally {
      setState(() => _loading = false);
    }
  }

  // Method untuk menghitung pemasukan dan pengeluaran
  void _calculateStats() {
    _income = 0;
    _expenses = 0;
    _categoryTotals = {};

    for (final it in _items) {
      if (it.isIncome) {
        _income += it.amount;
      } else {
        _expenses += it.amount;
        _categoryTotals[it.category] =
            (_categoryTotals[it.category] ?? 0) + it.amount;
      }
    }

    _remaining = _income - _expenses;
    setState(() {});
  }

  // Menambahkan atau memperbarui data
  Future<void> _addOrEditItem({BudgetItem? existing}) async {
    final rootContext = context;
    final isEdit = existing != null;

    final amountCtrl = TextEditingController(
      text: existing != null ? existing.amount.toStringAsFixed(0) : '',
    );
    final categoryCtrl = TextEditingController(text: existing?.category ?? '');
    String selectedType = existing?.type ?? 'Kebutuhan';
    DateTime selectedDate = existing?.date ?? DateTime.now();

    await showModalBottomSheet(
      context: rootContext,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: MediaQuery.of(
                modalCtx,
              ).viewInsets.add(const EdgeInsets.all(16)),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isEdit ? 'Edit Transaksi' : 'Tambah Transaksi',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(modalCtx).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Jumlah (Rp)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: categoryCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Kategori (cth: Makanan, Transport)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedType,
                            items: const [
                              DropdownMenuItem(
                                value: 'Kebutuhan',
                                child: Text('Kebutuhan'),
                              ),
                              DropdownMenuItem(
                                value: 'Keinginan',
                                child: Text('Keinginan'),
                              ),
                              DropdownMenuItem(
                                value: 'Tabungan',
                                child: Text('Tabungan'),
                              ),
                            ],
                            onChanged: (v) {
                              setModalState(
                                () => selectedType = v ?? 'Kebutuhan',
                              );
                            },
                            decoration: const InputDecoration(
                              labelText: 'Tipe',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: modalCtx,
                                initialDate: selectedDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setModalState(() => selectedDate = picked);
                              }
                            },
                            child: Text(
                              'Tanggal: ${_displayDate(selectedDate)}',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final textAmount = amountCtrl.text
                                  .replaceAll('.', '')
                                  .trim();
                              final textCategory = categoryCtrl.text.trim();

                              if (textAmount.isEmpty || textCategory.isEmpty) {
                                ScaffoldMessenger.of(rootContext).showSnackBar(
                                  const SnackBar(
                                    content: Text('Lengkapi semua field'),
                                  ),
                                );
                                return;
                              }

                              final parsed = double.tryParse(textAmount);
                              if (parsed == null) {
                                ScaffoldMessenger.of(rootContext).showSnackBar(
                                  const SnackBar(
                                    content: Text('Jumlah tidak valid'),
                                  ),
                                );
                                return;
                              }

                              try {
                                if (isEdit) {
                                  await supabase
                                      .from('budgets')
                                      .update({
                                        'amount': parsed.abs(),
                                        'category': textCategory,
                                        'type': selectedType,
                                        'date': selectedDate.toIso8601String(),
                                      })
                                      .eq('id', existing.id)
                                      .select();
                                } else {
                                  final user = supabase.auth.currentUser;
                                  if (user == null) {
                                    throw Exception('Not authenticated');
                                  }

                                  await supabase.from('budgets').insert({
                                    'user_id': user.id,
                                    'amount': parsed.abs(),
                                    'category': textCategory,
                                    'type': selectedType,
                                    'date': selectedDate.toIso8601String(),
                                  }).select();
                                }

                                if (!context.mounted) return;
                                Navigator.of(modalCtx).pop();
                                await _loadData();
                                if (!rootContext.mounted) return;
                                ScaffoldMessenger.of(rootContext).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isEdit
                                          ? 'Berhasil diperbarui'
                                          : 'Berhasil ditambahkan',
                                    ),
                                  ),
                                );
                              } catch (e) {
                                debugPrint('Save error: $e');
                                if (!rootContext.mounted) return;
                                ScaffoldMessenger.of(rootContext).showSnackBar(
                                  SnackBar(
                                    content: Text('Gagal menyimpan: $e'),
                                  ),
                                );
                              }
                            },
                            child: Text(isEdit ? 'Simpan Perubahan' : 'Simpan'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (isEdit)
                          OutlinedButton(
                            onPressed: () {
                              Navigator.of(modalCtx).pop();
                              _deleteItem(existing);
                            },
                            child: const Text('Hapus'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    amountCtrl.dispose();
    categoryCtrl.dispose();
  }

  // Menghapus data
  Future<void> _deleteItem(BudgetItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus transaksi?'),
        content: const Text('Transaksi akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await supabase.from('budgets').delete().eq('id', item.id);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Berhasil dihapus')));
      }
    } catch (e) {
      debugPrint('Delete error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
      }
    }
  }

  // Widget inti halaman
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Budget Planner')),
      body: _items.isEmpty ? _buildEmptyState() : _buildDashboard(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditItem(),
        child: const Icon(Icons.add),
      ),
    );
  }

  // Halaman ketika data budget masih kosong
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.insert_chart_outlined,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum ada transaksi',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tambahkan pemasukan, pengeluaran, atau tabungan pertama Anda.',
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _addOrEditItem(),
              child: const Text('Tambah Transaksi'),
            ),
          ],
        ),
      ),
    );
  }

  // Dashboard yang ditampilkan kepada pengguna
  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewCard(),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _addOrEditItem(),
                  icon: const Icon(LucideIcons.plus),
                  label: const Text('Tambah'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _addOrEditItem(),
                  icon: const Icon(LucideIcons.trendingDown),
                  label: const Text('Tambah Pengeluaran/Tabungan'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildCategoryChart(),
          const SizedBox(height: 24),
          const Text(
            'Riwayat Transaksi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ..._items.map(_buildItemTile),
        ],
      ),
    );
  }

  Widget _buildOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sisa Budget', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Text(
            'Rp ${_format(_remaining)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _miniStat('Pemasukan', _income, Colors.green)),
              Expanded(child: _miniStat('Pengeluaran', _expenses, Colors.red)),
            ],
          ),
        ],
      ),
    );
  }

  // Statistik ringkas
  Widget _miniStat(String label, double value, Color color) {
    return Row(
      children: [
        Icon(
          label == 'Pemasukan'
              ? LucideIcons.trendingUp
              : LucideIcons.trendingDown,
          color: color,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70)),
            Text(
              'Rp ${_format(value)}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Grafik per kategori
  Widget _buildCategoryChart() {
    final categories = _categoryTotals.entries.toList();
    final total = categories.fold<double>(0, (p, e) => p + e.value);

    if (categories.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Alokasi Pengeluaran',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  centerSpaceRadius: 50,
                  sectionsSpace: 0,
                  sections: categories.map((entry) {
                    final color =
                        Colors.primaries[entry.key.hashCode %
                            Colors.primaries.length];
                    return PieChartSectionData(
                      value: entry.value,
                      title: '',
                      color: color,
                      radius: 40,
                    );
                  }).toList(),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Total', style: TextStyle(color: Colors.grey)),
                  Text(
                    '${(total / 1000000).toStringAsFixed(1)} jt',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...categories.map((e) {
          final color =
              Colors.primaries[e.key.hashCode % Colors.primaries.length];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(e.key)),
                Text('Rp ${_format(e.value)}'),
              ],
            ),
          );
        }),
      ],
    );
  }

  // Data transaksi
  Widget _buildItemTile(BudgetItem item) {
    final isIncome = item.isIncome;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isIncome
                  ? Colors.green.withValues(alpha: 0.12)
                  : Colors.red.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isIncome ? LucideIcons.trendingUp : LucideIcons.trendingDown,
              color: isIncome ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.category,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.date.day}/${item.date.month}/${item.date.year}',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? '+' : '-'}Rp ${_format(item.amount)}',
                style: TextStyle(
                  color: isIncome ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _addOrEditItem(existing: item),
                    icon: const Icon(Icons.edit, size: 18),
                  ),
                  IconButton(
                    onPressed: () => _deleteItem(item),
                    icon: const Icon(Icons.delete, size: 18),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _format(double x) {
    final intVal = x.round();
    final s = intVal.toString();
    final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return s.replaceAllMapped(reg, (m) => '.');
  }

  String _displayDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

class BudgetItem {
  final String id;
  final double amount;
  final String category;
  final String type;
  final DateTime date;
  final DateTime? createdAt;

  BudgetItem({
    required this.id,
    required this.amount,
    required this.category,
    required this.type,
    required this.date,
    this.createdAt,
  });

  bool get isIncome => type.toLowerCase() == 'tabungan';
  bool get isExpense =>
      type.toLowerCase() == 'kebutuhan' || type.toLowerCase() == 'keinginan';
  String get group => isIncome ? 'Pemasukan' : 'Pengeluaran';
}
