import 'package:apt/model/event.dart';
import 'package:apt/model/user_story.dart';

import 'developer_page.dart';
import 'model/developer.dart';
import 'model/project.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pr_user_story_page.dart';

class ProjectPage extends StatefulWidget {
  final Project project;
  ProjectPage({Key key, this.project}) : super(key: key);

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
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final getDescription = Container(
        width: MediaQuery.of(context).size.width,
        padding: EdgeInsets.all(20.0),
        child: new SingleChildScrollView(
            child: Text(
          widget.project.description,
          style: TextStyle(fontSize: 18.0),
        )));

    IconData getIcons(dynamic obj) {
      IconData ico;
      if (obj is Developer) {
        if (widget.project.owner == obj.id)
          ico = Icons.verified_user;
        else if (widget.project.admins.contains(obj.id))
          ico = Icons.supervised_user_circle;
        else
          ico = Icons.account_circle;
      } else {
        switch (obj) {
          case Event:
            break;
          case UserStory:
            break;
          default: //Progress case
        }
      }
      return ico;
    }

    ListTile makeListTile(dynamic obj) => ListTile(
          contentPadding:
              EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          leading: Container(
            padding: EdgeInsets.only(right: 12.0),
            decoration: new BoxDecoration(
                border: new Border(
                    right: new BorderSide(width: 1.0, color: Colors.white24))),
            child: Icon(getIcons(obj),color: Colors.white,),
          ),
          title: Text(
            obj.name,
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 25),
          ),
          /*
      trailing:
      Icon(Icons.keyboard_arrow_right, color: Colors.white, size: 30.0),
      onTap: () {
        /* il metodo serve a renderizzare la pagina del progetto selezionato
         * quindi prendo un progetto come parametro nel costruttore
         */
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ProjectPage(project: project)));
      },*/
        );

    Card makeCard(dynamic obj) => Card(
          elevation: 8.0,
          margin: new EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
          child: Container(
            decoration: BoxDecoration(color: Color.fromRGBO(58, 66, 86, 0.9)),
            child: makeListTile(obj),
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
            print(content.length);
            return new ListView.builder(
                scrollDirection: Axis.vertical,
                shrinkWrap: true,
                itemCount: content.length,
                itemBuilder: (BuildContext context, int index) {
                  var dp = content[index];
                  if (widget.project.developers.contains(dp.documentID)) {
                    Developer dev = new Developer.fromJson(dp);
                    return makeCard(dev);
                  }
                  else return Container();
                });
          });
    }

/*
    StreamBuilder<QuerySnapshot> _retrieveUS() {

    return new StreamBuilder<QuerySnapshot>(
      // Interacts with Firestore (not CloudFunction)
        stream: Firestore.instance
            .collection('projects')
            .where("developers", arrayContains: widget.user.uid)
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
                Project pr = new Project.fromJson(dp);
                return Dismissible(
                  child: makeCard(pr),
                  key: Key(UniqueKey().toString()),
                  background: Container(color: Colors.red),
                  direction: DismissDirection.endToStart,
                  onDismissed: (DismissDirection direction) {
                    bool removed = false;
                    setState(() {
                      if (widget.user.uid == pr.owner) {
                        removed = true;
                        Firestore.instance
                            .collection('projects')
                            .document(pr.id)
                            .delete();
                      }
                    });
                    removed
                        ? Scaffold.of(context).showSnackBar(SnackBar(
                        content: Text("Project " + pr.name + " removed")))
                        : Scaffold.of(context).showSnackBar(SnackBar(
                        content: Text("Project " +
                            pr.name +
                            " cannot be removed")));
                  },
                );
              });
        });
  }

    StreamBuilder<QuerySnapshot> _retrieveEv() {

    return new StreamBuilder<QuerySnapshot>(
      // Interacts with Firestore (not CloudFunction)
        stream: Firestore.instance
            .collection('projects')
            .where("developers", arrayContains: widget.user.uid)
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
                Project pr = new Project.fromJson(dp);
                return Dismissible(
                  child: makeCard(pr),
                  key: Key(UniqueKey().toString()),
                  background: Container(color: Colors.red),
                  direction: DismissDirection.endToStart,
                  onDismissed: (DismissDirection direction) {
                    bool removed = false;
                    setState(() {
                      if (widget.user.uid == pr.owner) {
                        removed = true;
                        Firestore.instance
                            .collection('projects')
                            .document(pr.id)
                            .delete();
                      }
                    });
                    removed
                        ? Scaffold.of(context).showSnackBar(SnackBar(
                        content: Text("Project " + pr.name + " removed")))
                        : Scaffold.of(context).showSnackBar(SnackBar(
                        content: Text("Project " +
                            pr.name +
                            " cannot be removed")));
                  },
                );
              });
        });
  }

    StreamBuilder<QuerySnapshot> _retrieveProg() {
      
      return new StreamBuilder<QuerySnapshot>(
        // Interacts with Firestore (not CloudFunction)
          stream: Firestore.instance
              .collection('projects')
              .where("developers", arrayContains: widget.user.uid)
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
                  Project pr = new Project.fromJson(dp);
                  return Dismissible(
                    child: makeCard(pr),
                    key: Key(UniqueKey().toString()),
                    background: Container(color: Colors.red),
                    direction: DismissDirection.endToStart,
                    onDismissed: (DismissDirection direction) {
                      bool removed = false;
                      setState(() {
                        if (widget.user.uid == pr.owner) {
                          removed = true;
                          Firestore.instance
                              .collection('projects')
                              .document(pr.id)
                              .delete();
                        }
                      });
                      removed
                          ? Scaffold.of(context).showSnackBar(SnackBar(
                          content: Text("Project " + pr.name + " removed")))
                          : Scaffold.of(context).showSnackBar(SnackBar(
                          content: Text("Project " +
                              pr.name +
                              " cannot be removed")));
                    },
                  );
                });
          });
    }

*/

    final List<Widget> _children = [
      getDescription,
      getDescription,
      getDescription,
      _retrieveDev(),
      getDescription
    ];

/*
final List<Widget> _children = [
      getDescription,
      _retrieveEv(),
      _retrieveUS(),
      _retrieveDev(),
      _retrieveProg()
    ];
*/

    void onTabTapped(int index) {
      setState(() {
        _currentIndex = index;
      });
    }

    return new DefaultTabController(
      length: tabNames.length,
      child: new Scaffold(
        appBar: new AppBar(
            title: new Text(widget.project.name,
                style: TextStyle(color: Colors.white, fontSize: 30.0)),
            backgroundColor: Color.fromRGBO(58, 66, 86, 0.9)),
        body: _children[_currentIndex],
        /*
        new TabBarView(
          children: new List<Widget>.generate(tabNames.length, (int index) {
            //print(tabNames[index]);
            switch (_currentIndex) {
              case 0:
                return getDescription;
                break;
              case 3:
                return _retrieveDev();
                break;
              case 2: //return _retrieveUS();
                break;
              case 1: //return _retrieveEv();
                break;
              case 4: //return _retrieveProg();
                break;

              default:
                return new Center();
            }
          }),
        ),*/

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
              icon: Icon(Icons.format_list_bulleted),
              title: Text('UStories'),
            ),
            new BottomNavigationBarItem(
              icon: Icon(Icons.group),
              title: Text('Developers'),
            ),
            new BottomNavigationBarItem(
                icon: Icon(Icons.equalizer), title: Text('Progress')),
          ],
        ),
      ),
    );
  }
}
