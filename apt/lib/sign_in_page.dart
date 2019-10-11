import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:apt/home_page.dart';
import 'package:github/server.dart';
import 'dart:async';
import 'package:uni_links/uni_links.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:apt/common/helpers/github_login_request.dart';
import 'package:apt/common/helpers/github_login_response.dart';
import 'package:http/http.dart' as http;
import 'package:apt/common/apt_secure_storage.dart' as globals;



class SignInPage extends StatefulWidget {
  SignInPage({Key key, @required this.auth});

  final FirebaseAuth auth;

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  static const String GITHUB_CLIENT_ID = "6693b7c583388aca6c3a";
  static const String GITHUB_CLIENT_SECRET = "96bb2935260ab3ae9ea7507ae0eb071167721477";
  @override
  Widget build(BuildContext context) {
    final logo = Hero(
      tag: 'hero',
      child: CircleAvatar(
        backgroundColor: Colors.transparent,
        radius: 128.0,
        child: Image.asset('assets/images/scrum_black.png'),
      ),
    );

    final title = Center(
        child: Text(
          'Agile Project Tracker',
          style: TextStyle(fontSize: 28.0, color: Colors.black, fontWeight: FontWeight.bold),
        ),
    );

    final introduction = Center(
      child: Text(
        'Everything a SCRUM team needs',
        style: TextStyle(fontSize: 16.0, color: Colors.black),
      ),
    );

    final loginButton = Padding(
      padding: EdgeInsets.symmetric(vertical: 24.0),
      child: RaisedButton(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        onPressed: onClickGitHubLoginButton,
        padding: EdgeInsets.all(24),
        color: Color.fromRGBO(58, 66, 86, 1),
        child: Text('Sign in with Github', style: TextStyle(color: Colors.white), textScaleFactor: 1.5,),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: EdgeInsets.only(left: 24.0, right: 24.0),
          children: <Widget>[
            logo,
            title,
            SizedBox(height: 10),
            introduction,
            SizedBox(height: 200.0),
            loginButton,
          ],
        ),
      ),
    );
  }



  void onClickGitHubLoginButton() async {

    const String url = "https://github.com/login/oauth/authorize" +
        "?client_id=" +
        GITHUB_CLIENT_ID +
        "&scope=public_repo%20read:user%20user:email";

    if (await canLaunch(url)) {

      await launch(
        url,
        forceSafariVC:
        false,
        forceWebView:
        false,
      );
    }
    else {
      print("CANNOT LAUNCH THIS URL!");
    }

  }

  StreamSubscription _subs;

  @override
  void initState() {
    _initDeepLinkListener();
    super.initState();
  }

  Future<FirebaseUser> getUser() async {
    return await widget.auth.currentUser();
  }

  @override
  void dispose() {
    _disposeDeepLinkListener();

    super.dispose();
  }

  void _initDeepLinkListener() async {
    _subs = getLinksStream().listen((String link) {
      _checkDeepLink(link);
    }, cancelOnError:
    true);
  }

  void _checkDeepLink(String link) {

    if (link != null) {
      String code = link.substring(link.indexOf(RegExp('code=')) + 5);

      loginWithGitHub(code).then((firebaseUser) {
        //print("LOGGED IN AS: " + firebaseUser.displayName);
      }).catchError((e) {
        print("LOGIN ERROR: " + e.toString());
      });
    }
  }

  void _disposeDeepLinkListener() {

    if (_subs != null) {
      _subs.cancel();
      _subs =
      null;
    }
  }

  //Dopo essermi autenticato su github, ottengo il token per completare l'autenticazione sull'app
  Future<void> loginWithGitHub(String code) async {
    //ACCESS TOKEN REQUEST

    final response = await http.post(

      "https://github.com/login/oauth/access_token",
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json"
      },
      body: jsonEncode(GitHubLoginRequest(
        clientId:
        GITHUB_CLIENT_ID,
        clientSecret:
        GITHUB_CLIENT_SECRET,
        code:
        code,
      )),
    );
    GitHubLoginResponse loginResponse =
    GitHubLoginResponse.fromJson(json.decode(response.body));
    //Il processo di login vero e proprio inizia qui, dopo che ho catturato il token parsando il json

    globals.storage.write(key: "githubToken", value: loginResponse.accessToken);
    globals.github = createGitHubClient(auth: new Authentication.withToken(loginResponse.accessToken));

    final AuthCredential credential = GithubAuthProvider.getCredential(token: loginResponse.accessToken,);
    widget.auth.signInWithCredential(credential).then((final FirebaseUser user) {
      globals.github.users.getCurrentUser().then((githubuser) {
        CloudFunctions.instance.call(
            functionName: "UpdateUser",
            parameters: {
              "name": githubuser.login,
            }).then((completed) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage(user: user, auth: widget.auth,)));
        });
      });
    });

  }

}
