library apt;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:github/server.dart';

final storage = new FlutterSecureStorage();
dynamic github;

Future<void> showErrorAlert(context) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('OOPS!'),
        content: SingleChildScrollView(
          child: new Text('Something were wrong during computation. Please retry later.'),
        ),
      );
    },
  );
}