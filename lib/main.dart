import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BudgetPlannerPage(),
    );
  }
}

class BudgetPlannerPage extends StatefulWidget {
  @override
  _BudgetPlannerPageState createState() => _BudgetPlannerPageState();
}

class _BudgetPlannerPageState extends State<BudgetPlannerPage> {
  String selectedPeriod = "November 2025";
  String selectedCategory = "Kebutuhan";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Budget Planner"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Period dropdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Aliran Kas", style: TextStyle(fontSize: 16)),
                DropdownButton<String>(
                  value: selectedPeriod,
                  items: ["November 2025", "Desember 2025", "Januari 2026"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => selectedPeriod = v!),
                ),
              ],
            ),
            SizedBox(height: 10),

            // Donut Chart
            Container(
              height: 260,
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: 60,
                  sectionsSpace: 2,
                  sections: [
                    PieChartSectionData(
                      value: 41,
                      title: "Tabungan\n41%",
                      radius: 60,
                      color: Colors.orange,
                      titleStyle: TextStyle(fontSize: 12, color: Colors.white),
                    ),
                    PieChartSectionData(
                      value: 33,
                      title: "Kebutuhan\n33%",
                      radius: 60,
                      color: Colors.blue,
                      titleStyle: TextStyle(fontSize: 12, color: Colors.white),
                    ),
                    PieChartSectionData(
                      value: 22,
                      title: "Keinginan\n22%",
                      radius: 60,
                      color: Colors.red,
                      titleStyle: TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Category Tabs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _categoryButton("Kebutuhan", Colors.blue),
                _categoryButton("Keinginan", Colors.red),
                _categoryButton("Tabungan", Colors.orange),
              ],
            ),

            SizedBox(height: 20),

            // Transaction list
            _transactionCard(
              date: "10–16",
              label: "Kebutuhan",
              description: "Belanja Bahan Makanan",
              amount: "Rp 116.000",
            ),

            SizedBox(height: 20),

            // Totals bar
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Total: Rp 116.000",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text("Budget: Rp 5.000.000",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Beranda"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Statistik"),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Trans."),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }

  // -------- Widgets ----------
  Widget _categoryButton(String label, Color color) {
    bool active = selectedCategory == label;
    return GestureDetector(
      onTap: () => setState(() => selectedCategory = label),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.2) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? color : Colors.black87,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _transactionCard({
    required String date,
    required String label,
    required String description,
    required String amount,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(label, style: TextStyle(fontSize: 12)),
        ),
        title: Text(description, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(date),
        trailing: Text(amount,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ),
    );
  }
}