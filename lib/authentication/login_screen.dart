import 'package:drivers_app/SplashScreen/splash_screen.dart';
import 'package:drivers_app/global/global.dart';
import 'package:drivers_app/widgets/progress_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class LoginScreen extends StatefulWidget {



  @override
  _LoginScreenState createState() => _LoginScreenState();
}



class _LoginScreenState extends State<LoginScreen> {

  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();

  validateForm(){
    if(!emailTextEditingController.text.contains("@")){
      Fluttertoast.showToast(msg: "Email Address is not correct");
    }
    else if (passwordTextEditingController.text.isEmpty){
      Fluttertoast.showToast(msg: "Password field is empty");
    }
    else{
        loginDriverNow();
    }
  }

  loginDriverNow() async {
    showDialog(context: context,
        barrierDismissible: false,
        builder: (BuildContext c){
          return ProgressDialog(message: "Processing, Please wait....",);
        });

    final User? firebaseUser = (
        await firebaseAuth.signInWithEmailAndPassword(
          email: emailTextEditingController.text.trim(),
          password: passwordTextEditingController.text.trim(),
        ).catchError((msg){
          Navigator.pop(context);
          Fluttertoast.showToast(msg: "Error: " + msg.toString());
        })
    ).user;

    if(firebaseUser!= null){

      DatabaseReference driversRef = FirebaseDatabase.instance.ref().child("drivers");
      driversRef.child(firebaseUser.uid).once().then((driverKey){
        final snap = driverKey.snapshot;
        if(snap.value != null){
          currentFirebaseUser = firebaseUser;
          Fluttertoast.showToast(msg: "Login successfully ");
          Navigator.push(context, MaterialPageRoute(builder: (e)=> const MySplashScreen()));
        }else{
          Fluttertoast.showToast(msg: "No record exist with this email");
          firebaseAuth.signOut();
          Navigator.push(context, MaterialPageRoute(builder: (e)=> const MySplashScreen()));
        }
      });
    }else{
      Navigator.pop(context);
      Fluttertoast.showToast(msg: "Error occurred during Login");
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(20.0),
                child: Image.asset("images/logo1.jpg"),
              ),

              SizedBox(height: 10,),

              const Text("Login as a Driver",
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10,),

              SignUpTextField(nameTextEditingController: emailTextEditingController, labelText: 'E_mail', hintText: 'E_mail',inputType: TextInputType.text,),
              SignUpTextField(nameTextEditingController: passwordTextEditingController, labelText: 'Password', hintText: 'Password',inputType: TextInputType.text,obscure: true,),

              SizedBox(height: 10,),

              ElevatedButton(onPressed: (){
                validateForm();
                Navigator.push(context, MaterialPageRoute(builder: (c)=> const MySplashScreen() ));
              },
                child: const Text("Login",
                  style: TextStyle(color: Colors.black,fontSize: 18),
                ),
              ),

              SizedBox(height: 10,),
            ],
          ),
        ),
      ),
    );
  }
}
class SignUpTextField extends StatelessWidget {
  SignUpTextField({
    Key? key,
    required this.nameTextEditingController, required this.labelText, required this.hintText, required this.inputType, this.obscure=false, this.fareAmount,
  }) : super(key: key);

  final TextEditingController nameTextEditingController;
  int? fareAmount;
  final String labelText;
  final String hintText;
  final TextInputType inputType;
  final bool? obscure;

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: obscure!,
      controller: nameTextEditingController,
      keyboardType: inputType,
      style: const TextStyle(
        color: Colors.grey,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
        ),
        hintStyle: const TextStyle(
          color: Colors.grey,
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          color: Colors.grey,
          fontSize: 14,
        ),
      ),
    );
  }
}