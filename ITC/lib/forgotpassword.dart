import 'package:firebase_auth/firebase_auth.dart';
import 'package:itc/uihelper.dart';
import 'package:flutter/material.dart';

class ForgotPassWord extends StatefulWidget {
  const ForgotPassWord({super.key});

  @override
  State<ForgotPassWord> createState() => _ForgotPassWordState();
}

class _ForgotPassWordState extends State<ForgotPassWord> {
  TextEditingController emailController=TextEditingController();

  forgotpassword(String email)async{
    if(email=="null")
    {
      return UiHelper.CustomAlertBox(context, "Enter an Email to reset password");
    }
    else{
      FirebaseAuth.instance.sendPasswordResetEmail(email: email).then((value){
        return UiHelper.CustomAlertBox(context, "password reset link send to email");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Forgot Password"),
        centerTitle: true,
      ),

      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          UiHelper.CustomTextField(emailController, "Email", Icons.email, false),
          SizedBox(height: 20),
          UiHelper.customButton(() {
            forgotpassword(emailController.text.toString());
          }, "Reset Password")
        ],
      ),
    );
  }
}