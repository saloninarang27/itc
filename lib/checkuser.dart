import 'package:firebase_auth/firebase_auth.dart';
import 'package:itc/Profile.dart';
import 'package:itc/loginpage.dart';
import 'package:itc/main.dart';
import 'package:flutter/material.dart';
class CheckUser extends StatefulWidget {
  const CheckUser({super.key});

  @override
  State<CheckUser> createState() => _CheckUserState();
}
class _CheckUserState extends State<CheckUser> {
  checkuser() {
    final user =   FirebaseAuth.instance.currentUser;
    if(user != null)
    {
      return ProfilePage(gmail: "${user.email}");
    }
    else{
      return LoginPage();
    }
  }
  @override
  Widget build(BuildContext context) {
    return checkuser();
  }
}