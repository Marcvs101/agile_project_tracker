import 'package:firebase_auth/firebase_auth.dart';
import 'package:apt/common/apt_secure_storage.dart' as globals;

class AuthHelper {

  static String githubToken;

  static String retrieveToken(FirebaseUser user) {
    String idToken = "";
    user.getIdToken().then((token) {
      idToken = token;
    }).catchError((e) {
      print("ERROR: Cannot retrieve token - " + e.toString());
    });
    return idToken;
  }

}