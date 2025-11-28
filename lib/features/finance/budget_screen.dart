import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final double _remainingBudget = 1800000;
  final double _income = 5000000;
  final double _expenses = 3200000;

  final List<BudgetCategory> _categories = [
    BudgetCategory(
      name: 'Kebutuhan',
      amount: 2000000,
      percentage: 62.5,
      color: Colors.blue,
    ),
    BudgetCategory(
      name: 'Keinginan',
      amount: 800000,
      percentage: 25,
      color: Colors.purple,
    ),
    BudgetCategory(
      name: 'Tabungan',
      amount: 400000,
      percentage: 12.5,
      color: Colors.green,
    ),
  ];

  final List<Transaction> _transactions = [
    Transaction(
      title: 'Groceries bulanan',
      category: 'Makanan',
      date: DateTime(2025, 11, 16),
      amount: -500000,
      type: TransactionType.expense,
    ),
    Transaction(
      title: 'Gaji bulan November',
      category: 'Gaji',
      date: DateTime(2025, 11, 15),
      amount: 5000000,
      type: TransactionType.income,
    ),
    Transaction(
      title: 'Bensin dan Grab',
      category: 'Transport',
      date: DateTime(2025, 11, 14),
      amount: -300000,
      type: TransactionType.expense,
    ),
    Transaction(
      title: 'Nonton bioskop',
      category: 'Hiburan',
      date: DateTime(2025, 11, 13),
      amount: -150000,
      type: TransactionType.expense,
    ),
    Transaction(
      title: 'Listrik & internet',
      category: 'Tagihan',
      date: DateTime(2025, 11, 12),
      amount: -400000,
      type: TransactionType.expense,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Planner'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subtitle
            Text(
              'Kelola keuangan Anda',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),

            // Budget Overview Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sisa Budget Bulan Ini',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rp ${_formatCurrency(_remainingBudget)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.trendingUp,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pemasukan',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'Rp ${_formatCurrency(_income, short: true)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.trendingDown,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pengeluaran',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'Rp ${_formatCurrency(_expenses, short: true)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(LucideIcons.trendingUp, size: 18),
                    label: const Text('Tambah Pemasukan'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.green),
                      foregroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(LucideIcons.trendingDown, size: 18),
                    label: const Text('Tambah Pengeluaran'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.red),
                      foregroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Alokasi Budget
            const Text(
              'Alokasi Budget',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Donut Chart with Center Text
            SizedBox(
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 0,
                      centerSpaceRadius: 60,
                      sections: _categories.map((category) {
                        return PieChartSectionData(
                          value: category.amount,
                          title: '',
                          color: category.color,
                          radius: 40,
                        );
                      }).toList(),
                    ),
                  ),
                  // Center Text
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${(_categories.fold(0.0, (sum, cat) => sum + cat.amount) / 1000000).toStringAsFixed(1)}jt',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Budget Categories Legend
            ..._categories.map((category) => _buildCategoryItem(category)),

            const SizedBox(height: 32),

            // Transaction History Header
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Riwayat Transaksi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Lihat Semua',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Transaction List
            ..._transactions.map(
              (transaction) => _buildTransactionItem(transaction),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(BudgetCategory category) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: category.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(category.name, style: const TextStyle(fontSize: 15)),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Rp ${_formatCurrency(category.amount)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Text(
                '${category.percentage}%',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    final isIncome = transaction.type == TransactionType.income;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              color: isIncome
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isIncome ? LucideIcons.trendingUp : LucideIcons.trendingDown,
              color: isIncome ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      transaction.category,
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${transaction.date.day} Nov ${transaction.date.year}',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}Rp ${_formatCurrency(transaction.amount.abs())}',
            style: TextStyle(
              color: isIncome ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount, {bool short = false}) {
    if (short) {
      if (amount >= 1000000) {
        return '${(amount / 1000000).toStringAsFixed(amount % 1000000 == 0 ? 0 : 1)}jt';
      } else if (amount >= 1000) {
        return '${(amount / 1000).toStringAsFixed(0)}k';
      }
    }
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }
}

class BudgetCategory {
  final String name;
  final double amount;
  final double percentage;
  final Color color;

  BudgetCategory({
    required this.name,
    required this.amount,
    required this.percentage,
    required this.color,
  });
}

enum TransactionType { income, expense }

class Transaction {
  final String title;
  final String category;
  final DateTime date;
  final double amount;
  final TransactionType type;

  Transaction({
    required this.title,
    required this.category,
    required this.date,
    required this.amount,
    required this.type,
  });
}
