import 'package:commut4/loginsignup.dart';
import 'package:commut4/ridesinfo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Authwrapper extends StatelessWidget {
  const Authwrapper({super.key});

  

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(stream: FirebaseAuth.instance.authStateChanges(), builder: (context, snapshot){
      if (snapshot.connectionState == ConnectionState.waiting){
        return const  CircularProgressIndicator();
      }

      if(snapshot.hasData){
          return RidesPage();
      }
      
      return WelcomePage();
    });
  }
}