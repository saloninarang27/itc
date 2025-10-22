import 'package:firebase_auth/firebase_auth.dart';
import 'package:itc/main.dart';
import 'package:flutter/material.dart';
import 'package:itc/uihelper.dart';
import 'package:itc/profile.dart';
import 'package:itc/forgotpassword.dart';
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  TextEditingController emailController=TextEditingController();
  TextEditingController passwordController=TextEditingController();
  login(String email,String password) async{
    if(email=="" && password=="")
    {
      return UiHelper.CustomAlertBox(context, "Enter Required Field");
    }
    else{
      UserCredential? usercredential;
      try{
        usercredential=await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password).then((value){
          print("Match found");
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>ProfilePage(gmail: email)));
        });
      }
      on FirebaseAuthException catch(ex)
      {
        return UiHelper.CustomAlertBox(context, ex.code.toString());
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      backgroundColor: Colors.orange,
        title: Row(
          children: [
            Image.asset(
              'lib/images/logo.jpg',
              height: 40,
            ),
            Expanded(
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  'TrackStar',
                  style: TextStyle(fontSize: 20,
                    color: Colors.indigo
                  ),
                ),
              ),
            ),
          ],
        ),
        leading: SizedBox(),
      ),
      body: Column(
        mainAxisAlignment:MainAxisAlignment.center,
        children: [
          Text("LogIn",style: TextStyle(fontSize: 40,color: Colors.orange,fontWeight: FontWeight.bold),),
          UiHelper.CustomTextField(emailController, "Email", Icons.email, false),
          UiHelper.CustomTextField(passwordController,"Password",Icons.password, true),
          SizedBox(height: 30),
          UiHelper.customButton(() {
            login(emailController.text.toString(), passwordController.text.toString());
          }, "Login"),
          SizedBox(height: 20,),
          TextButton(onPressed: (){
            Navigator.push(context, MaterialPageRoute(builder: (context)=> ForgotPassWord()));
          }, child: Text("Forgot Password"))
        ],),
    );
  }
}
