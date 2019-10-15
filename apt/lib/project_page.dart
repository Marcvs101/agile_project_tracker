import 'package:apt/event_page.dart';
import 'package:apt/model/event.dart';
import 'package:apt/model/sprint.dart';
import 'package:apt/model/user_story.dart';
import 'package:apt/sprint_page.dart';
import 'package:apt/userStory_page.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'model/developer.dart';
import 'model/project.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'new_developer.dart';
import 'new_event.dart';
import 'new_sprint.dart';
import 'new_user_story.dart';
import 'dart:async';


class ProjectPage extends StatefulWidget {
  final Project project;
  final String devUid;
  final int page;
  ProjectPage({Key key, this.project, this.devUid, this.page}) : super(key: key);

  @override
  _ProjectPageState createState() => new _ProjectPageState();
}

const List<String> tabNames = const <String>[
  'description',
  'developers',
  'user stories',
  'progress',
  'events'
];

class _ProjectPageState extends State<ProjectPage> {

  int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.page;
  }

  @override
  Widget build(BuildContext context) {
    final getDescription = Container(
        width: MediaQuery.of(context).size.width,
        padding: EdgeInsets.all(20.0),
        child: new SingleChildScrollView(
            child: Text(
          widget.project.description != null ? widget.project.description : "(No description found for this project)",
          style: TextStyle(fontSize: 18.0),
    )));

    Icon getIcons(dynamic obj) {
      Icon i;
      IconData ico;
      if (obj is Developer) {
        if (widget.project.owner == obj.id)
          {ico = Icons.verified_user; i = Icon(ico,color: Colors.blue,);}
        else if (widget.project.admins.contains(obj.id))
          {ico = Icons.supervised_user_circle;i = Icon(ico,color: Colors.blue,);}
        else
          {ico = Icons.account_circle;i = Icon(ico,color: Colors.blue,);}
      } 
      else if (obj is UserStory){
        if(obj.completed == "") {ico = Icons.close;i = Icon(ico,color: Colors.red,);}
        else {ico = Icons.check; i = Icon(ico,color: Colors.green,);}
      }
      else if (obj is Sprint){
        if(obj.status) {ico = Icons.check; i = Icon(ico,color: Colors.green,);}
        else {ico = Icons.close;i = Icon(ico,color: Colors.red,);}
      }
      return i;
    }
  
    ListTile makeListTileUS(dynamic obj) => ListTile(
      contentPadding:
          EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      leading: Container(
        padding: EdgeInsets.only(right: 12.0),
        decoration: new BoxDecoration(
            border: new Border(
                right: new BorderSide(width: 1.0, color: Colors.white24))),
        child: getIcons(obj)
      ),
      title: Text(
        obj.name,
        style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 25),
      ),
      trailing: Icon(Icons.keyboard_arrow_right, color: Colors.white, size: 30.0),
        onTap: () {
        Navigator.push( context, MaterialPageRoute(
          builder: (context) => UserStoryPage(userStory: obj, project: widget.project, devUid: widget.devUid)));
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

    ListTile makeListTileEv(dynamic obj) => ListTile(
      contentPadding:
          EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      leading: Icon(Icons.access_time,color: Colors.white,),
      title: Text(
        obj.name,
        style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 25),
      ),
      subtitle: Text(
        obj.date,
        style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)  
      ),
      trailing: Icon(Icons.keyboard_arrow_right, color: Colors.white, size: 30.0),
        onTap: () {
          Navigator.push( context, MaterialPageRoute(
           builder: (context) => EventPage(event: obj, devUid: widget.devUid, project: widget.project )));
        },
    );

    Card makeCardEv(dynamic obj) => Card(
          elevation: 8.0,
          margin: new EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
          child: Container(
            decoration: BoxDecoration(color: Color.fromRGBO(58, 66, 86, 0.9)),
            child: makeListTileEv(obj),
          ),
    );

    ListTile makeListTileDev(dynamic obj) => ListTile(
      contentPadding:
          EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      leading: Container(
        padding: EdgeInsets.only(right: 12.0),
        decoration: new BoxDecoration(
            border: new Border(
                right: new BorderSide(width: 1.0, color: Colors.white24))),
        child: getIcons(obj)
      ),
      title: Text(
        obj.name,
        style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 25),
      ),
    );

    Card makeCardDev(dynamic obj) => Card(
      elevation: 8.0,
      margin: new EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      child: Container(
        decoration: BoxDecoration(color: Color.fromRGBO(58, 66, 86, 0.9)),
        child: makeListTileDev(obj),
      ),
    );

    ListTile makeListTileSpr(dynamic obj) => ListTile(
      contentPadding:
          EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      leading: Container(
        padding: EdgeInsets.only(right: 12.0),
        decoration: new BoxDecoration(
            border: new Border(
                right: new BorderSide(width: 1.0, color: Colors.white24))),
        child: getIcons(obj)
      ),
      title: Text(
        obj.name,
        style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 25),
      ),
      trailing: Icon(Icons.keyboard_arrow_right, color: Colors.white, size: 30.0),
        onTap: () {
        Navigator.push( context, MaterialPageRoute(
          builder: (context) => SprintPage(project: widget.project, devUid: widget.devUid, sprint: obj, )));
        },
    );

    Card makeCardSpr(dynamic obj) => Card(
          elevation: 8.0,
          margin: new EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
          child: Container(
            decoration: BoxDecoration(color: Color.fromRGBO(58, 66, 86, 0.9)),
            child: makeListTileSpr(obj),
          ),
    );

    StreamBuilder<QuerySnapshot> _retrieveDev() {
      return new StreamBuilder<QuerySnapshot>(
          stream: Firestore.instance.collection('developers').snapshots(),
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
                  if (widget.project.developers.contains(dp.documentID)) {
                    Developer dev = new Developer.fromJson(dp);
                    if(widget.project.admins.contains(widget.devUid) && !widget.project.admins.contains(dev.id))
                      return Dismissible(
                        child: makeCardDev(dev),
                        key: Key(UniqueKey().toString()),
                        background: Container(color: Colors.red),
                        direction: DismissDirection.endToStart,
                        onDismissed: (DismissDirection direction) {
                          bool removed = false;
                          setState(() {
                              removed = true;
                              CloudFunctions.instance.call(
                                functionName: 'RemoveDeveloper',
                                parameters: {
                                  'project': widget.project.id,
                                  'developer': dev.id
                                }
                              ).whenComplete(() {
                                Project.refreshProject(context, widget.project.id, Project.developers_page);
                              });
                          });
                        if(removed)
                          Scaffold.of(context).showSnackBar(SnackBar(
                        content: Text("Developers " + dev.name + " was removed")));
                        });
                    return makeCardDev(dev);
                  }
                  else return Container();
                });
          });
    }

    StreamBuilder<QuerySnapshot> _retrieveUS() {

      return new StreamBuilder<QuerySnapshot>(
        // Interacts with Firestore (not CloudFunction)
          stream: Firestore.instance
              .collection('userStories')
              .snapshots(),
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
                  if(widget.project.userStories.contains(dp.documentID)){
                    UserStory us = new UserStory.fromJson(dp);
                    return makeCardUS(us);
                  }
                  else return Container();
                });
          });
  }

    StreamBuilder<QuerySnapshot> _retrieveEv() {

      return new StreamBuilder<QuerySnapshot>(
        // Interacts with Firestore (not CloudFunction)
          stream: Firestore.instance
              .collection('events')
              .snapshots(),
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
                  if(widget.project.events.contains(dp.documentID)){
                    Event ev = new Event.fromJson(dp);
                    return makeCardEv(ev);
                  }
                  else return Container();
                  
                });
          });
    }

    StreamBuilder<QuerySnapshot> _retrieveProg() {
      
      return new StreamBuilder<QuerySnapshot> (
        // Interacts with Firestore (not CloudFunction)
          stream: Firestore.instance
              .collection('sprints')
              .snapshots(),
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
                  if(widget.project.sprints.contains(dp.documentID)){
                    Sprint spr = new Sprint.fromJson(dp);
                    return makeCardSpr(spr);
                  }
                  else return Container();
                });
          });
    }

    final List<Widget> _children = [
      getDescription,
      _retrieveEv(),
      _retrieveProg(),
      _retrieveDev(),
      _retrieveUS(),
    ];


    void onTabTapped(int index) {
      setState(() {
        _currentIndex = index;
      });
    }

    void _leave(){
      CloudFunctions.instance.call(
        functionName: "LeaveProject",
        parameters: {
          "project":widget.project.id,
        }
      );
      print("User "+widget.devUid+" leaves project "+widget.project.id );
      Navigator.of(context).pop();
    }

    void _addDeveloper(){
      Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => NewDeveloperPage(project: widget.project, devUid: widget.devUid,)));
    }

    void _addSprint(){
      Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => NewSprintPage(project: widget.project)));
    }

    void _addEvent(){
      Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => NewEventPage(project: widget.project)));
    }

    void _addUserStory(){
      Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => NewUserStoryPage(project: widget.project, sprint: false,)));
    }

    return new DefaultTabController(
      length: tabNames.length,
      child: new Scaffold(
        appBar: new AppBar(
          title: new Text(
            widget.project.name,
            style: TextStyle(color: Colors.white, fontSize: 30.0)
          ),
          backgroundColor: Color.fromRGBO(58, 66, 86, 0.9),
          actions: <Widget>[
            //widget.project.admins.contains(widget.devUid)? 
            new PopupMenuButton<int>(
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 1,
                  child: Text("Leave this project"),
                ),
                if(widget.project.admins.contains(widget.devUid))              
                  PopupMenuItem(
                    value: 2,
                    child: Text("Add developer"),
                  ),
                if(widget.project.admins.contains(widget.devUid))
                  PopupMenuItem(
                    value: 3,
                    child: Text("Add sprint"),
                  ),
                if(widget.project.admins.contains(widget.devUid))
                  PopupMenuItem(
                    value: 4,
                    child: Text("Add event"),
                  ),
                if(widget.project.admins.contains(widget.devUid))
                  PopupMenuItem(
                    value: 5,
                    child: Text("Add UserStory"),
                  ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 1: _leave();         break;
                  case 2: _addDeveloper();  break;
                  case 3: _addSprint();     break;
                  case 4: _addEvent();      break;
                  case 5: _addUserStory();  break;
                  default:
                }
              },
            )
            
          ],

        ),
        body: _children[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          iconSize: 18.0,
          onTap: onTabTapped, // new
          currentIndex: _currentIndex, // new
          selectedFontSize: 13,
          unselectedFontSize: 11,
          backgroundColor: Color.fromRGBO(58, 66, 86, 0.9),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.black,
          items: <BottomNavigationBarItem>[
            new BottomNavigationBarItem(
              icon: Icon(Icons.description),
              title: Text('Description'),
            ),
            new BottomNavigationBarItem(
                icon: Icon(Icons.event), title: Text('Events')),
            new BottomNavigationBarItem(
                icon: Icon(Icons.equalizer), title: Text('Progress')),
            new BottomNavigationBarItem(
              icon: Icon(Icons.group),
              title: Text('Developers'),
            ),
            if(widget.project.admins.contains(widget.devUid))
              new BottomNavigationBarItem(
                icon: Icon(Icons.format_list_bulleted), title: Text('UStories')),
          ],
        ),
      ),
    );
  }
}
