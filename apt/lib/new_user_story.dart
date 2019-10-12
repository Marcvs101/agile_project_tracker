import 'package:apt/model/sprint.dart';
import 'package:flutter/material.dart';
import 'model/project.dart';
import 'package:cloud_functions/cloud_functions.dart';

class NewUserStoryPage extends StatefulWidget {
  NewUserStoryPage({Key key, @required this.project, @required this.sprint}) : super(key: key);

  final Project project;
  final bool sprint;

  @override
  _NewUserStoryPageState createState() => _NewUserStoryPageState();
}

class _NewUserStoryPageState extends State<NewUserStoryPage> {
  TextEditingController _nameTextController = new TextEditingController();
  TextEditingController _descrTextController = new TextEditingController();
  int _score = 1;

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
                          if (_formKey.currentState.validate()) {
                            CloudFunctions.instance.call(
                              functionName: "AddUserStory",
                              parameters: {
                                "project": widget.project.id,
                                "name": _nameTextController.text,
                                "description":_descrTextController.text,
                                "score": _score,
                              }).whenComplete(() {
                                widget.sprint ? Sprint.refreshSprintForm(context, widget.project.id) : Project.refreshProject(context, widget.project.id, Project.userstories_page);
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
        title: Text("Add new User Story"),
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
                        controller: _nameTextController,
                        decoration: const InputDecoration(
                            labelText: "Insert the user story's name: "),
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
                            labelText: "Insert the user story's description: "),
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        validator: (value) {
                          if (value.isEmpty) {
                            return 'Please enter some text';
                          }
                          return null;
                        },
                      ),
                      Padding(
                          padding: EdgeInsets.only(top: 20),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Set user story's value"),
                                Row(children: [
                                  Flexible(
                                    flex: 1,
                                    child: Slider(
                                      activeColor: Colors.indigoAccent,
                                      min: 0,
                                      max: 5,
                                      onChanged: (newRating) {
                                        setState(
                                            () => _score = newRating.toInt());
                                      },
                                      value: _score.toDouble(),
                                    ),
                                  ),
                                  Container(
                                    width: 50.0,
                                    alignment: Alignment.center,
                                    child: Text('${_score.toInt()}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .display1),
                                  ),
                                ])
                              ]))
                    ],
                  )
                ],
              ))),
      bottomNavigationBar: makeBottom,
    );
  }
}
