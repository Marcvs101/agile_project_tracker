import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:apt/common/apt_secure_storage.dart' as globals;

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
                          globals.github.repositories
                              .listRepositories()
                              .toList()
                              .then((repos) {
                            return showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return new SimpleDialog(
                                  title: new Text("Select a repository"),
                                  children: <Widget>[
                                    for (var repo in repos)
                                      SimpleDialogOption(
                                        child: Text(repo.name),
                                        onPressed: () {
                                          CloudFunctions.instance.call(
                                              functionName: "CreateNewProject",
                                              parameters: {
                                                "name": repo.name,
                                                "description": repo.description,
                                                "owner": widget.user.uid,
                                                "github": true,
                                                "userStories": [],
                                                "developers": [widget.user.uid],
                                                "admins": [widget.user.uid],
                                                "events": [],
                                                "sprints": [],
                                              }).whenComplete(() {Navigator.popUntil(context, (route) => route.isFirst);});
                                          showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return Center(child: CircularProgressIndicator(),);
                                              });
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
                                  "github": false,
                                  "userStories": [],
                                  "developers": [widget.user.uid],
                                  "admins": [widget.user.uid],
                                  "events": [],
                                  "sprints": [],
                                }).whenComplete(() {Navigator.popUntil(context, (route) => route.isFirst);});
                            showDialog(
                                context: context,
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
                            hintText: "Insert new project's name: ",
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
                          ),
                          validator: (value) {
                            if (value.isEmpty) {
                              return 'Please enter some text';
                            }
                            return null;
                          },
                        ),
                        Container(padding: EdgeInsets.all(10.0)),
                        Container(
                          child: Padding(
                            padding: const EdgeInsets.all(0.0),
                            child: TextFormField(
                              minLines: 15,
                              maxLines: 15,
                              autocorrect: false,
                              keyboardType: TextInputType.multiline,
                              controller: _descrTextController,
                              decoration: InputDecoration(
                                hintText: "Insert new project's description",
                                filled: false,
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
                              ),
                              validator: (value) {
                                if (value.isEmpty) {
                                  return 'Please enter some text';
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ))));
  }
}
