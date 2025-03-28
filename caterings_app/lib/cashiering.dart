import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class CashieringScreen extends StatefulWidget {
  const CashieringScreen({super.key});

  @override
  _CashieringScreenState createState() => _CashieringScreenState();
}

class _CashieringScreenState extends State<CashieringScreen> {
  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> packages = [];
  List<Map<String, dynamic>> filteredPackages = [];
  List<Map<String, dynamic>> cart = [];
  double totalPackagesAmount = 0.0;
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  TextEditingController searchController = TextEditingController();
  String selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    loadItems();
    loadPackages();
  }

  Future<void> loadItems() async {
    var itemsBox = await Hive.openBox('items');
    setState(() {
      items = itemsBox.values.map((item) {
        return Map<String, dynamic>.from(item);
      }).toList();
    });
  }

  Future<void> loadPackages() async {
    var packageBox = await Hive.openBox('packages');
    setState(() {
      packages = packageBox.values.map((item) {
        return Map<String, dynamic>.from(item);
      }).toList();
      filterPackages();
    });
  }

  void filterPackages() {
    setState(() {
      // First filter by name
      var nameFilteredPackages = packages.where((package) {
        return searchController.text.isEmpty ||
            package['name'].toString().toLowerCase().contains(searchController.text.toLowerCase());
      }).toList();

      // Then apply price sorting if needed
      if (selectedFilter == 'Low to High') {
        nameFilteredPackages.sort((a, b) {
          double priceA = double.tryParse(a['price'].toString()) ?? 0;
          double priceB = double.tryParse(b['price'].toString()) ?? 0;
          return priceA.compareTo(priceB);
        });
      } else if (selectedFilter == 'High to Low') {
        nameFilteredPackages.sort((a, b) {
          double priceA = double.tryParse(a['price'].toString()) ?? 0;
          double priceB = double.tryParse(b['price'].toString()) ?? 0;
          return priceB.compareTo(priceA);
        });
      }

      filteredPackages = nameFilteredPackages;
    });
  }

  void calculatePackageTotal() {
    totalPackagesAmount = packages.fold(0.0, (sum, package) =>
      sum + ((package['quantity'] != null && package['quantity'] > 0)
        ? ((package['price'] is String ? double.tryParse(package['price']) ?? 0 : package['price']) * package['quantity'])
        : 0));
    setState(() {});
  }

  double getTotalAmount() {
    return cart.fold(0.0, (sum, package) => sum + ((package['price'] is String ? double.tryParse(package['price']) ?? 0 : package['price']) * package['quantity']));
  }

  void addToCart(Map<String, dynamic> package) {
    setState(() {
      int index = cart.indexWhere((item) => item['name'] == package['name']);
      if (index >= 0) {
        cart[index]['quantity'] += 1;
      } else {
        cart.add({...package, 'quantity': 1});
      }
    });
  }

  void removeFromCart(int index) {
    setState(() {
      cart.removeAt(index);
    });
  }

  Future<void> saveTransaction(List<Map<String, dynamic>> cartPackages, double total, String customerName, String dateTime, String suggestions, double customerMoney) async {
    var transactionsBox = await Hive.openBox('transactions');
    transactionsBox.add({
      'packages': cartPackages,
      'total': total,
      'date': DateTime.now().toString(),
      'customerName': customerName,
      'dateTime': dateTime,
      'suggestions': suggestions,
      'customerMoney': customerMoney,
      'change': customerMoney - total
    });

    // Get the packages box to fetch inclusions
    var packageBox = await Hive.openBox('packages');
    
    // Create a map of package names to their inclusions
    Map<String, List<dynamic>> packageInclusions = {};
    for (var package in packageBox.values) {
      packageInclusions[package['name']] = package['inclusions'];
    }

    var trackOrdersBox = await Hive.openBox('trackOrders');
    trackOrdersBox.add({
      'customerName': customerName,
      'dateTime': dateTime,
      'total': total,
      'packages': cartPackages.map((p) => {
        'name': p['name'],
        'quantity': p['quantity'],
        'inclusions': packageInclusions[p['name']] ?? []
      }).toList(),
      'status': 'Pending' // Default status
    });
  }

  void completeTransaction() {
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please add at least one package to the cart before proceeding.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    TextEditingController nameController = TextEditingController();
    TextEditingController suggestionController = TextEditingController();
    TextEditingController moneyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Complete Transaction',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Customer Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(Duration(days: 365)),
                              );
                              if (pickedDate != null) {
                                setState(() => selectedDate = pickedDate);
                              }
                            },
                            child: Text(
                              'Pick up Date: ${selectedDate.toLocal().toString().split(' ')[0]}',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        Container(
                          height: 24,
                          width: 1,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        Expanded(
                          child: TextButton(
                            onPressed: () async {
                              TimeOfDay? pickedTime = await showTimePicker(
                                context: context,
                                initialTime: selectedTime,
                              );
                              if (pickedTime != null) {
                                setState(() => selectedTime = pickedTime);
                              }
                            },
                            child: Text(
                              'Pick up Time: ${selectedTime.format(context)}',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: suggestionController,
                    decoration: InputDecoration(
                      labelText: 'Suggestion',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: moneyController,
                    decoration: InputDecoration(
                      labelText: 'Amount Received',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Selected Package: ${cart.map((p) => '${p['name']} x${p['quantity']}').join(', ')}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Total Amount: \$${getTotalAmount().toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () async {
                            double customerMoney = double.tryParse(moneyController.text) ?? 0;

                            if (customerMoney < getTotalAmount()) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Insufficient amount! Please enter a valid amount.')),
                              );
                              return;
                            }

                            double finalTotal = getTotalAmount();

                            await saveTransaction(
                              cart,
                              finalTotal,
                              nameController.text,
                              '${selectedDate.toLocal().toString().split(' ')[0]} ${selectedTime.format(context)}',
                              suggestionController.text,
                              customerMoney,
                            );

                            setState(() {
                              cart.clear();
                              totalPackagesAmount = 0.0;
                            });

                            Navigator.pop(context);
                            showSuccessDialog(finalTotal, customerMoney);
                          },
                          child: Text(
                            'Confirm',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void showSuccessDialog(double finalTotal, double customerMoney) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 80),
            SizedBox(height: 16),
            Text(
              'Successfully Booked!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 16),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Amount:', style: TextStyle(fontSize: 16)),
                Text(
                  '\$${finalTotal.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Paid:', style: TextStyle(fontSize: 16)),
                Text(
                  '\$${customerMoney.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Change:', style: TextStyle(fontSize: 16)),
                Text(
                  '\$${(customerMoney - finalTotal).toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                setState(() {
                  cart.clear(); // Clear the cart
                });
                Navigator.pop(context);
              },
              child: Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 30),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Cashiering', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.orange,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.shade100, Colors.white],
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
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
                    'Available Packages',
                    style: TextStyle(
                      fontSize: 24,
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
                  SizedBox(height: 16),
                  // Search Bar
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search packages...',
                      prefixIcon: Icon(Icons.search, color: Colors.orange),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.orange.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.orange.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.orange),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) {
                      filterPackages();
                    },
                  ),
                  SizedBox(height: 16),
                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: Text('All'),
                          selected: selectedFilter == 'All',
                          onSelected: (bool selected) {
                            setState(() {
                              selectedFilter = 'All';
                              filterPackages();
                            });
                          },
                          selectedColor: Colors.orange,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: selectedFilter == 'All' ? Colors.white : Colors.black,
                          ),
                        ),
                        SizedBox(width: 8),
                        FilterChip(
                          label: Text('Low to High'),
                          selected: selectedFilter == 'Low to High',
                          onSelected: (bool selected) {
                            setState(() {
                              selectedFilter = 'Low to High';
                              filterPackages();
                            });
                          },
                          selectedColor: Colors.orange,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: selectedFilter == 'Low to High' ? Colors.white : Colors.black,
                          ),
                        ),
                        SizedBox(width: 8),
                        FilterChip(
                          label: Text('High to Low'),
                          selected: selectedFilter == 'High to Low',
                          onSelected: (bool selected) {
                            setState(() {
                              selectedFilter = 'High to Low';
                              filterPackages();
                            });
                          },
                          selectedColor: Colors.orange,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: selectedFilter == 'High to Low' ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filteredPackages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.inbox,
                              size: 80,
                              color: Colors.orange,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No Available Package Yet!',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Please add some packages first.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: filteredPackages.length,
                      itemBuilder: (context, index) {
                        final package = filteredPackages[index];
                        return Card(
                          margin: EdgeInsets.only(bottom: 16),
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.orange.shade50, Colors.white],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade100,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.book_rounded, color: Colors.orange, size: 30),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          package['name'] ?? 'Package',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange.shade900,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Inclusion:',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange.shade700,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Wrap(
                                          spacing: 4,
                                          runSpacing: 4,
                                          children: (package['inclusions'] as List<dynamic>?)
                                                  ?.map((item) => Container(
                                                        padding: EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: Colors.orange.shade100,
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                        child: Text(
                                                          item,
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.orange.shade900,
                                                          ),
                                                        ),
                                                      ))
                                                  .toList() ??
                                              [],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '\$${package['price'] is String ? double.tryParse(package['price'])?.toStringAsFixed(2) ?? '0.00' : package['price'].toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      ElevatedButton(
                                        onPressed: () => addToCart(package),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange,
                                          shape: CircleBorder(),
                                          padding: EdgeInsets.all(12),
                                        ),
                                        child: Icon(Icons.add, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Cart',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(height: 8),
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    constraints: BoxConstraints(
                      maxHeight: cart.length > 4 ? 240 : cart.length * 80.0,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: cart.length > 4 ? ScrollPhysics() : NeverScrollableScrollPhysics(),
                      itemCount: cart.length,
                      itemBuilder: (context, index) {
                        final cartItem = cart[index];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 4),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.orange.shade100,
                              child: Icon(Icons.shopping_cart, color: Colors.orange),
                            ),
                            title: Text(
                              '${cartItem['name']} x${cartItem['quantity']}',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '\$${((cartItem['price'] is String ? double.tryParse(cartItem['price']) ?? 0 : cartItem['price']) * cartItem['quantity']).toStringAsFixed(2)}',
                              style: TextStyle(color: Colors.green.shade700),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => removeFromCart(index),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 16),
                  GestureDetector(
                    onTap: completeTransaction,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.orange, Colors.orange.shade700],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.white,
                                child: Text(
                                  '${cart.length}',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Complete Transaction',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Tap to proceed',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Text(
                            '\$${getTotalAmount().toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}