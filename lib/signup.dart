import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:itc/Profile.dart';
import 'package:itc/uihelper.dart';
import 'package:flutter/material.dart';
class SignUp2 extends StatefulWidget {
  const SignUp2({super.key});
  @override
  State<SignUp2> createState() => _SignUp2State();
}
class _SignUp2State extends State<SignUp2> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController firstname = TextEditingController();
  TextEditingController lastname = TextEditingController();
  signUp(String firstname,String lastname, String email, String password) async {
    // print("${email} + ${password}" );
    if (email == "" || password == "" || firstname == "" || lastname == "") {
      return UiHelper.CustomAlertBox((context), "Enter Required Field");
    }
    else {
      UserCredential? usercredential;
      try {
        usercredential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email, password: password).then((value) {
          AlertDialog(
            title: Text("Email Password Signed Up"),
            actions: [
              TextButton(onPressed: () {
                Navigator.pop(context);
              }, child: Text("Ok"))
            ],

          );
          uploadData();
        });
      }
      on FirebaseAuthException catch (ex) {
        log(ex.code.toString());
        return AlertDialog(
          title: Text("Email Password SignUp Fail"),
          actions: [
            TextButton(onPressed: () {
              Navigator.pop(context);
            }, child: Text("Ok"))
          ],

        );
      }
    }
  }
  uploadData() async
  {
    FirebaseFirestore.instance.collection("Users").doc(
        emailController.text.toString()).set(
        {
          "First Name" : firstname.text.toString(),
          "Last Name" : lastname.text.toString(),
          "Email": emailController.text.toString(),
          "Role" :"Employee"
        }).then((value) {
      log("user uploaded");
      UiHelper.CustomAlertBox(context, "Done");
       //return Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>ProfilePage()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Employee"),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          UiHelper.CustomTextField(firstname, "First Name", Icons.person, false),
          UiHelper.CustomTextField(lastname, "Last Name", Icons.person, false),
          UiHelper.CustomTextField(
              emailController, "Email", Icons.email, false),
          UiHelper.CustomTextField(
              passwordController, "Password", Icons.password, true),
          SizedBox(height: 20,),
          UiHelper.customButton(() {
            signUp(firstname.text.toString(),lastname.text.toString(),
                emailController.text.toString(),
                passwordController.text.toString());
          }, "Add")
        ],
      ),
    );
  }
}