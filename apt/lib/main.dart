import 'package:apt/github_sign_in.dart';
import 'package:apt/splashscreen_page.dart';
import 'package:flutter/material.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Agile Project Tracker',
      theme: new ThemeData(
          primaryColor: Color.fromRGBO(58, 66, 86, 1), fontFamily: 'Raleway'),
      home: SplashScreenPage(),
    );
  }
}
