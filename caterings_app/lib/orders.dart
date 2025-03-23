import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class TrackOrdersScreen extends StatefulWidget {
  @override
  _TrackOrdersScreenState createState() => _TrackOrdersScreenState();
}

class _TrackOrdersScreenState extends State<TrackOrdersScreen> {
  List<Map<String, dynamic>> bookings = [];
  Map<int, List<bool>> inclusionSelections = {};

  @override
  void initState() {
    super.initState();
    loadBookings();
  }

  Future<void> loadBookings() async {
    var box = await Hive.openBox('bookings');
    setState(() {
      bookings = box.values.map((e) {
        var booking = Map<String, dynamic>.from(e);
        booking['price'] = double.tryParse(booking['price'].toString()) ?? 0.0;
        return booking;
      }).toList();

      // Initialize checkbox selections for inclusions
      inclusionSelections = {
        for (int i = 0; i < bookings.length; i++)
          i: List<bool>.filled((bookings[i]['inclusions'] as List<dynamic>?)?.length ?? 0, false),
      };
    });
  }

  void toggleStatus(int index) async {
    if (inclusionSelections[index]?.contains(false) == true) {
      // Show error if not all checkboxes are selected
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 100,
              ),
              SizedBox(height: 10),
              Text(
                'Error',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Please complete all inclusions before marking the status as Done.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
      return;
    }

    var box = await Hive.openBox('bookings');
    setState(() {
      bookings[index]['status'] = bookings[index]['status'] == 'Done' ? 'Not Yet' : 'Done';
      box.putAt(index, bookings[index]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
         leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.orange, size: 30),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Track Your Orders', style: TextStyle(fontWeight: FontWeight.bold,color: Colors.orange)),
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(height: 30),
            Text('Your Booked Packages:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
            SizedBox(height: 10),
            Expanded(
              child: bookings.isEmpty
                  ? Text('No bookings yet!', style: TextStyle(color: Colors.grey))
                  : ListView.builder(
                      itemCount: bookings.length,
                      itemBuilder: (context, index) {
                        var booking = bookings[index];
                        var inclusions = booking['inclusions'] as List<dynamic>? ?? [];
                        return Container(
                          margin: EdgeInsets.only(bottom: 16.0),
                          padding: EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300, width: 1),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade200,
                                blurRadius: 5,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Receipt',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepOrange,
                                ),
                              ),
                              Divider(color: Colors.grey.shade400),
                              Text('Package: ${booking['package']}'),
                              Text('Date: ${booking['date']}'),
                              Text('Booked by: ${booking['name']}'),
                              Text('Contact: ${booking['contact']}'),
                              SizedBox(height: 5),
                              Text(
                                'Inclusions:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Wrap(
                                spacing: 8.0,
                                runSpacing: 4.0,
                                children: List.generate(inclusions.length, (i) {
                                  return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Checkbox(
                                    value: inclusionSelections[index]?[i] ?? false,
                                    onChanged: (value) {
                                      setState(() {
                                      inclusionSelections[index]?[i] = value ?? false;
                                      });
                                    },
                                    ),
                                    Text(inclusions[i]),
                                  ],
                                  );
                                }),
                                ),
                              SizedBox(height: 5),
                              Text(
                                'Price: \$${booking['price'].toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              SizedBox(height: 5),
                              Divider(color: Colors.grey.shade400),
                              Text(
                                'Status: ${booking['status'] ?? 'Not Yet'}',
                                style: TextStyle(
                                  color: booking['status'] == 'Done' ? Colors.green : Colors.red,
                                ),
                              ),
                              
                              Align(
                                alignment: Alignment.centerRight,
                                child: IconButton(
                                  icon: Icon(
                                    booking['status'] == 'Done' ? Icons.check_circle : Icons.cancel,
                                    color: booking['status'] == 'Done' ? Colors.green : Colors.red,
                                  ),
                                  onPressed: () => toggleStatus(index),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}