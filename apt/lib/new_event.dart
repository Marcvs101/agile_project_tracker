import 'package:flutter/material.dart';
import 'model/project.dart';
import 'package:cloud_functions/cloud_functions.dart';

class NewEventPage extends StatefulWidget {
  NewEventPage({Key key, @required this.project}) : super(key: key);

  final Project project;

  @override
  _NewEventPageState createState() => _NewEventPageState();
}

class _NewEventPageState extends State<NewEventPage> {
  TextEditingController _nameTextController = new TextEditingController();
  TextEditingController _descrTextController = new TextEditingController();
  String type = "";
  DateTime date;

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
                            date = DateTime.now();
                            var d = date.day.toString() +
                                "-" +
                                date.month.toString() +
                                "-" +
                                date.year.toString();
                            CloudFunctions.instance
                                .call(functionName: "AddEvent", parameters: {
                              "project": widget.project.id,
                              "name": _nameTextController.text,
                              "description": _descrTextController.text,
                              "type": type,
                              "date": d
                            }).whenComplete(() {
                              Project.refreshProject(context, widget.project.id,
                                  Project.events_page);
                            });
                          }
                        },
                        child: const Text("Confirm",
                            style: TextStyle(color: Colors.white)))
                  ],
                )),
          ]),
        )));

    String _selected = "Select the event's type";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(58, 66, 86, 1),
        title: Text("Add new event"),
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
                          hintText: "Insert new event's name: ",
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
                        child: new DropdownButton<String>(
                          isExpanded: true,
                          items: <String>[
                            'Planning meeting',
                            'Daily Scrum',
                            'Backlog Grooming',
                            'Scrum of Scrums',
                            'Sprint Review',
                            'Sprint Retrospective'
                          ].map((String value) {
                            return new DropdownMenuItem<String>(
                              value: value,
                              child: new Text(
                                value,
                                style: TextStyle(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            type = val;
                            setState(() {});
                          },
                          hint: type == "" ? Text(_selected) : Text(type),
                        ),
                      ),
                      Container(padding: EdgeInsets.all(10.0)),
                      Container(
                        child: Padding(
                          padding: const EdgeInsets.all(0.0),
                          child: TextFormField(
                            minLines: 10,
                            maxLines: 10,
                            autocorrect: false,
                            keyboardType: TextInputType.multiline,
                            controller: _descrTextController,
                            decoration: InputDecoration(
                              hintText: "Insert new event's description",
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
              ))),
      bottomNavigationBar: makeBottom,
    );
  }
}
