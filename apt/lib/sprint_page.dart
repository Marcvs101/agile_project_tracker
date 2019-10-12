import 'package:apt/model/sprint.dart';
import 'package:apt/model/user_story.dart';
import 'package:apt/model/project.dart';
import 'package:apt/userStory_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class SprintPage extends StatefulWidget {
  
  final Project project;
  final Sprint sprint;
  final String devUid;

  SprintPage({Key key, this.devUid, this.project, this.sprint})
      : super(key: key);

  @override
  _SprintPageState createState() => _SprintPageState();
}

class _SprintPageState extends State<SprintPage> {
  @override
  Widget build(BuildContext context) {
    final schedule = Container(
      padding: const EdgeInsets.all(10.0),
      decoration: new BoxDecoration(
          border: new Border.all(color: Color.fromRGBO(58, 66, 86, 0.9)),
          borderRadius: BorderRadius.circular(5.0)),
      child: new Text(
        "Scheduled:  " + widget.sprint.schedule,
        style:
            TextStyle(color: Color.fromRGBO(58, 66, 86, 0.9), fontSize: 16.0),
        textAlign: TextAlign.left,
      ),
    );

    ListTile makeListTileUS(dynamic obj) => ListTile(
          contentPadding:
              EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          leading: Container(
            padding: EdgeInsets.only(right: 12.0),
            decoration: new BoxDecoration(
                border: new Border(
                    right: new BorderSide(width: 1.0, color: Colors.white24))),
            child: Icon(
              obj.completed == "" ? Icons.close : Icons.check,
              color: Colors.white,
            ),
          ),
          title: Text(
            obj.name,
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 25),
          ),
          trailing:
              Icon(Icons.keyboard_arrow_right, color: Colors.white, size: 30.0),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => UserStoryPage(
                        userStory: obj,
                        project: widget.project,
                        devUid: widget.devUid)));
          },
        );

    Card makeCardUS(dynamic obj) => Card(
          elevation: 8.0,
          margin: new EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
          child: Container(
            decoration: BoxDecoration(color: Color.fromRGBO(58, 66, 86, 0.9)),
            child: makeListTileUS(obj),
          ),
        );

    StreamBuilder<QuerySnapshot> _retrieveUS() {
      return new StreamBuilder<QuerySnapshot>(
          // Interacts with Firestore (not CloudFunction)
          stream: Firestore.instance.collection('userStories').snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (!snapshot.hasData || snapshot.data == null) {
              return Container();
            }
            var content = snapshot.data.documents;
            return new ListView.builder(
                scrollDirection: Axis.vertical,
                shrinkWrap: true,
                itemCount: content.length,
                itemBuilder: (BuildContext context, int index) {
                  var dp = content[index];
                  if (widget.sprint.userStories.contains(dp.documentID)) {
                    UserStory us = new UserStory.fromJson(dp);
                    return makeCardUS(us);
                  } else
                    return Container();
                });
          });
    }

    return Scaffold(
        appBar: new AppBar(
            title: new Text(
              widget.sprint.name,
              style: TextStyle(color: Colors.white, fontSize: 30.0),
            ),
            backgroundColor: Color.fromRGBO(58, 66, 86, 0.9),
            actions: <Widget>[
              widget.project.admins.contains(widget.devUid)
                  ? new PopupMenuButton<int>(
                      itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 1,
                              child: Text("Delete this sprint"),
                            )
                          ],
                      onSelected: (value) {
                        CloudFunctions.instance.call(
                          functionName: "RemoveSprint",
                          parameters: {
                            "sprint":widget.sprint.id,
                          }
                        ).whenComplete(() {
                          Project.refreshProject(context, widget.project.id, Project.progress_page);
                        });
                      })
                  : null
            ]),
        body: Column(children: <Widget>[
          Container(
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.all(20.0),
              child: new SingleChildScrollView(
                  child: new Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                    schedule,
                    Text(widget.sprint.status ? "completed" : "not completed",
                        style: TextStyle(fontSize: 16.0)),
                  ]))),
          Container(
            width: MediaQuery.of(context).size.width,
            padding: EdgeInsets.only(left: 30, right: 30, bottom: 20),
            child: Text(
              widget.sprint.description,
              style: TextStyle(fontSize: 14),
            ),
          ),
          Container(
            width: 300.0,
            child: new Divider(color: Color.fromRGBO(58, 66, 86, 0.9)),
          ),
          Container(
            height: 400,
            padding: EdgeInsets.all(20.0),
            width: MediaQuery.of(context).size.width,
            child: _retrieveUS(),
          )
        ]));
  }
}
