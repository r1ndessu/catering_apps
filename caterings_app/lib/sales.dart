import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  double totalEarnings = 0;
  int totalOrders = 0;
  int totalSales = 0;
  String selectedFilter = 'Daily';
  Map<String, int> packageSales = {};

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    var box = await Hive.openBox('bookings');
    DateTime now = DateTime.now();
    Map<String, int> salesCount = {};

    setState(() {
      totalOrders = box.length;
      totalEarnings = box.values.fold(0.0, (sum, booking) => sum + (double.tryParse(booking['price'].toString()) ?? 0.0));

      if (selectedFilter == 'Daily') {
        totalSales = box.values.where((booking) => booking['status'] == 'Done' && DateTime.parse(booking['date']).day == now.day).length;
      } else if (selectedFilter == 'Weekly') {
        totalSales = box.values.where((booking) => booking['status'] == 'Done' && now.difference(DateTime.parse(booking['date'])).inDays <= 7).length;
      } else if (selectedFilter == 'Monthly') {
        totalSales = box.values.where((booking) => booking['status'] == 'Done' && DateTime.parse(booking['date']).month == now.month).length;
      }

      // Count sales for each package
      for (var booking in box.values) {
        if (booking['status'] == 'Done') {
          String packageName = booking['package'];
          salesCount[packageName] = (salesCount[packageName] ?? 0) + 1;
        }
      }
      packageSales = salesCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Dashboard'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => fetchDashboardData(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text('Dashboard', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
              const SizedBox(height: 26),

              dashboardCard('Total Earnings', totalEarnings.toStringAsFixed(2), Colors.blue, Icons.attach_money_outlined, () {}),
              const SizedBox(height: 16),
              dashboardCard('Total Orders', totalOrders.toString(), Colors.green, Icons.shopping_bag, () {}),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Sales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    value: selectedFilter,
                    items: ['Daily', 'Weekly', 'Monthly'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        selectedFilter = newValue!;
                        fetchDashboardData();
                      });
                    },
                  ),
                ],
              ),
              dashboardCard('Total Sales', totalSales.toString(), Colors.red, Icons.show_chart, () {}),
              const SizedBox(height: 16),

              const Text('Top Selling Packages', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              packageSales.isEmpty
                  ? const Text('No sales data available', style: TextStyle(color: Colors.grey))
                  : Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: packageSales.entries.map((entry) {
                        return smallCard(entry.key, entry.value);
                      }).toList(),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget dashboardCard(String title, String value, Color color, IconData icon, VoidCallback onViewFull) {
    return Card(
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                Icon(icon, color: Colors.white, size: 60),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget smallCard(String packageName, int salesCount) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(packageName, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text('Sales: $salesCount', style: const TextStyle(color: Colors.blueGrey)),
          ],
        ),
      ),
    );
  }
}