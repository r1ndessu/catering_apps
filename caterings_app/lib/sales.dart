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
  DateTime? fromDate;
  DateTime? toDate;
  Map<String, int> packageSales = {};

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  DateTime? parseCustomDate(String dateString) {
    try {
      // Fixing invalid date format issues
      dateString = dateString.replaceAll(' ', 'T').replaceAll('PM', ' PM').replaceAll('AM', ' AM');
      return DateTime.tryParse(dateString);
    } catch (e) {
      print('Date format error: $e');
      return null;
    }
  }

  Future<void> fetchDashboardData() async {
    var trackOrdersBox = await Hive.openBox('trackOrders');
    Map<String, int> salesCount = {};

    setState(() {
      totalOrders = trackOrdersBox.length;
      totalEarnings = trackOrdersBox.values.fold(
          0.0, (sum, booking) => sum + (double.tryParse(booking['total'].toString()) ?? 0.0));

      totalSales = trackOrdersBox.values
    .where((booking) {
      DateTime? bookingDate = parseCustomDate(booking['dateTime']);
      return booking['status'] == 'Completed' &&
          bookingDate != null &&
          (fromDate == null || !bookingDate.isBefore(fromDate!)) &&
          (toDate == null || !bookingDate.isAfter(toDate!));
    })
    .length;

      // Count sales for each package
      for (var booking in trackOrdersBox.values) {
        if (booking['status'] == 'Completed') {
          for (var packageName in booking['packages']) {
            salesCount[packageName] = (salesCount[packageName] ?? 0) + 1;
          }
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
              dashboardCard('Total Earnings', totalEarnings.toStringAsFixed(2), Colors.blue, Icons.attach_money_outlined),
              const SizedBox(height: 16),
              dashboardCard('Total Orders', totalOrders.toString(), Colors.green, Icons.shopping_bag),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('From:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () async {
                      DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: fromDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now());
                      if (picked != null) {
                        setState(() {
                          fromDate = picked;
                          fetchDashboardData();
                        });
                      }
                    },
                    child: Text(fromDate == null ? 'Select Date' : '${fromDate!.toLocal()}'.split(' ')[0]),
                  ),
                  const Text('To:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () async {
                      DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: toDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now());
                      if (picked != null) {
                        setState(() {
                          toDate = picked;
                          fetchDashboardData();
                        });
                      }
                    },
                    child: Text(toDate == null ? 'Select Date' : '${toDate!.toLocal()}'.split(' ')[0]),
                  ),
                ],
              ),
              dashboardCard('Total Sales', totalSales.toString(), Colors.red, Icons.show_chart),
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

  Widget dashboardCard(String title, String value, Color color, IconData icon) {
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
