
import 'dart:io' show File;
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:itc/addadmin.dart';
import 'package:itc/changepassword.dart';
import 'package:itc/loginpage.dart';
import 'package:itc/remove.dart';
import 'package:itc/signup.dart';
import 'package:flutter/material.dart';
import 'package:itc/suggesstion.dart';
import 'package:itc/uihelper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key,required this.gmail});
  final String gmail;
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

String _searchQuery = "";
TextEditingController _searchController = TextEditingController();
class _ProfilePageState extends State<ProfilePage> {
  bool _canUploadFile = true;
  String ?fname;
  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  void _showItemDetails(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(data['Material Description'] ?? 'No Name'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                title: Text('Line Name'),
                subtitle: Text(data['Line Name'] ?? '#ERROR!'),
              ),
              ListTile(
                title: Text('Location'),
                subtitle: Text(data['Location'] ?? 'A-R-2'),
              ),
              ListTile(
                title: Text('Material Description'),
                subtitle: Text(data['Material Description'] ?? 'LER-CODING UNIT 2371507901'),
              ),
              ListTile(
                title: Text('Material No'),
                subtitle: Text(data['Material No'] ?? '61009204'),
              ),
              ListTile(
                title: Text('Qty'),
                subtitle: Text(data['Qty'] ?? '#REF!'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkUserRole() async {
    try {
      var userDoc = await FirebaseFirestore.instance.collection('Users').doc(
          widget.gmail).get();
      if (userDoc.exists) {
        // setState(() {
        //   fname=userDoc.data()?['FirstName']+" "+userDoc.data()?['LastName'];
        // });
        setState(() {
          fname=userDoc.data()?['First Name']+" "+userDoc.data()?['Last Name'];
        });
        var role = userDoc.data()?['Role'];
        if (role == 'Employee') {
          print("Employee");
          setState(() {
            _canUploadFile = false;
          });
        } else {
          print("Admin");
        }
      } else {
        await FirebaseAuth.instance.signOut();
        UiHelper.CustomAlertBox(context, "You are not a user now!!");
        // thik h ?
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      }
    } catch (e) {
      print("Error fetching user role: $e");
    }
  }

  Future<void> _requestPermission() async {
    if (!kIsWeb) {
      var status = await Permission.storage.status;
      if (status.isDenied) {
        status = await Permission.storage.request();
      }
      if (status.isPermanentlyDenied) {
        openAppSettings();
      }
    }
  }

  Future<void> _deleteExistingData() async {
    var collection = FirebaseFirestore.instance.collection('excelData');
    var snapshots = await collection.get();
    for (var doc in snapshots.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> _uploadFile() async {
    await _requestPermission();

    // Pick file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result != null && result.files.isNotEmpty) {
      // Delete existing data
      await _deleteExistingData();

      // Get the file
      PlatformFile file = result.files.first;

      // Read the file bytes
      Uint8List? fileBytes;
      if (kIsWeb) {
        fileBytes = file.bytes;
      } else {
        if (file.path != null) {
          File fileFromPath = File(file.path!!);
          fileBytes = await fileFromPath.readAsBytes();
        }
      }

      // Ensure the file has bytes
      if (fileBytes != null) {
        // Read the file
        var excel = Excel.decodeBytes(fileBytes);

        // Iterate over the sheets
        for (var table in excel.tables.keys) {
          var sheet = excel.tables[table];
          List<String> columnNames = sheet!.rows.first.map((cell) =>
          cell?.value.toString() ?? '').toList();

          for (var row in sheet.rows.skip(1)) {
            // Create a map for Firestore
            Map<String, dynamic> data = {};
            for (var i = 0; i < row.length; i++) {
              data[columnNames[i]] = row[i]?.value.toString() ?? '';
            }

            // Upload the data to Firestore
            await FirebaseFirestore.instance.collection('excelData').add(data);
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data uploaded successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File bytes are null')),
        );
      }
    } else {
      // User canceled the picker
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No file selected')),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAllData() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection(
        'excelData').get();
    return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: Text("TrackStar"),
        centerTitle: true,
      ),
      drawer: Drawer(
        width: 240,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              child: Column(
                children: [

                  CircleAvatar(
                    backgroundImage: AssetImage('lib/images/logo.jpg'),
                    radius: 50.0, // Adjust the radius as needed
                  ),
                  //   "${name}", style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.black,),),
                ],
              ),
            ),
            //SizedBox(height: 35,),
            if (_canUploadFile)
              ListTile(
                leading: Icon(Icons.add_box_outlined),
                title: Text('Add Admins'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AddAdmin()),
                  );

                },
              ),
            if (_canUploadFile)
              ListTile(
                leading: Icon(Icons.remove),
                title: Text('Remove Admins'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Remove(role: "Admin")),
                  );
                },
              ),
            if (_canUploadFile)
              ListTile(
                leading: Icon(Icons.add_box),
                title: Text('Add Employee'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SignUp2()),
                  );

                },
              ),
            if (_canUploadFile)
              ListTile(
                leading: Icon(Icons.delete),
                title: Text('Remove Employee'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Remove(role: "Employee")),
                  );
                },
              ),
            ListTile(
              leading: Icon(Icons.label_important_outline),
              title: Text('Suggesstions'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Suggesstion(name: fname.toString())),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.change_circle_outlined),
              title: Text('Change Password'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChangePassword()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout_outlined),
              title: Text('Logout'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: <Widget>[
          if (_canUploadFile)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _uploadFile,
                child: Text('Upload New Excel File'),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchAllData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No data available'));
                }

                final allData = snapshot.data!;
                final filteredData = allData.where((data) {
                  final materialDescription = data['Material Description']?.toLowerCase() ?? '';
                  final materialNo = data['Material No']?.toLowerCase() ?? '';
                  return materialDescription.contains(_searchQuery) || materialNo.contains(_searchQuery);
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: filteredData.length,
                  itemBuilder: (context, index) {
                    var data = filteredData[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        title: Text(data['Material Description'] ?? 'No Name'),
                        //subtitle: Text('Category: ${data['Category'] ?? 'N/A'}'),
                        subtitle: Text('Material No: ${data['Material No'] ?? 'N/A'}'),
                        onTap: () => _showItemDetails(data),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}