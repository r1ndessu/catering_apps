import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class TrackOrdersScreen extends StatefulWidget {
  const TrackOrdersScreen({super.key});

  @override
  _TrackOrdersScreenState createState() => _TrackOrdersScreenState();
}

class _TrackOrdersScreenState extends State<TrackOrdersScreen> {
  List<Map<String, dynamic>> bookings = [];
  List<Map<String, dynamic>> filteredBookings = [];
  String selectedFilter = 'All';
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadBookings();
  }

  Future<void> loadBookings() async {
    var trackOrdersBox = await Hive.openBox('trackOrders');
    setState(() {
      bookings = trackOrdersBox.values.map((e) => Map<String, dynamic>.from(e)).toList();
      filterBookings();
    });
  }

  void filterBookings() {
    setState(() {
      filteredBookings = bookings.where((booking) {
        bool statusMatch = selectedFilter == 'All' || 
                         (booking['status'] ?? 'Pending') == selectedFilter;
        
        bool nameMatch = searchController.text.isEmpty ||
                        booking['customerName'].toString().toLowerCase()
                        .contains(searchController.text.toLowerCase());
        
        return statusMatch && nameMatch;
      }).toList();
    });
  }

  void deleteBooking(int index) async {
    var trackOrdersBox = await Hive.openBox('trackOrders');
    await trackOrdersBox.deleteAt(index);
    await loadBookings();
  }

  Future<void> editBooking(int index, Map<String, dynamic> booking) async {
    TextEditingController customerNameController = TextEditingController(text: booking['customerName']);
    TextEditingController dateTimeController = TextEditingController(text: booking['dateTime']);
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    await showDialog(
      context: context,
      builder: (context) => Dialog(
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
                    'Edit Booking',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: customerNameController,
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
                StatefulBuilder(
                  builder: (context, setState) => Container(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              minimumSize: Size(0, 46),
                            ),
                            onPressed: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(Duration(days: 365)),
                              );
                              if (pickedDate != null) {
                                setState(() => selectedDate = pickedDate);
                                String formattedDate = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
                                dateTimeController.text = "$formattedDate ${selectedTime.format(context)}";
                              }
                            },
                            child: Text(
                              'Pick up Date: ${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
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
                            style: TextButton.styleFrom(
                              minimumSize: Size(0, 46),
                            ),
                            onPressed: () async {
                              TimeOfDay? pickedTime = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (pickedTime != null) {
                                setState(() => selectedTime = pickedTime);
                                String formattedDate = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
                                dateTimeController.text = "$formattedDate ${selectedTime.format(context)}";
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
                ),
                SizedBox(height: 16),
                Text(
                  'Selected Package:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.shade200,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking['packages'].map((p) => '${p['name']} x${p['quantity']}').join(', '),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (booking['packages'] is List && booking['packages'].isNotEmpty && booking['packages'][0]['inclusions'] != null) ...[
                        SizedBox(height: 8),
                        Text(
                          'Inclusions:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: (booking['packages'][0]['inclusions'] as List<dynamic>)
                              .map((inclusion) => Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.orange.shade200,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      inclusion.toString(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange.shade800,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Total Amount: \$${booking['total'].toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          minimumSize: Size(0, 46),
                        ),
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
                            borderRadius: BorderRadius.circular(24),
                          ),
                          minimumSize: Size(0, 46),
                          padding: EdgeInsets.symmetric(horizontal: 24),
                        ),
                        onPressed: () async {
                          var trackOrdersBox = await Hive.openBox('trackOrders');
                          Map<String, dynamic> updatedBooking = {
                            ...booking,
                            'customerName': customerNameController.text,
                            'dateTime': dateTimeController.text,
                          };
                          await trackOrdersBox.putAt(index, updatedBooking);
                          await loadBookings();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Booking updated successfully')),
                          );
                        },
                        child: Text(
                          'Save',
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
    );
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
    // Get device screen size for responsive layout
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360; // Adjust threshold as needed for Infinix X6731
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 30),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Track Orders', 
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            color: Colors.white,
            fontSize: isSmallScreen ? 18 : 20, // Adjust font size for smaller screens
          )
        ),
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
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 12.0 : 16.0,
                vertical: 16.0
              ),
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
                  // Search Bar
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search customer name...',
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
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 8.0 : 12.0,
                        vertical: 12.0
                      ),
                    ),
                    onChanged: (value) {
                      filterBookings();
                    },
                  ),
                  SizedBox(height: 16),
                  // Filter Buttons
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: Text('All Orders', 
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                            ),
                          ),
                          selected: selectedFilter == 'All',
                          onSelected: (bool selected) {
                            setState(() {
                              selectedFilter = 'All';
                              filterBookings();
                            });
                          },
                          selectedColor: Colors.orange,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: selectedFilter == 'All' ? Colors.white : Colors.black,
                          ),
                          padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 6.0 : 8.0),
                        ),
                        SizedBox(width: 8),
                        FilterChip(
                          label: Text('Completed',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                            ),
                          ),
                          selected: selectedFilter == 'Completed',
                          onSelected: (bool selected) {
                            setState(() {
                              selectedFilter = 'Completed';
                              filterBookings();
                            });
                          },
                          selectedColor: Colors.orange,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: selectedFilter == 'Completed' ? Colors.white : Colors.black,
                          ),
                          padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 6.0 : 8.0),
                        ),
                        SizedBox(width: 8),
                        FilterChip(
                          label: Text('Pending',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                            ),
                          ),
                          selected: selectedFilter == 'Pending',
                          onSelected: (bool selected) {
                            setState(() {
                              selectedFilter = 'Pending';
                              filterBookings();
                            });
                          },
                          selectedColor: Colors.orange,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: selectedFilter == 'Pending' ? Colors.white : Colors.black,
                          ),
                          padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 6.0 : 8.0),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filteredBookings.isEmpty
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
                              Icons.shopping_cart_outlined,
                              size: 80,
                              color: Colors.orange,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No bookings found!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
                      itemCount: filteredBookings.length,
                      itemBuilder: (context, index) {
                        var booking = filteredBookings[index];
                        return Container(
                          margin: EdgeInsets.only(bottom: 16),
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
                              ListTile(
                                contentPadding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
                                title: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade100,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.event,
                                        color: Colors.orange,
                                        size: isSmallScreen ? 16 : 20,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Packages:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: isSmallScreen ? 14 : 16,
                                              color: Colors.orange.shade900,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: (booking['packages'] as List<dynamic>).map((package) {
                                              if (package is Map) {
                                                return Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      '${package['name']} x${package['quantity']}',
                                                      style: TextStyle(
                                                        color: Colors.orange.shade700,
                                                        fontSize: isSmallScreen ? 12 : 14,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    if (package['inclusions'] != null) ...[
                                                      SizedBox(height: 4),
                                                      Wrap(
                                                        spacing: 4,
                                                        runSpacing: 4,
                                                        children: (package['inclusions'] as List<dynamic>)
                                                            .map((inclusion) => Container(
                                                                  padding: EdgeInsets.symmetric(
                                                                    horizontal: isSmallScreen ? 6 : 8,
                                                                    vertical: 4,
                                                                  ),
                                                                  decoration: BoxDecoration(
                                                                    color: Colors.orange.shade50,
                                                                    borderRadius: BorderRadius.circular(12),
                                                                    border: Border.all(
                                                                      color: Colors.orange.shade200,
                                                                      width: 1,
                                                                    ),
                                                                  ),
                                                                  child: Text(
                                                                    inclusion.toString(),
                                                                    style: TextStyle(
                                                                      fontSize: isSmallScreen ? 10 : 12,
                                                                      color: Colors.orange.shade800,
                                                                    ),
                                                                  ),
                                                                ))
                                                            .toList(),
                                                      ),
                                                      SizedBox(height: 8),
                                                    ],
                                                  ],
                                                );
                                              } else {
                                                return Text(
                                                  package.toString(),
                                                  style: TextStyle(
                                                    color: Colors.orange.shade700,
                                                    fontSize: isSmallScreen ? 12 : 14,
                                                  ),
                                                );
                                              }
                                            }).toList(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Icon(Icons.access_time, size: isSmallScreen ? 14 : 16, color: Colors.orange.shade700),
                                        SizedBox(width: 4),
                                        Text(
                                          booking['dateTime'],
                                          style: TextStyle(
                                            color: Colors.orange.shade700,
                                            fontSize: isSmallScreen ? 12 : 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.person, size: isSmallScreen ? 14 : 16, color: Colors.orange.shade700),
                                        SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            'Booked by: ${booking['customerName']}',
                                            style: TextStyle(
                                              color: Colors.orange.shade700,
                                              fontSize: isSmallScreen ? 12 : 14,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.attach_money, size: isSmallScreen ? 14 : 16, color: Colors.orange.shade700),
                                        SizedBox(width: 4),
                                        Text(
                                          'Total Price: \$${booking['total'].toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 14 : 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange.shade900,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: booking['status'] == 'Completed'
                                            ? Colors.green.shade100
                                            : Colors.orange.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            booking['status'] == 'Completed'
                                                ? Icons.check_circle
                                                : Icons.pending,
                                            size: isSmallScreen ? 14 : 16,
                                            color: booking['status'] == 'Completed'
                                                ? Colors.green
                                                : Colors.orange,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Status: ${booking['status'] ?? 'Pending'}',
                                        style: TextStyle(
                                              color: booking['status'] == 'Completed'
                                                  ? Colors.green
                                                  : Colors.orange,
                                              fontWeight: FontWeight.bold,
                                              fontSize: isSmallScreen ? 12 : 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Put actions in a separate row for better spacing on narrow screens
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (booking['status'] != 'Completed') ...[
                                      IconButton(
                                        icon: Icon(
                                          Icons.edit,
                                          color: Colors.blue,
                                          size: isSmallScreen ? 20 : 24,
                                        ),
                                        padding: EdgeInsets.all(isSmallScreen ? 4.0 : 8.0),
                                        constraints: BoxConstraints(),
                                        onPressed: () => editBooking(index, booking),
                                      ),
                                      SizedBox(width: isSmallScreen ? 4 : 8),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                          size: isSmallScreen ? 20 : 24,
                                        ),
                                        padding: EdgeInsets.all(isSmallScreen ? 4.0 : 8.0),
                                        constraints: BoxConstraints(),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text('Delete Booking'),
                                              content: Text('Are you sure you want to delete this booking?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    deleteBooking(index);
                                                    Navigator.pop(context);
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text('Booking deleted successfully')),
                                                    );
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.red,
                                                  ),
                                                  child: Text('Delete'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                    SizedBox(width: isSmallScreen ? 4 : 8),
                                    IconButton(
                                      icon: Icon(
                                        booking['status'] == 'Completed'
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        color: booking['status'] == 'Completed'
                                            ? Colors.green
                                            : Colors.orange,
                                        size: isSmallScreen ? 20 : 24,
                                      ),
                                      padding: EdgeInsets.all(isSmallScreen ? 4.0 : 8.0),
                                      constraints: BoxConstraints(),
                                      onPressed: () => toggleStatus(index),
                                    ),
                                  ],
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