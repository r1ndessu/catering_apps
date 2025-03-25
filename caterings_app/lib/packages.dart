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
        title: Text('Manage Packages', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
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

      showSuccessDialog('Adding Package', 'Successfully!');
    }
  }

  void editPackage(int index) {
    var package = packageBox.getAt(index);
    packageController.text = package['name'];
    priceController.text = package['price'];
    inclusions = List<String>.from(package['inclusions']);
    TextEditingController editInclusionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Edit Package',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: packageController,
                      decoration: InputDecoration(
                        hintText: 'Enter Package Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Enter Package Price',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: editInclusionController,
                            maxLines: 1,
                            decoration: InputDecoration(
                              hintText: 'Enter Inclusion',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            if (editInclusionController.text.isNotEmpty &&
                                inclusions.length < 4) {
                              setState(() {
                                inclusions.add(editInclusionController.text);
                              });
                              editInclusionController.clear();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            shape: CircleBorder(),
                            padding: EdgeInsets.all(16),
                          ),
                          child: Icon(Icons.add, color: Colors.white),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: inclusions.map((inclusion) {
                        return Chip(
                          label: Text(inclusion),
                          deleteIcon: Icon(Icons.close),
                          onDeleted: () => setState(() => inclusions.remove(inclusion)),
                          backgroundColor: Colors.orange.shade100,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      packageBox.putAt(index, {
                        'name': packageController.text,
                        'price': priceController.text,
                        'inclusions': List<String>.from(inclusions),
                      });
                    });
                    Navigator.of(context).pop();
                    showSuccessDialog('Editing Package', 'Successfully!');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Save',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
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

  void showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 100),
              SizedBox(height: 20),
              Text(
                title,
                style: TextStyle(fontSize: 18, color: Colors.green),
              ),
              SizedBox(height: 3),
              Text(
                message,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'OK',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Adding Package:',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          SizedBox(height: 20),
          TextField(
            controller: packageController,
            decoration: InputDecoration(
              hintText: 'Enter Package Name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          SizedBox(height: 10),
          TextField(
            controller: priceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter Package Price',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: inclusionController,
                  decoration: InputDecoration(
                    hintText: 'Enter Inclusion',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: addInclusion,
                child: Icon(Icons.add, color: Colors.white),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: CircleBorder(),
                  padding: EdgeInsets.all(16),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: inclusions.map((inclusion) {
              return Chip(
                label: Text(inclusion),
                deleteIcon: Icon(Icons.close),
                onDeleted: () => setState(() => inclusions.remove(inclusion)),
                backgroundColor: Colors.orange.shade100,
              );
            }).toList(),
          ),
          SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: addPackage,
              child: Text(
                'Add Package',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
          SizedBox(height: 20),
          Divider(),
          Text(
            'Your Packages:',
            style: TextStyle(
              fontSize: 24,
              color: Colors.orange,
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: packageBox.length,
              itemBuilder: (context, index) {
                var package = packageBox.getAt(index);
                return Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    title: Text(
                      '${package['name']} - \$${package['price']}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    subtitle: Text(
                      'Inclusions: ${(package['inclusions'] as List).join(', ')}',
                      style: TextStyle(color: Colors.black54),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => editPackage(index),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deletePackage(index),
                        ),
                      ],
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