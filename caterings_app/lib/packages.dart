import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ManagePackagesScreen extends StatefulWidget {
  @override
  ManagePackagesScreenScreen createState() => ManagePackagesScreenScreen();
}

class ManagePackagesScreenScreen extends State<ManagePackagesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
         leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.orange, size: 30),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Manage Packages', style: TextStyle(fontWeight: FontWeight.bold,color: Colors.orange)),
      ),
      body: AdminPanel(),
    );
  }
}

class AdminPanel extends StatefulWidget {
  @override
  _AdminPanelState createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  late Box packageBox;
  TextEditingController packageController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController inclusionController = TextEditingController();
  List<String> inclusions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadPackages();
  }

  Future<void> loadPackages() async {
    packageBox = await Hive.openBox('packages');
    setState(() {
      isLoading = false;
    });
  }

  void addPackage() {
    if (packageController.text.isNotEmpty && priceController.text.isNotEmpty) {
      setState(() {
        packageBox.add({
          'name': packageController.text,
          'price': priceController.text,
          'inclusions': List<String>.from(inclusions)
        });
      });
      packageController.clear();
      priceController.clear();
      inclusions.clear();
    }
  }

  void deletePackage(int index) {
    setState(() {
      packageBox.deleteAt(index);
    });
  }

  void addInclusion() {
    if (inclusionController.text.isNotEmpty) {
      setState(() {
        inclusions.add(inclusionController.text);
      });
      inclusionController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: packageController,
            decoration: InputDecoration(
              labelText: 'Enter Package Name',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 10),
          TextField(
            controller: priceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Enter Package Price',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: inclusionController,
                  decoration: InputDecoration(
                    labelText: 'Enter Inclusion',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: addInclusion,
                child: Icon(Icons.add, color: Colors.white),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              ),
            ],
          ),
          Wrap(
            children: inclusions.map((inclusion) => Chip(
              label: Text(inclusion),
              deleteIcon: Icon(Icons.close),
              onDeleted: () => setState(() => inclusions.remove(inclusion)),
            )).toList(),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade200),
            onPressed: addPackage,
            child: Text('Add Package', style: TextStyle(color: Colors.white)),
          ),
          SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: packageBox.length,
              itemBuilder: (context, index) {
                var package = packageBox.getAt(index);
                return Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    title: Text(
                      '${package['name']} - \$${package['price']}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Inclusions: ${(package['inclusions'] as List).join(', ')}'),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => deletePackage(index),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
