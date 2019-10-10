import 'package:apt/home_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:apt/common/apt_secure_storage.dart' as globals;
import 'package:github/server.dart';

import 'common/helpers/auth_helper.dart';

class NewProjectPage extends StatefulWidget {
  NewProjectPage({Key key, @required this.user}) : super(key: key);

  final FirebaseUser user;

  @override
  _NewProjectPageState createState() => _NewProjectPageState();
}

class _NewProjectPageState extends State<NewProjectPage> {

  TextEditingController _nameTextController = new TextEditingController();
  TextEditingController _descrTextController = new TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {

    final makeBottom = Container(
        width: MediaQuery.of(context).size.width,
        height: 65.0,
        child: BottomAppBar(
            child: Center(
              child: Column(children: <Widget>[
                Padding(
                    padding: EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        new FlatButton(
                            padding: EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 7.0),
                            color: Color.fromRGBO(58, 66, 86, 1.0),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text("Cancel",
                                style: TextStyle(color: Colors.white))),
                        new FlatButton(
                            color: Color.fromRGBO(58, 66, 86, 1.0),
                            padding: EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 7.0),
                            onPressed: () {
                              globals.github.repositories.listRepositories().toList().then((repos) {
                                  return showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return new SimpleDialog(
                                          title: new Text("Select a repository"),
                                          children: <Widget>[
                                            for(var repo in repos) SimpleDialogOption(
                                              child: Text(repo.name),
                                              onPressed: () {
                                                CloudFunctions.instance.call(
                                                    functionName: "CreateNewProject",
                                                    parameters: {
                                                      "name": repo.name,
                                                      "description": repo.description,
                                                      "owner": widget.user.uid,
                                                      "userStories": [],
                                                      "developers": [widget.user.uid],
                                                      "admins":[widget.user.uid],
                                                      "events":[],
                                                      "sprints":[],
                                                    });
                                                Navigator.of(context).pop();
                                                Navigator.of(context).pop();
                                              },
                                            )
                                          ],
                                        );
                                      },
                                  );
                                });
                              },
                            child: const Text("Import from Github",
                                style: TextStyle(color: Colors.white))),
                        new FlatButton(
                            color: Color.fromRGBO(58, 66, 86, 1.0),
                            padding: EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 7.0),
                            onPressed: () {
                              if (_formKey.currentState.validate()) {
                                CloudFunctions.instance.call(
                                    functionName: "CreateNewProject",
                                    parameters: {
                                      "name": _nameTextController.text,
                                      "description": _descrTextController.text,
                                      "owner": widget.user.uid,
                                      "userStories": [],
                                      "developers": [widget.user.uid],
                                      "admins":[widget.user.uid],
                                      "events":[],
                                      "sprints":[],
                                    });
                                Navigator.of(context).pop();
                              }
                            },
                            child: const Text("Confirm",
                                style: TextStyle(color: Colors.white)))
                      ],
                    )),
              ]),
            )));

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Color.fromRGBO(58, 66, 86, 1),
          title: Text("New Project"),
          elevation: 0.1,
        ),
        bottomNavigationBar: makeBottom,
        body: Form(
            key: _formKey,
            child: Padding(
                padding: EdgeInsets.all(20.0),
                child: ListView(
                  children: <Widget>[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        TextFormField(
                          controller: _nameTextController,
                          decoration: const InputDecoration(
                              labelText: "Insert new project's name: "),
                          validator: (value) {
                            if (value.isEmpty) {
                              return 'Please enter some text';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: _descrTextController,
                          decoration: const InputDecoration(
                              labelText: "Insert new project's description: "),
                          keyboardType: TextInputType.multiline,
                          maxLines: null,
                          validator: (value) {
                            if (value.isEmpty) {
                              return 'Please enter some text';
                            }
                            return null;
                          },
                        ),
                      ],
                    )
                  ],
                ))));
  }
}
