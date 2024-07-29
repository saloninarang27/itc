import 'package:itc/uihelper.dart';
import 'package:flutter/material.dart';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class Suggesstion extends StatefulWidget {
  const Suggesstion({Key? key, required this.name}) : super(key: key);
  final String name;

  @override
  State<Suggesstion> createState() => _SuggesstionState();
}

class _SuggesstionState extends State<Suggesstion> {
  TextEditingController suggest = TextEditingController();

  void uploadData() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      log("No user is currently signed in.");
      UiHelper.CustomAlertBox(context, "No user is currently signed in.");
      return;
    }
    final DateTime now = DateTime.now();
    final String formattedDate = DateFormat('yyyy-MM-dd').format(now);
    final String formattedTime = DateFormat('HH:mm:ss').format(now);
    FirebaseFirestore.instance.collection("Suggestion").add({
      "Suggestion": suggest.text.toString(),
      "Date": formattedDate,
      "Time": formattedTime,
      "Email": currentUser.email,
      "fullName": widget.name,
    }).then((value) {
      log("Suggestion Added");
      UiHelper.CustomAlertBox(context, "Done");
      suggest.clear();
    }).catchError((error) {
      log("Failed to add suggestion: $error");
    });
  }

  Widget buildMessageItem(Map<String, dynamic> data, bool isCurrentUser) {
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isCurrentUser ? Colors.blueAccent : Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              data['fullName'],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isCurrentUser ? Colors.white : Colors.black,
              ),
            ),
            SizedBox(height: 5),
            Text(
              data['Suggestion'],
              style: TextStyle(color: isCurrentUser ? Colors.white : Colors.black),
            ),
            SizedBox(height: 5),
            Text(
              "${data['Date']} ${data['Time']}",
              style: TextStyle(
                fontSize: 10,
                color: isCurrentUser ? Colors.white70 : Colors.black54,
              ),
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
        title: Text("Query Box"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection("Suggestion").snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No suggestions yet."));
                }

                List<Map<String, dynamic>> sortedData = snapshot.data!.docs
                    .map((doc) => doc.data() as Map<String, dynamic>)
                    .toList();

                // Sort the data in ascending order
                sortedData.sort((a, b) {
                  DateTime dateA = DateTime.parse("${a['Date']} ${a['Time']}");
                  DateTime dateB = DateTime.parse("${b['Date']} ${b['Time']}");
                  return dateA.compareTo(dateB); // Sort in ascending order
                });

                final currentUserEmail = FirebaseAuth.instance.currentUser?.email;
                return ListView.builder(
                  reverse: false, // Ensure the messages are displayed from top to bottom
                  itemCount: sortedData.length,
                  itemBuilder: (context, index) {
                    var data = sortedData[index];
                    bool isCurrentUser = data['Email'] == currentUserEmail;
                    return buildMessageItem(data, isCurrentUser);
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: suggest,
                    decoration: InputDecoration(
                      hintText: "Enter your suggestion",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    if (suggest.text.isNotEmpty) {
                      uploadData();
                    } else {
                      UiHelper.CustomAlertBox(context, "Enter a suggestion");
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}