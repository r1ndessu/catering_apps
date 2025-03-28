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
  int pendingOrders = 0;
  double pendingEarnings = 0;
  int totalPackagesSold = 0;
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
      // Convert the date string to a proper format
      List<String> parts = dateString.split(' ');
      String datePart = parts[0];
      
      // Parse date components
      List<String> datePieces = datePart.split('-');
      if (datePieces.length != 3) return null;
      
      int year = int.parse(datePieces[0]);
      int month = int.parse(datePieces[1]);
      int day = int.parse(datePieces[2]);
      
      return DateTime(year, month, day);
    } catch (e) {
      print('Date format error: $e');
      return null;
    }
  }

  Future<void> fetchDashboardData() async {
    try {
    var trackOrdersBox = await Hive.openBox('trackOrders');
    Map<String, int> salesCount = {};
      double filteredEarnings = 0.0;
      int filteredSales = 0;
      int filteredPendingOrders = 0;
      double filteredPendingEarnings = 0.0;
      int totalPackages = 0;

      // Debug print the raw data
      print('Raw Data:');
      for (var booking in trackOrdersBox.values) {
        print('Booking: ${booking.toString()}');
      }

      // Calculate total earnings and sales for the selected date range
      for (var booking in trackOrdersBox.values) {
        print('Processing booking: ${booking.toString()}');
        
        DateTime? bookingDate = parseCustomDate(booking['dateTime']);
        print('Parsed date: $bookingDate');
        
        bool isInRange = true;
        if (fromDate != null) {
          isInRange = isInRange && (bookingDate?.isAfter(fromDate!) ?? false);
        }
        if (toDate != null) {
          isInRange = isInRange && (bookingDate?.isBefore(toDate!.add(Duration(days: 1))) ?? false);
        }
        
        if (bookingDate != null && isInRange) {
          print('Booking in range: ${booking.toString()}');
          
          // Handle the total amount
          String totalStr = booking['total'].toString().replaceAll('\$', '');
          double total = double.tryParse(totalStr) ?? 0.0;
          
        if (booking['status'] == 'Completed') {
            filteredSales++;
            filteredEarnings += total;
            
            // Handle packages
            var packages = booking['packages'];
            if (packages is List) {
              for (var package in packages) {
                if (package is Map) {
                  String packageName = package['name'];
                  int quantity = package['quantity'] ?? 1;
                  salesCount[packageName] = (salesCount[packageName] ?? 0) + quantity;
                  totalPackages += quantity;
                } else if (package is String) {
                  salesCount[package] = (salesCount[package] ?? 0) + 1;
                  totalPackages += 1;
                }
              }
            } else if (packages is String) {
              salesCount[packages] = (salesCount[packages] ?? 0) + 1;
              totalPackages += 1;
            }
          } else {
            filteredPendingOrders++;
            filteredPendingEarnings += total;
          }
        }
      }

      // Debug prints
      print('After processing:');
      print('Date Range: ${fromDate?.toString()} to ${toDate?.toString()}');
      print('Total Sales: $filteredSales');
      print('Total Earnings: $filteredEarnings');
      print('Pending Orders: $filteredPendingOrders');
      print('Pending Earnings: $filteredPendingEarnings');
      print('Package Sales: $salesCount');
      print('Total Packages Sold: $totalPackages');

      setState(() {
        totalOrders = trackOrdersBox.length;
        totalSales = filteredSales;
        totalEarnings = filteredEarnings;
        pendingOrders = filteredPendingOrders;
        pendingEarnings = filteredPendingEarnings;
        packageSales = Map<String, int>.from(salesCount);
        totalPackagesSold = totalPackages;
      });
    } catch (e, stackTrace) {
      print('Error in fetchDashboardData: $e');
      print('Stack trace: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Dashboard'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                fromDate = null;
                toDate = null;
              });
              fetchDashboardData();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: fetchDashboardData,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.orange.shade100, Colors.white],
            ),
          ),
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'Sales Dashboard',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 2,
                            color: Colors.black12,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  // Date Range Selection
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Date Range',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                            Text(
                              'From:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                              ),
                            ),
                  TextButton(
                    onPressed: () async {
                      DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: fromDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                      setState(() {
                        fromDate = picked;
                        fetchDashboardData();
                      });
                                        },
                              child: Text(
                                fromDate == null
                                    ? 'Select Date'
                                    : '${fromDate!.toLocal()}'.split(' ')[0],
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              'To:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                              ),
                            ),
                  TextButton(
                    onPressed: () async {
                      DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: toDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                      setState(() {
                        toDate = picked;
                        fetchDashboardData();
                      });
                                        },
                              child: Text(
                                toDate == null
                                    ? 'Select Date'
                                    : '${toDate!.toLocal()}'.split(' ')[0],
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  // Total Packages Sold Card
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.orange.shade400,
                          Colors.orange.shade600,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Packages Sold',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.inventory_2, color: Colors.white, size: 30),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                totalPackagesSold.toString(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Total Units',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          if (fromDate != null || toDate != null) ...[
                            SizedBox(height: 12),
                            Text(
                              'Period: ${fromDate != null ? fromDate!.toLocal().toString().split(' ')[0] : 'Start'} - ${toDate != null ? toDate!.toLocal().toString().split(' ')[0] : 'Present'}',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  // Total Sales Card
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.orange,
                          Colors.orange.shade700,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Completed Orders',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.check_circle, color: Colors.white, size: 30),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Number of Completed Orders',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    totalSales.toString(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Total Revenue',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '\$${totalEarnings.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (fromDate != null || toDate != null) ...[
                            SizedBox(height: 12),
                            Text(
                              'Period: ${fromDate != null ? fromDate!.toLocal().toString().split(' ')[0] : 'Start'} - ${toDate != null ? toDate!.toLocal().toString().split(' ')[0] : 'Present'}',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
            ],
          ),
        ),
      ),
                  SizedBox(height: 24),
                  // Pending Orders Card
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.orange.shade300,
                          Colors.orange.shade400,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
      child: Padding(
                      padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Pending Orders',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.pending, color: Colors.white, size: 30),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Number of Pending Orders',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    pendingOrders.toString(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Pending Revenue',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '\$${pendingEarnings.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
              ],
            ),
          ],
        ),
                          if (fromDate != null || toDate != null) ...[
                            SizedBox(height: 12),
                            Text(
                              'Period: ${fromDate != null ? fromDate!.toLocal().toString().split(' ')[0] : 'Start'} - ${toDate != null ? toDate!.toLocal().toString().split(' ')[0] : 'Present'}',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  // Top Selling Packages
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Top Selling Packages',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        SizedBox(height: 16),
                        packageSales.isEmpty
                            ? Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.local_offer_outlined,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'No completed orders for selected period',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                children: (packageSales.entries.toList()
                                  ..sort((a, b) => b.value.compareTo(a.value)))
                                    .map((entry) => Padding(
                                          padding: const EdgeInsets.only(bottom: 12),
                                          child: Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black12,
                                                  blurRadius: 4,
                                                  offset: Offset(0, 2),
                                                ),
                                              ],
                                            ),
      child: Padding(
                                              padding: const EdgeInsets.all(16.0),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    padding: EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.orange.shade100,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(
                                                      Icons.local_offer,
                                                      color: Colors.orange,
                                                      size: 24,
                                                    ),
                                                  ),
                                                  SizedBox(width: 16),
                                                  Expanded(
        child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                                                        Text(
                                                          entry.key,
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 16,
                                                            color: Colors.orange.shade900,
                                                          ),
                                                        ),
                                                        SizedBox(height: 4),
                                                        Text(
                                                          'Sales: ${entry.value}',
                                                          style: TextStyle(
                                                            color: Colors.orange.shade700,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
