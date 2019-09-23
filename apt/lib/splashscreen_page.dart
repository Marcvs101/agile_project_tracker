import 'package:apt/github_sign_in.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreenPage extends StatefulWidget {
  @override
  _SplashScreenPageState createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> with SingleTickerProviderStateMixin {
  final int splashDuration = 2;

  @override
  void initState() {
    super.initState();
    countDownTime();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
    );
  }

  Future<void> countDownTime() async {
    return Timer(
        Duration(seconds: splashDuration),
            () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => GithubSignInPage()));
        }
    );
  }

}
