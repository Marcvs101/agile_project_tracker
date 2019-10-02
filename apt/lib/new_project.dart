import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NewProjectPage extends StatefulWidget {
  NewProjectPage({Key key, @required this.user}) : super(key: key);

  final FirebaseUser user;

  @override
  _NewProjectPageState createState() => _NewProjectPageState();
}

class _NewProjectPageState extends State<NewProjectPage> {
  TextEditingController _nameTextController = new TextEditingController();
  TextEditingController _descrTextController = new TextEditingController();
  bool admin = false;
  bool developer = false;

  @override
  Widget build(BuildContext context) {
    
    final makeBottom = Container(
        width: MediaQuery.of(context).size.width,
        height: 65.0,
        child: BottomAppBar(
            child: Center(
          child: Column(children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                new FlatButton(
                    padding: EdgeInsets.symmetric(vertical: 8.0,horizontal: 7.0),
                    color: Color.fromRGBO(58, 66, 86, 1.0),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("Cancel", style: TextStyle(color: Colors.white))),
                new FlatButton(
                    color: Color.fromRGBO(58, 66, 86, 1.0),
                    padding: EdgeInsets.symmetric(vertical: 8.0,horizontal: 7.0),
                    onPressed: () {
                      CloudFunctions.instance
                          .call(functionName: "CreateNewProject", parameters: {
                        "nome": _nameTextController.text,
                        "descrizione": _descrTextController.text,
                        "proprietario": widget.user.uid,
                        "user_story": [],
                        "completato": false,
                        "sviluppatori": developer ? [widget.user.uid] : [],
                        "amministratori": admin ? [widget.user.uid] : [],
                      });
                      Navigator.of(context).pop();
                    },
                    child: const Text("Confirm", style: TextStyle(color: Colors.white)))
              
              ],
            )
          ]),
        )));

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Color.fromRGBO(58, 66, 86, 1),
          title: Text("New Project"),
          elevation: 0.1,
        ),
        body: Padding(
          padding: EdgeInsets.all(20.0),
          child: ListView(
            children: <Widget>[
              Column(
                children: <Widget>[
                  new TextField(
                    controller: _nameTextController,
                    decoration: const InputDecoration(labelText: "Name: "),
                  ),
                  new TextField(
                    controller: _descrTextController,
                    decoration:
                        const InputDecoration(labelText: "Description: "),
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                  ),
                  new Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                  new Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      Text("Developer"),
                      Checkbox(
                        value: developer,
                        onChanged: (bool value) {
                          setState(() {
                            developer = value;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        bottomNavigationBar: makeBottom
      );
      
  }
}
