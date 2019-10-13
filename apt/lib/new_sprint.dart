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
                        builder: (context) => NewUserStoryPage(project: widget.project, sprint: true,)));
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
                            _ustories.isNotEmpty ?
                            CloudFunctions.instance.call(
                              functionName: "AddSprint",
                              parameters: {
                                "project": widget.project.id,
                                "name": _nameTextController.text,
                                "description":_descrTextController.text,
                                "schedule": date.day.toString()+"-"+date.month.toString()+"-"+date.year.toString(),
                                "userstories": _ustories,
                              }).whenComplete(() {
                              Project.refreshProject(context, widget.project.id, Project.progress_page);
                            }) : noUserStorySelectedAlert();

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
                          hintText: "Insert new sprint's name: ",
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10.0)),
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10.0)),
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
                      Container(padding: EdgeInsets.all(10.0)),
                      Container(
                        child: Padding(
                          padding: const EdgeInsets.all(0.0),
                          child: TextFormField(
                            minLines: 1,
                            maxLines: 3,
                            autocorrect: false,
                            keyboardType: TextInputType.multiline,
                            controller: _descrTextController,
                            decoration: InputDecoration(
                              hintText: "Insert new sprint's description",
                              filled: false,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(10.0)),
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(10.0)),
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
                      Container(padding: EdgeInsets.all(10.0)),
                      Container(
                        child: Wrap(runSpacing: 20, children: [
                          DateTimePickerFormField(
                            inputType: InputType.date,
                            format: DateFormat("dd-MM-yyyy"),
                            initialDate: DateTime.now(), //DateTime(2019, 1, 1),
                            editable: false,
                            decoration: InputDecoration(
                              prefixText: "Scheduled for: ",
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(10.0)),
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(10.0)),
                                  borderSide: BorderSide(color: Colors.blue),
                                ),
                                labelText: 'Scheduled for: ',
                                hasFloatingPlaceholder: false),
                            onChanged: (dt) {
                              setState(() => date = dt);
                            },
                          ),
                          Center(child:
                          Text("Select user stories",
                            style: TextStyle(
                                color: Color.fromRGBO(58, 66, 86, 0.9),
                                fontSize: 16.0,
                              ),
                            ),
                          )
                        ]),
                      ),
                    ],
                  ),
                  _retrieveUs,
                ],
              ))),
      bottomNavigationBar: makeBottom,
    );
  }
}
