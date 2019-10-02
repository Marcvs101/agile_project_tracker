import 'package:firebase_auth/firebase_auth.dart';

class AuthHelper {

  String retrieveToken(FirebaseUser user) {
    String idToken = "";
    user.getIdToken().then((token) {
      idToken = token;
    }).catchError((e) {
      print("ERROR: Cannot retrieve token - " + e.toString());
    });
    return idToken;
  }

}