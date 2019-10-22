import 'dart:io';

import 'package:apt/project_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as prefix0;
import 'model/project.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:apt/common/apt_secure_storage.dart' as globals;
import 'package:github/server.dart';

class NewDeveloperPage extends StatefulWidget {
  NewDeveloperPage({Key key, @required this.project, this.devUid})
      : super(key: key);

  final Project project;
  final String devUid;

  @override
  _NewDeveloperPageState createState() => _NewDeveloperPageState();
}

class _NewDeveloperPageState extends State<NewDeveloperPage> {
  TextEditingController _emailTextController = new TextEditingController();
  bool admin = false;
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
                    widget.project.github
                        ? new FlatButton(
                            color: Color.fromRGBO(58, 66, 86, 1.0),
                            padding: EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 7.0),
                            onPressed: () {
                              globals.github.users
                                  .getCurrentUser()
                                  .then((user) {
                                globals.github.repositories
                                    .listContributors(new RepositorySlug(
                                        user.login, widget.project.name))
                                    .toList()
                                    .then((contributors) {
                                  return showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return new SimpleDialog(
                                        title: new Text("Select a user"),
                                        children: <Widget>[
                                          for (var contributor in contributors)
                                            SimpleDialogOption(
                                                child: Text(contributor.login),
                                                onPressed: () {
                                                  CloudFunctions.instance.call(
                                                      functionName:
                                                          "AddDeveloper",
                                                      parameters: {
                                                        "project":
                                                            widget.project.id,
                                                        "developer":
                                                            contributor.login,
                                                        "admins": true,
                                                      }).whenComplete(() {
                                                    Project.refreshProject(
                                                        context,
                                                        widget.project.id,
                                                        Project
                                                            .developers_page);
                                                  }).catchError((error) {
                                                    Navigator.of(context).pop();
                                                    globals.showErrorAlert(
                                                        context);
                                                  });
                                                })
                                        ],
                                      );
                                    },
                                  );
                                });
                              });
                            },
                            child: const Text("Import from Github",
                                style: TextStyle(color: Colors.white)))
                        : new Container(),
                    new FlatButton(
                        color: Color.fromRGBO(58, 66, 86, 1.0),
                        padding: EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 7.0),
                        onPressed: () {
                          if (_formKey.currentState.validate()) {
                            CloudFunctions.instance.call(
                                functionName: "AddDeveloper",
                                parameters: {
                                  "project": widget.project.id,
                                  "developer": _emailTextController.text,
                                  "admins": admin,
                                }).whenComplete(() {
                              Project.refreshProject(context, widget.project.id,
                                  Project.developers_page);
                            }).catchError((error) {
                              globals.showErrorAlert(context);
                            });
                            showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext context) {
                                  return Center(child: CircularProgressIndicator(),);
                                });
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
        title: Text("Add new developer"),
        elevation: 0.1,
      ),
      body: Form(
          key: _formKey,
          child: Padding(
              padding: EdgeInsets.all(20.0),
              child: ListView(
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(padding: EdgeInsets.all(10.0)),
                      Container(
                        child: Padding(
                          padding: const EdgeInsets.all(0.0),
                          child: TextFormField(
                              controller: _emailTextController,
                              decoration: const InputDecoration(
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10.0)),
                                    borderSide: BorderSide(color: Colors.grey),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10.0)),
                                    borderSide: BorderSide(color: Colors.blue),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10.0)),
                                    borderSide: BorderSide(color: Colors.red),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius:
                                    BorderRadius.all(Radius.circular(10.0)),
                                    borderSide: BorderSide(color: Colors.red),
                                  ),
                                  labelText: "Insert new developer's email "),
                              keyboardType: TextInputType.emailAddress,
                              validator: (String value) {
                                Pattern pattern =
                                    r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
                                RegExp regex = new RegExp(pattern);
                                if (!regex.hasMatch(value))
                                  return 'Enter Valid Email';
                                else
                                  return null;
                              }),
                        ),
                      ),
                      Container(padding: EdgeInsets.all(10.0)),
                      Container(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: 4.0, horizontal: 5.0),
                          child: new Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(
                                  "Will this user be an admin for the project?"),
                              Checkbox(
                                value: admin,
                                onChanged: (bool value) {
                                  setState(() {
                                    admin = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  )
                ],
              ))),
      bottomNavigationBar: makeBottom,
    );
  }
}
