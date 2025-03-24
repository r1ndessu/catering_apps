import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class CashieringScreen extends StatefulWidget {
  @override
  _CashieringScreenState createState() => _CashieringScreenState();
}

class _CashieringScreenState extends State<CashieringScreen> {
  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> packages = [];
  List<Map<String, dynamic>> cart = [];
  double totalPackagesAmount = 0.0;

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

    var trackOrdersBox = await Hive.openBox('trackOrders');
    trackOrdersBox.add({
      'customerName': customerName,
      'dateTime': dateTime,
      'total': total,
      'packages': cartPackages.map((p) => p['name']).toList(),
      'status': 'Completed'
    });
  }

  void completeTransaction() {
    TextEditingController nameController = TextEditingController();
    TextEditingController suggestionController = TextEditingController();
    TextEditingController moneyController = TextEditingController();

    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
      title: Center(
        child: Text(
        'Complete Transaction',
        style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Customer Name',
            border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          ),
          SizedBox(height: 10),
          Row(
          children: [
            Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              ),
              onPressed: () async {
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime.now().subtract(Duration(days: 365)),
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
            SizedBox(width: 10),
            Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              ),
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
          SizedBox(height: 10),
          TextField(
          controller: suggestionController,
          decoration: InputDecoration(
            labelText: 'Suggestion',
            border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          ),
          SizedBox(height: 10),
          TextField(
          controller: moneyController,
          decoration: InputDecoration(
            labelText: 'Amount Received',
            border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          keyboardType: TextInputType.number,
          ),
          SizedBox(height: 20),
          Text(
          'Selected Package: ${cart.map((p) => '${p['name']} x${p['quantity']}').join(', ')}',
          style: TextStyle(fontStyle: FontStyle.italic, fontSize: 14),
          ),
          SizedBox(height: 5),
          Text(
          'Total Amount: \$${getTotalAmount().toStringAsFixed(2)}',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          
        ],
        ),
      ),
      actions: [
        TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          ),
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
        child: Text('Confirm', style: TextStyle(color: Colors.white)),
        ),
      ],
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
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ),
  );
}
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
         leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.orange, size: 30),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Cashiering', style: TextStyle(fontWeight: FontWeight.bold,color: Colors.orange)),
      ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Available Packages',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: packages.length,
            itemBuilder: (context, index) {
              final package = packages[index];
              return Card(
          margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade200, Colors.yellow.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
            Container(
              width: 50,
              height: 70,
              child: Icon(Icons.book_rounded, color: const Color.fromARGB(255, 255, 255, 255), size: 50),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
              package['name'] ?? 'Package',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
              'Inclusion:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Wrap(
              spacing: 4,
              children: (package['inclusions'] as List<dynamic>?)
                ?.map((item) => Chip(
                      label: Text(item, style: TextStyle(fontSize: 12,color: Colors.white)),
                      backgroundColor: const Color.fromARGB(255, 255, 164, 16),
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
                  '\$${package['price']}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => addToCart(package),
                  style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: CircleBorder(),
              padding: EdgeInsets.all(8),
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
        GestureDetector(
          onTap: completeTransaction,
          child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange, const Color.fromARGB(255, 255, 136, 0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16.0),
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
            '${cart.length}',
            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text(
                'Complete Transaction',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                'Text message here',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
              ],
            ),
          ],
            ),
            Text(
          '\$${getTotalAmount().toStringAsFixed(2)}',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: const Color.fromARGB(255, 255, 255, 255)),
            ),
          ],
        ),
          ),
        ),
      ],
    ),
  );
}
}