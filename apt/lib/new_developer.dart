import 'package:flutter/material.dart';
import 'model/project.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:apt/common/apt_secure_storage.dart' as globals;
import 'package:github/server.dart';

import 'common/helpers/auth_helper.dart';


class NewDeveloperPage extends StatefulWidget {
  NewDeveloperPage({Key key, @required this.project}) : super(key: key);

  final Project project;

  @override
  _NewDeveloperPageState createState() => _NewDeveloperPageState();

}

class _NewDeveloperPageState extends State<NewDeveloperPage>{

  TextEditingController _emailTextController = new TextEditingController(); 
  bool admin = false;
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context){

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
                          globals.github.users.getCurrentUser().then((user) {
                            globals.github.repositories.listContributors(new RepositorySlug(user.login, widget.project.name)).toList().then((contributors) {
                              return showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return new SimpleDialog(
                                    title: new Text("Select a user"),
                                    children: <Widget>[
                                      for(var contributor in contributors) SimpleDialogOption(
                                        child: Text(contributor.login),
                                        onPressed: null,
                                      )
                                    ],
                                  );
                                },
                              );
                            });
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
                            //CloudFunctions.instance.call(
                            //  functionName: "AddDeveloper",
                            //  parameters: {
                            //    "project": widget.project.id,
                            //    "developer": _emailTextController.text,
                            //    "admins":admin,
                            //  });
                            print("Added "+_emailTextController.text+" to project: "+widget.project.id+" with priviledge? "+admin.toString());
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
                        TextFormField(
                          controller: _emailTextController,
                          decoration: const InputDecoration(
                              labelText: "Insert new developer's email: "),
                          keyboardType: TextInputType.emailAddress,
                          validator: (String value) {
                            Pattern pattern = r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
                            RegExp regex = new RegExp(pattern);
                            if (!regex.hasMatch(value))
                              return 'Enter Valid Email';
                            else
                              return null;
                          }
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: 4.0, horizontal: 50.0),
                          child: new Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text("Admin"),
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
                      ],
                    )
            ],
          )
        )
      ),
      bottomNavigationBar: makeBottom,
    );
  }

}