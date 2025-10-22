import 'dart:io' show File, HttpClient;
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
import 'package:flutter/foundation.dart' show consolidateHttpClientResponseBytes, kIsWeb;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.gmail});
  final String gmail;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

String _searchQuery = "";
TextEditingController _searchController = TextEditingController();

class _ProfilePageState extends State<ProfilePage> {
  bool _canUploadFile = true;
  String? fname;
  bool _isUploading = false; // 🔹 New variable for upload loader

  // Local pagination
  final int _limit = 20;
  List<Map<String, dynamic>> _allRows = [];
  List<Map<String, dynamic>> _visibleRows = [];
  int _currentPage = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _loadExcelData(); // fetch Excel from Storage
  }

  // 🔹 Show details
  void _showItemDetails(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(data['Material Description'] ?? 'No Description'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailTile('Material No', data['Material No']),
              _detailTile('Material Description', data['Material Description']),
              _detailTile('Location', data['Location']),
              _detailTile('Qty', data['Qty']),
              _detailTile('Line Name', data['Line Name']),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailTile(String title, String? value) {
    return ListTile(
      title: Text(title),
      subtitle: Text(value ?? 'N/A'),
    );
  }

  // 🔹 Check role
  Future<void> _checkUserRole() async {
    try {
      var userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.gmail)
          .get();

      if (userDoc.exists) {
        setState(() {
          fname =
          "${userDoc.data()?['First Name']} ${userDoc.data()?['Last Name']}";
          if (userDoc.data()?['Role'] == 'Employee') {
            _canUploadFile = false;
          }
        });
      } else {
        await FirebaseAuth.instance.signOut();
        UiHelper.CustomAlertBox(context, "You are not a user now!!");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      }
    } catch (e) {
      print("Error checking user role: $e");
    }
  }

  // 🔹 Request permission
  Future<void> _requestPermission() async {
    if (!kIsWeb) {
      var status = await Permission.storage.status;
      if (status.isDenied) await Permission.storage.request();
      if (status.isPermanentlyDenied) openAppSettings();
    }
  }

  // 🔹 Upload Excel file to Firebase Storage
  Future<void> _uploadFile() async {
    await _requestPermission();

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result == null || result.files.first.path == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No file selected')));
      return;
    }

    File file = File(result.files.first.path!);

    try {
      // 🔹 Show upload loader
      setState(() {
        _isUploading = true;
      });

      // Upload task with progress monitoring
      final uploadTask = FirebaseStorage.instance
          .ref('excel_files/trackstar_data.xlsx')
          .putFile(file);

      // Optional: Listen to upload progress
      uploadTask.snapshotEvents.listen((taskSnapshot) {
        final progress = (taskSnapshot.bytesTransferred / taskSnapshot.totalBytes) * 100;
        print('Upload progress: ${progress.toStringAsFixed(2)}%');
      });

      // Wait for upload to complete
      await uploadTask;

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Excel uploaded successfully!')));

      // Reload data after upload
      await _loadExcelData();

    } catch (e) {
      print('Upload error: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Upload error: $e')));
    } finally {
      // 🔹 Hide upload loader
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _loadExcelData() async {
    setState(() {
      _isLoading = true;
      _allRows.clear();
      _visibleRows.clear();
      _currentPage = 0;
    });

    try {
      // Get download URL instead of using getData()
      String downloadURL = await FirebaseStorage.instance
          .ref('excel_files/trackstar_data.xlsx')
          .getDownloadURL();

      // For web, use http package to fetch the file
      if (kIsWeb) {
        final response = await HttpClient().getUrl(Uri.parse(downloadURL));
        final httpRequest = await response.close();
        final data = await consolidateHttpClientResponseBytes(httpRequest);
        _processExcelData(data);
      } else {
        // For mobile, use the existing approach
        Uint8List? data = await FirebaseStorage.instance
            .ref('excel_files/trackstar_data.xlsx')
            .getData();
        if (data != null) {
          _processExcelData(data);
        }
      }
    } catch (e) {
      print('Error loading Excel: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload Excel Data')),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Helper method to process Excel data
  void _processExcelData(Uint8List data) {
    var excel = Excel.decodeBytes(data);
    _allRows.clear();

    for (var table in excel.tables.keys) {
      var sheet = excel.tables[table];
      if (sheet == null || sheet.rows.isEmpty) continue;

      List<String> headers =
      sheet.rows.first.map((cell) => cell?.value.toString() ?? '').toList();

      for (var row in sheet.rows.skip(1)) {
        Map<String, dynamic> rowData = {};
        for (var i = 0; i < headers.length && i < row.length; i++) {
          rowData[headers[i]] = row[i]?.value?.toString() ?? '';
        }
        _allRows.add(rowData);
      }
    }

    _applyPagination();
  }

  // 🔹 Apply pagination
  void _applyPagination() {
    final start = _currentPage * _limit;
    final end = start + _limit;
    final newPage = _allRows.sublist(
        start, end > _allRows.length ? _allRows.length : end);

    setState(() {
      if (_currentPage == 0) {
        _visibleRows = newPage;
      } else {
        _visibleRows.addAll(newPage);
      }
    });
  }

  // 🔹 Load next page
  void _loadNextPage() {
    if ((_currentPage + 1) * _limit >= _allRows.length) return;
    _currentPage++;
    _applyPagination();
  }

  // 🔹 Filtered rows based on search
  List<Map<String, dynamic>> get _filteredRows {
    if (_searchQuery.isEmpty) return _visibleRows;

    return _allRows.where((data) {
      final materialNo =
      (data['Material No'] ?? '').toString().toLowerCase();
      final description =
      (data['Material Description'] ?? '').toString().toLowerCase();
      return materialNo.contains(_searchQuery) ||
          description.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text("TrackStar"),
        centerTitle: true,
      ),
      drawer: Drawer(
        width: 240,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              child: Column(
                children: const [
                  CircleAvatar(
                    backgroundImage: AssetImage('lib/images/logo.jpg'),
                    radius: 50.0,
                  ),
                ],
              ),
            ),
            if (_canUploadFile)
              ListTile(
                leading: const Icon(Icons.add_box_outlined),
                title: const Text('Add Admins'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddAdmin()),
                ),
              ),
            if (_canUploadFile)
              ListTile(
                leading: const Icon(Icons.remove),
                title: const Text('Remove Admins'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Remove(role: "Admin")),
                ),
              ),
            if (_canUploadFile)
              ListTile(
                leading: const Icon(Icons.add_box),
                title: const Text('Add Employee'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignUp2()),
                ),
              ),
            if (_canUploadFile)
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Remove Employee'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Remove(role: "Employee")),
                ),
              ),
            ListTile(
              leading: const Icon(Icons.label_important_outline),
              title: const Text('Suggestions'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        Suggesstion(name: fname?.toString() ?? 'User')),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.change_circle_outlined),
              title: const Text('Change Password'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChangePassword()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout_outlined),
              title: const Text('Logout'),
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
      // 🔹 Floating Action Button for upload
      floatingActionButton: _canUploadFile
          ? FloatingActionButton(
        onPressed: _isUploading ? null : _uploadFile,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        tooltip: 'Upload Excel File',
        child: _isUploading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            strokeWidth: 2,
          ),
        )
            : const Icon(Icons.upload_file),
      )
          : null,
      body: Stack( // 🔹 Use Stack to show loader overlay
        children: [
          Column(
            children: [
              // 🔹 Removed the old upload button from here
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search by Material No or Description',
                    prefixIcon: const Icon(Icons.search),
                    border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _filteredRows.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _filteredRows.length) {
                      // Load more button
                      if ((_currentPage + 1) * _limit >= _allRows.length) {
                        return const SizedBox(); // no more
                      }
                      return TextButton(
                        onPressed: _loadNextPage,
                        child: const Text('Load More'),
                      );
                    }
                    final data = _filteredRows[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        title:
                        Text(data['Material Description'] ?? 'No Name'),
                        subtitle:
                        Text('Material No: ${data['Material No'] ?? 'N/A'}'),
                        onTap: () => _showItemDetails(data),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // 🔹 Upload loader overlay
          if (_isUploading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Uploading Excel File...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Please wait',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
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