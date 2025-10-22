import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddData extends StatefulWidget {
  const AddData({super.key});

  @override
  State<AddData> createState() => _AddDataState();
}

class _AddDataState extends State<AddData> {
  TextEditingController titleController=TextEditingController();
  TextEditingController descController=TextEditingController();
  addData(String title,String desc)async{
    if(title=="" && desc==""){
      log("Enter Required Details");
    }
    else{
      FirebaseFirestore.instance.collection("Users").doc(title).set({
        "Title":title,
        "Description":desc
      }).then((value){
        log("Data Inserted");
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Data"),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: TextField(
            controller: titleController,
            decoration: InputDecoration(
              hintText: "Enter Title",
              suffixIcon: Icon(Icons.title),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25)
              )
            ),
          ),
        ),
        SizedBox(height: 30,),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: TextField(
            controller: descController,
            decoration: InputDecoration(
                hintText: "Enter Description",
                suffixIcon: Icon(Icons.description),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25)
                )
            ),
          ),
        ),
        SizedBox(height: 30),
        ElevatedButton(onPressed: (){
          addData(titleController.text.toString(), descController.text.toString());
        }, child: Text("Save Data"))
      ],),
    );
  }
}
