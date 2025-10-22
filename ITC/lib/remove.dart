
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Remove extends StatefulWidget {
  const Remove({Key? key, required this.role}) : super(key: key);
  final String role;

  @override
  State<Remove> createState() => _RemoveState();
}

class _RemoveState extends State<Remove> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? currentUserEmail;
  bool isAdmin = false;

  @override

  Future<void> _deleteUser(String email) async {
    try {
      // Delete user from Firestore Users collection
      await FirebaseFirestore.instance.collection('Users').doc(email).delete();

      // Fetch user by email
      List<String> signInMethods = await _auth.fetchSignInMethodsForEmail(email);
      if (signInMethods.isNotEmpty) {
        User? user = _auth.currentUser;
        if (user != null && user.email == email) {
          await user.delete();
        }
      }

      // Show a success message
      print('User deleted successfully');
    } catch (e) {
      // Handle error
      print('Error deleting user: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.role + "s"),
        centerTitle: true,

      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection("Users").snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No employees found.'));
          }

          // Filter the documents where Role is the specified role
          var employeeDocs = snapshot.data!.docs.where((doc) {
            // print(doc['Email']+ " " + doc['Role']);
            return doc['Role'] == widget.role && doc['Email']!="salonisafety@gmail.com";
          }).toList();

          // Map the filtered documents to a list of ListTiles
          return ListView.builder(
            itemCount: employeeDocs.length,
            itemBuilder: (context, index) {
              var userDoc = employeeDocs[index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(
                      userDoc['Email'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text('Role: ${userDoc['Role']}'),
                    trailing:
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.orange),
                      onPressed: () async {
                        await _deleteUser(userDoc['Email']);
                      },
                    )

                ),
              );
            },
          );
        },
      ),
    );
  }
}