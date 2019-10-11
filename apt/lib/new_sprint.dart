import 'package:apt/new_user_story.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'model/project.dart';
import 'package:intl/intl.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:cloud_functions/cloud_functions.dart';

class NewSprintPage extends StatefulWidget {
  NewSprintPage({Key key, @required this.project}) : super(key: key);

  final Project project;

  @override
  _NewSprintPageState createState() => _NewSprintPageState();
}

class _NewSprintPageState extends State<NewSprintPage> {
  TextEditingController _nameTextController = new TextEditingController();
  TextEditingController _descrTextController = new TextEditingController();
  DateTime date;
  List _ustories = [];
  bool firstime = true;
  Map<String, bool> values = {};
  Map<String, String> retrieve = {};
  final _formKey = GlobalKey<FormState>();

  Future<void> noUserStorySelectedAlert() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('No User Story selected'),
          content: SingleChildScrollView(
            child: new Text('You must select at least one User Story in order to create a Sprint!'),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Add a User Story now'),
              onPressed: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => NewUserStoryPage(project: widget.project)));
              },
            ),
          ],
        );
      },
    );
  }

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
                            values.forEach(
                              (k,v){
                                if(v) _ustories.add(k);
                              }
                            );
                            values.isNotEmpty ?
                            CloudFunctions.instance.call(
                              functionName: "AddSprint",
                              parameters: {
                                "project": widget.project.id,
                                "name": _nameTextController.text,
                                "description":_descrTextController.text,
                                "schedule": date.day.toString()+"-"+date.month.toString()+"-"+date.year.toString(),
                                "userstories": _ustories,
                              }).then((completed) {
                              Navigator.of(context).pop();
                            }
                            ) : noUserStorySelectedAlert();

                          }
                        },
                        child: const Text("Confirm",
                            style: TextStyle(color: Colors.white)))
                  ],
                )),
          ]),
        )));

    final _retrieveUs = Container(
        padding: EdgeInsets.all(20),
        child: new StreamBuilder<QuerySnapshot>(
            stream: Firestore.instance
                .collection('userStories')
                .where('project', isEqualTo: widget.project.id)
                .where('sprint', isEqualTo: "")
                .snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (!snapshot.hasData || snapshot.data == null) {
                return Container();
              }
              var content = snapshot.data.documents;

              if(firstime){
                content.forEach((f) {
                  values[f.documentID] = false;
                  retrieve[f.documentID] = f.data['name'];
                });
                firstime = false;
              }

              return Container(
                height: 250,
                child: SingleChildScrollView(
                  child: ListView(
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    children: values.keys.map((String key) {
                        return new CheckboxListTile(
                          title: new Text(retrieve[key]),
                          value: values[key],
                          onChanged: (bool value) {
                            setState(() {
                              values[key] = value;
                            }); 
                          },
                        );
                    }).toList())
                ),
              ) ;
            })
        );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(58, 66, 86, 1),
        title: Text("Add new sprint"),
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
                          labelText: "Insert new sprint's name: "),
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
                          labelText: "Insert new sprint's description: "),
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Please enter some text';
                        }
                        return null;
                      },
                    ),
                    Wrap(runSpacing: 20, children: [
                      DateTimePickerFormField(
                        inputType: InputType.date,
                        format: DateFormat("dd-MM-yyyy"),
                        initialDate: DateTime.now(), //DateTime(2019, 1, 1),
                        editable: false,
                        decoration: InputDecoration(
                            labelText: 'Schedule',
                            hasFloatingPlaceholder: false),
                        onChanged: (dt) {
                          setState(() => date = dt);
                        },
                      ),
                      Text(
                        "Select user stories:",
                        style: TextStyle(
                            color: Color.fromRGBO(58, 66, 86, 0.9),
                            fontSize: 16.0),
                      )
                    ]),
                    _retrieveUs,
                  ],
                )
              ]))),
      bottomNavigationBar: makeBottom,
    );
  }
}
