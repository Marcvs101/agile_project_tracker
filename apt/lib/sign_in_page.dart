import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:apt/home_page.dart';
import 'dart:async';
import 'package:uni_links/uni_links.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:apt/common/helpers/github_login_request.dart';
import 'package:apt/common/helpers/github_login_response.dart';
import 'package:http/http.dart' as http;



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

    return Scaffold(
        backgroundColor: Colors.grey,
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(58, 66, 86, 1),
        title: Text('Agile Project Tracker'),
      ),
      body: Center(
        child: RaisedButton(
          color: Color.fromRGBO(58, 66, 86, 1),
          onPressed: onClickGitHubLoginButton,
          textColor: Colors.white,
          child: Text("Sign in with Github"),
        ),
      )
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
  // ...
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

    final AuthCredential credential = GithubAuthProvider.getCredential(
      token: loginResponse.accessToken,
    );

    final FirebaseUser user = await widget.auth.signInWithCredential(credential);

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage(user: user,)));
  }
}
