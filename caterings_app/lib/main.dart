import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:caterings_app/cashiering.dart';
import 'package:caterings_app/packages.dart';
import 'package:caterings_app/orders.dart';
import 'package:caterings_app/sales.dart';

void main() async {
  await Hive.initFlutter();
  runApp(const CateringApp());
}

class CateringApp extends StatelessWidget {
  const CateringApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catering Services',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleTextStyle: TextStyle(fontSize: 30 , fontWeight: FontWeight.bold , color: Colors.white), // Increased font size
        toolbarHeight: 100, // Increased toolbar height
        centerTitle: true,
        title: const Text('Catering Services'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 56), 
              const Text(
                'Select options',
                style: TextStyle(fontSize: 26, ),
              ),
              const SizedBox(height: 56), // Add spacing between text and grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  shrinkWrap: true,
                  children: [
                    _buildCard(
                      context,
                      icon: Icons.fastfood,
                      label: 'Book a Package',
                      color: Colors.blue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => CashieringScreen()),
                        );
                      },
                    ),
                    _buildCard(
                      context,
                      icon: Icons.shopping_cart,
                      label: 'Track Orders',
                      color: Colors.red,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => TrackOrdersScreen()),
                        );
                      },
                    ),
                    _buildCard(
                      context,
                      icon: Icons.settings,
                      label: 'Manage Packages',
                      color: Colors.orange,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ManagePackagesScreen()),
                        );
                      },
                    ),
                    _buildCard(
                      context,
                      icon: Icons.bar_chart,
                      label: 'Sales Dashboard',
                      color: Colors.green,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SalesScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

  Widget _buildCard(BuildContext context,
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 1, // Adjust the width
        height: 1, // Adjust the height
        child: Card(
          color: color,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 80, color: Colors.white), // Increased icon size
                const SizedBox(height: 1),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 22), // Increased font size
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }