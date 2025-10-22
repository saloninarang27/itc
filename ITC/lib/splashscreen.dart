import 'dart:async';
import 'package:itc/main.dart';
import 'package:itc/loginpage.dart';
import 'package:flutter/material.dart';
import 'package:itc/checkuser.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 2),(){
      Navigator.pushReplacement(context as BuildContext, MaterialPageRoute(builder: (context)=> CheckUser(),));
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          Container(
            child: Text('ITC Haridwar',
              style: TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w900,
              color: Colors.blueAccent.shade700),
           ),
         ),
          Container(
              child: Text('TrackStar',
                style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w500,
                    color: Colors.orange),
              ),
            ),
        ],),
      )
    );
  }
}
