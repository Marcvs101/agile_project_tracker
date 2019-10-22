import 'dart:async';
import 'package:apt/common/helpers/auth_helper.dart';
import 'package:apt/sign_in_page.dart';
import 'package:apt/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:github/server.dart';
import 'package:apt/common/apt_secure_storage.dart' as globals;

void main(){
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).whenComplete(() {
    runApp(new MaterialApp(
      debugShowCheckedModeBanner: false,
      home: new MyApp(),
    ));
  });

}

class MyApp extends StatefulWidget {
  final FirebaseAuth auth = FirebaseAuth.instance;

  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    getUser().then((user) {
      if (user != null) {
        // sono sicuro che esiste un token, perchè un utente non nullo implica un token non nullo
        globals.storage.read(key: "githubToken").then((token) {
          AuthHelper.githubToken = token;
          globals.github = createGitHubClient(auth: new Authentication.withToken(AuthHelper.githubToken));
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage(user: user, auth: widget.auth,)));
        });
      }
    });
    return new SignInPage(auth: widget.auth);
  }

  @override
  void initState(){
    super.initState();
  }

  Future<FirebaseUser> getUser() async {
    return await widget.auth.currentUser();
  }

}