import 'package:flutter/material.dart';
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

class _NewSprintPageState extends State<NewSprintPage>{

  TextEditingController _nameTextController = new TextEditingController();
  TextEditingController _descrTextController = new TextEditingController(); 
  DateTime date;

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
                          if (_formKey.currentState.validate()) {
                            //CloudFunctions.instance.call(
                            //  functionName: "AddSprint",
                            //  parameters: {
                            //    "project": widget.project.id,
                            //    "name": _nameTextController.text,
                            //    "description":_descrTextController,
                            //    "date": date,
                            //  });
                            print("Added "+_nameTextController.text+" to project: "+widget.project.id+" with description "+_nameTextController.text+" expiration on"+ date.toString());
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
                        DateTimePickerFormField(
                          inputType: InputType.date,
                          format: DateFormat("MM-dd-yyyy"),
                          initialDate: DateTime(2019, 1, 1),
                          editable: false,
                          decoration: InputDecoration(
                              labelText: 'Date',
                              hasFloatingPlaceholder: false
                          ),
                          onChanged: (dt) {
                            setState(() => date = dt);
                          },
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