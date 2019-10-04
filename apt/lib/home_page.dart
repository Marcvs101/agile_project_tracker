import 'package:apt/sign_in_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'model/project.dart';
import 'project_page.dart';
import 'new_project.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  HomePage({
    Key key,
    @required this.user,
    @required this.auth,
  }) : super(key: key);

  final FirebaseUser user;
  final FirebaseAuth auth;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
/* 
 * Viene chiamato dalla funzione makecard
 * genera il contenuto che va all'interno della card
 */

    ListTile makeListTile(Project project) => ListTile(
          contentPadding:
              EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          leading: Container(
            padding: EdgeInsets.only(right: 12.0),
            decoration: new BoxDecoration(
                border: new Border(
                    right: new BorderSide(width: 1.0, color: Colors.white24))),
            child: Icon(
              project.getIcon(),
              color: project.getColor(),
              size: 35,
            ),
          ),
          title: Text(
            project.nome,
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 25),
          ),
          subtitle: Text(
            project.proprietario,
            style: TextStyle(color: Colors.white, fontStyle: FontStyle.italic),
          ),
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
          },
        );

/* 
 * codice che crea la struttura della card
 * che conterrà un progetto
 */
    Card makeCard(Project project) => Card(
          elevation: 8.0,
          margin: new EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
          child: Container(
            decoration: BoxDecoration(color: Color.fromRGBO(58, 66, 86, 0.9)),
            child: makeListTile(project),
          ),
        );

/*
 * crea la barra superiore
 */
    void logout() {
      widget.auth.signOut();
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) => new SignInPage(auth: widget.auth)),
          (route) => false);
    }

    Future<void> logoutAlert() async {
      return showDialog<void>(
        context: context,
        //barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Logout'),
            content: SingleChildScrollView(
              child: new Text('Are you sure you want to log out?.'),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text('no'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              FlatButton(
                child: Text('yes'),
                onPressed: () {
                  logout();
                },
              ),
            ],
          );
        },
      );
    }

    final topAppBar = AppBar(
      elevation: 0.1,
      backgroundColor: Color.fromRGBO(58, 66, 86, 1),
      title: Text(widget.user.displayName),
      actions: <Widget>[
        new IconButton(
          icon: new Icon(Icons.exit_to_app),
          onPressed: () {
            logoutAlert();
          },
        ),
      ],
    );
/*
    FutureBuilder _loadProject() {
      return new FutureBuilder<List>(
          future: Project.getProjects(widget.user.uid),
          builder: (context, AsyncSnapshot<dynamic> snapshot) {
            if (!snapshot.hasData) return new Container();
            var content = snapshot.data;
            return new ListView.builder(
                scrollDirection: Axis.vertical,
                shrinkWrap: true,
                itemCount: content.length,
                itemBuilder: (BuildContext context, int index) {
                  Project pr = content[index] as Project;
                  return Dismissible(
                    child: makeCard(pr),
                    key: Key(UniqueKey().toString()),
                    background: Container(color: Colors.red),
                    direction: DismissDirection.endToStart,
                    onDismissed: (DismissDirection direction) {
                      bool removed = false;
                      setState(() {
                        if (widget.user.uid == pr.proprietario) {
                          removed = true;
                          Firestore.instance
                              .collection('progetti')
                              .document(pr.id)
                              .delete();
                        }
                      });
                      removed
                          ? Scaffold.of(context).showSnackBar(SnackBar(
                              content: Text("Project " + pr.nome + " removed")))
                          : Scaffold.of(context).showSnackBar(SnackBar(
                              content: Text("Project " +
                                  pr.nome +
                                  " cannot be removed")));
                    },
                    //child: makeCard(pr),
                  );
                });
          });
    }

    Future<Null> _reload() async {
      await Future.delayed(Duration(seconds: 2));
      setState(() {
        _loadProject();
      });
      return null;
    }
*/
    StreamBuilder<QuerySnapshot> _retrieveUsers() {
      return new StreamBuilder<QuerySnapshot>(
          // Interacts with Firestore (not CloudFunction)
          stream: Firestore.instance
              .collection('progetti')
              .where("sviluppatori", arrayContains: widget.user.uid)
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
                  //Project pr = new Project(dp["nome"], dp["proprietario"], dp["descrizione"], dp["completato"], dp.documentID);
                  Project pr = new Project.fromJson(dp);
                  return Dismissible(
                    child: makeCard(pr),
                    key: Key(UniqueKey().toString()),
                    background: Container(color: Colors.red),
                    direction: DismissDirection.endToStart,
                    onDismissed: (DismissDirection direction) {
                      bool removed = false;
                      setState(() {
                        if (widget.user.uid == pr.proprietario) {
                          removed = true;
                          Firestore.instance
                              .collection('progetti')
                              .document(pr.id)
                              .delete();
                        }
                      });
                      removed
                          ? Scaffold.of(context).showSnackBar(SnackBar(
                              content: Text("Project " + pr.nome + " removed")))
                          : Scaffold.of(context).showSnackBar(SnackBar(
                              content: Text("Project " +
                                  pr.nome +
                                  " cannot be removed")));
                    },
                  );
                });
          });
    }

    return Scaffold(
      appBar: topAppBar,
      backgroundColor: Colors.grey,
      body: _retrieveUsers(),
      //RefreshIndicator(
      //child: _loadProject(),
      //onRefresh: _reload,
      //),

      floatingActionButton: new FloatingActionButton.extended(
        backgroundColor: Color.fromRGBO(58, 66, 86, 0.9),
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => NewProjectPage(user: widget.user))),
        tooltip: 'Increment',
        label: Text("new project!"),
        icon: new Icon(Icons.add),
      ),
    );
  }
}
