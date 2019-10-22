import 'package:apt/model/event.dart';
import 'package:apt/model/project.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

class EventPage extends StatefulWidget {
  final Event event;
  final Project project;
  final String devUid;

  EventPage({Key key, this.event, this.devUid, this.project}) : super(key: key);

  @override
  _EventPageState createState() => new _EventPageState();
}

class _EventPageState extends State<EventPage> {
  @override
  Widget build(BuildContext context) {
    final type = Container(
      padding: const EdgeInsets.all(10.0),
      decoration: new BoxDecoration(
          border: new Border.all(color: Color.fromRGBO(58, 66, 86, 0.9)),
          borderRadius: BorderRadius.circular(5.0)),
      child: new Text(
        "Type:  " + widget.event.type,
        style:
            TextStyle(color: Color.fromRGBO(58, 66, 86, 0.9), fontSize: 16.0),
        textAlign: TextAlign.left,
      ),
    );

    return Scaffold(
        appBar: new AppBar(
            title: new Text(
              widget.event.name,
              style: TextStyle(color: Colors.white, fontSize: 30.0),
            ),
            backgroundColor: Color.fromRGBO(58, 66, 86, 0.9),
            actions: <Widget>[
              new PopupMenuButton<int>(
                  itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 1,
                          child: Text("Remove this event"),
                        )
                      ],
                  onSelected: (value) {
                    CloudFunctions.instance.call(
                      functionName: "RemoveEvent",
                      parameters: {
                        "event":widget.event.id,
                      }
                    ).whenComplete(() {
                    Project.refreshProject(context, widget.project.id, Project.events_page);
                    });
                    showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return Center(child: CircularProgressIndicator(),);
                        });
                  })
            ]),
        body: Column(children: <Widget>[
          Container(
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.all(20.0),
              child: new SingleChildScrollView(
                  child: new Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                    type,
                    Text(widget.event.date, style: TextStyle(fontSize: 16.0)),
                  ]))),
          Container(
            width: 300.0,
            child: new Divider(color: Color.fromRGBO(58, 66, 86, 0.9)),
          ),
          Container(
              height: 450,
              padding: EdgeInsets.all(20.0),
              width: MediaQuery.of(context).size.width,
              child: SingleChildScrollView(
                  child: Text(
                widget.event.description,
                style: TextStyle(fontSize: 18.0),
              )))
        ]));
  }
}
