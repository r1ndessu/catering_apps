import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class TrackOrdersScreen extends StatefulWidget {
  @override
  _TrackOrdersScreenState createState() => _TrackOrdersScreenState();
}

class _TrackOrdersScreenState extends State<TrackOrdersScreen> {
  List<Map<String, dynamic>> bookings = [];

  @override
  void initState() {
    super.initState();
    loadBookings();
  }

  Future<void> loadBookings() async {
    var trackOrdersBox = await Hive.openBox('trackOrders');
    setState(() {
      bookings = trackOrdersBox.values.map((e) => Map<String, dynamic>.from(e)).toList();
    });
  }

  void toggleStatus(int index) async {
    var trackOrdersBox = await Hive.openBox('trackOrders');
    setState(() {
      bookings[index]['status'] = bookings[index]['status'] == 'Completed' ? 'Pending' : 'Completed';
      trackOrdersBox.putAt(index, bookings[index]);
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
        title: Text('Track Orders', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Your Booked Packages:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
            SizedBox(height: 10),
            Expanded(
              child: bookings.isEmpty
                  ? Text('No bookings yet!', style: TextStyle(color: Colors.grey))
                  : ListView.builder(
                      itemCount: bookings.length,
                      itemBuilder: (context, index) {
                        var booking = bookings[index];
                        return Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            title: Text('${booking['packages'].join(', ')} - ${booking['dateTime']}',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Booked by: ${booking['customerName']}'),
                                SizedBox(height: 5),
                                Text('Total Price: \$${booking['total'].toStringAsFixed(2)}',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                                SizedBox(height: 5),
                                Text('Status: ${booking['status'] ?? 'Pending'}',
                                    style: TextStyle(
                                        color: booking['status'] == 'Completed' ? Colors.green : Colors.red)),
                              ],
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                booking['status'] == 'Completed' ? Icons.check_circle : Icons.cancel,
                                color: booking['status'] == 'Completed' ? Colors.green : Colors.red,
                              ),
                              onPressed: () => toggleStatus(index),
                            ),
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