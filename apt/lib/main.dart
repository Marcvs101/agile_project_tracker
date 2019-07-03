import 'package:flutter/material.dart';
import 'home_page.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'A.P.T',
      theme: new ThemeData(
          primaryColor: Color.fromRGBO(58, 66, 86, 1), fontFamily: 'Raleway'),
      home: new HomePage(),
    );
  }
}
