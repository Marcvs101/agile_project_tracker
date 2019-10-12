import 'package:apt/sign_in_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'model/project.dart';
import 'project_page.dart';
import 'new_project.dart';
import 'dart:async';
import 'package:apt/common/apt_secure_storage.dart' as globals;

class HomePage extends StatefulWidget {
  HomePage({
    Key key,
    @required this.user,
    @required this.auth,
  }) : super(key: key);

  final FirebaseUser user;
  final FirebaseAuth auth;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    widget.user.getIdToken().then((token) {
      globals.storage.write(key: "firebaseToken", value: token);
    });
    ListTile makeListTile(Project project) => ListTile(
      contentPadding:
      EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      leading: Container(
        padding: EdgeInsets.only(right: 12.0),
        decoration: new BoxDecoration(
            border: new Border(
                right: new BorderSide(width: 1.0, color: Colors.white24))),
        child: Icon(
          Icons.bookmark_border,
          color: Colors.blue,
          size: 35,
        ),
      ),
      title: Text(
        project.name,
        style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 25),
      ),
      trailing:
      Icon(Icons.keyboard_arrow_right, color: Colors.white, size: 30.0),
      onTap: () {
        
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ProjectPage(project: project, devUid: widget.user.uid, page: Project.description_page,)
            )
        );
      },
    );

    Card makeCard(Project project) => Card(
      elevation: 8.0,
      margin: new EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      child: Container(
        decoration: BoxDecoration(color: Color.fromRGBO(58, 66, 86, 0.9)),
        child: makeListTile(project),
      ),
    );

    void logout() {
      widget.auth.signOut();
      globals.github = null;
      globals.storage.delete(key: "githubToken");
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) => new SignInPage(auth: widget.auth)),
              (route) => false);
    }

    Future<void> logoutAlert() async {
      return showDialog<void>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Logout'),
            content: SingleChildScrollView(
              child: new Text('Are you sure you want to log out?.'),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text('no'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              FlatButton(
                child: Text('yes'),
                onPressed: () {
                  logout();
                },
              ),
            ],
          );
        },
      );
    }

    final topAppBar = AppBar(
      elevation: 0.1,
      backgroundColor: Color.fromRGBO(58, 66, 86, 1),
      title: Text("Your Projects"),
      actions: <Widget>[
        new IconButton(
          icon: new Icon(Icons.exit_to_app),
          onPressed: () {
            logoutAlert();
          },
        ),
      ],
    );

    StreamBuilder<QuerySnapshot> _retrieveProjects() {
      return new StreamBuilder<QuerySnapshot>(
        // Interacts with Firestore (not CloudFunction)
          stream: Firestore.instance
              .collection('projects')
              .where("developers", arrayContains: widget.user.uid)
              .snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (!snapshot.hasData || snapshot.data == null) {
              return Container();
            }
            var content = snapshot.data.documents;
            return new ListView.builder(
                scrollDirection: Axis.vertical,
                shrinkWrap: true,
                itemCount: content.length,
                itemBuilder: (BuildContext context, int index) {
                  var dp = content[index];
                  Project pr = new Project.fromJson(dp);
                  return Dismissible(
                    child: makeCard(pr),
                    key: Key(UniqueKey().toString()),
                    background: Container(color: Colors.red),
                    direction: DismissDirection.endToStart,
                    onDismissed: (DismissDirection direction) {
                      bool removed = false;
                      setState(() {
                        if (widget.user.uid == pr.owner) {
                          removed = true;
                          CloudFunctions.instance.call(
                            functionName: 'DeleteProject',
                            parameters: {
                              'project': pr.id
                            }
                          );
                        }
                      });
                      removed
                          ? Scaffold.of(context).showSnackBar(SnackBar(
                          content: Text("Project " + pr.name + " removed")))
                          : Scaffold.of(context).showSnackBar(SnackBar(
                          content: Text("Project " +
                              pr.name +
                              " cannot be removed")));
                    },
                  );
                });
          });
    }

    return Scaffold(
      appBar: topAppBar,
      backgroundColor: Colors.grey,
      body: _retrieveProjects(),
      floatingActionButton: new FloatingActionButton.extended(
        backgroundColor: Color.fromRGBO(58, 66, 86, 0.9),
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => NewProjectPage(user: widget.user))),
        tooltip: 'Increment',
        label: Text("new project!"),
        icon: new Icon(Icons.add),
      ),
    );
  }
}