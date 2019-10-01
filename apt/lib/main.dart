import 'dart:async';

import 'package:apt/github_sign_in.dart';
import 'package:apt/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:splashscreen/splashscreen.dart';



void main(){
  final FirebaseAuth auth = FirebaseAuth.instance;
  runApp(new MaterialApp(
    home: new MyApp(auth: auth,),
  ));
}


class MyApp extends StatefulWidget {
  MyApp({Key key, @required this.auth});

  final FirebaseAuth auth;

  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  bool isLogged = false;
  FirebaseUser loggedUser;
  @override
  Widget build(BuildContext context) {
    return new SplashScreen(
        seconds: 5,
        navigateAfterSeconds: (isLogged ? new HomePage(user: loggedUser) : new GithubSignInPage(auth: widget.auth)),
        title: new Text('Agile Project Tracker',
          style: new TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20.0,
              color: Colors.white
          ),),
        backgroundColor: Colors.black,
        styleTextUnderTheLoader: new TextStyle(),
        photoSize: 100.0,
        loaderColor: Colors.white
    );
  }

  @override
  void initState(){
    getUser().then((user) {
      if (user != null) {
        // send the user to the home page
        // homePage();
        loggedUser = user;
        isLogged = true;
      }
    });
    super.initState();
  }

  Future<FirebaseUser> getUser() async {
    return await widget.auth.currentUser();
  }

}