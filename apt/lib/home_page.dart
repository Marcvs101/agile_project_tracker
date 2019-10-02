import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:firebase/firestore.dart';
import 'package:flutter/material.dart';
import 'model/project.dart';
import 'project_page.dart';
import 'package:async/async.dart';


class HomePage extends StatefulWidget {
  HomePage({Key key, @required this.user}) : super(key: key);

  final FirebaseUser user;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>{

  @override
  Widget build(BuildContext context){

/* 
 * Viene chiamato dalla funzione makecard
 * genera il contenuto che va all'interno della card
 */

    ListTile makeListTile(Project project) => ListTile(
      contentPadding: 
        EdgeInsets.symmetric(horizontal: 20.0,vertical: 10.0),
        leading: Container(
          padding: EdgeInsets.only(right: 12.0),
          decoration: new BoxDecoration(
            border: new Border(
              right: new BorderSide(
                width: 1.0,
                color: Colors.white24
              )
            )
          ),
          child: Icon(project.getIcon(),color: project.getColor(),size: 35,
            ),
        ),
        title: Text(
          project.nome,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold,fontSize: 25),
        ),
        subtitle: Text(
          project.proprietario, style: TextStyle(color: Colors.white, fontStyle: FontStyle.italic),
        ),
        trailing:
          Icon(Icons.keyboard_arrow_right, color: Colors.white,size: 30.0),
        onTap: (){
          /* il metodo serve a renderizzare la pagina del progetto selezionato
           * quindi prendo un progetto come parametro nel costruttore
           */
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => 
              ProjectPage(project: project))
          );
        },
    );

/* 
 * codice che crea la struttura della card
 * che conterrà un progetto
 */
    Card makeCard(Project project) => Card(
      elevation: 8.0,
      margin: new EdgeInsets.symmetric(
        horizontal: 10.0,
        vertical:6.0
      ),
      child: Container(
        decoration: BoxDecoration(color: Color.fromRGBO(58, 66, 86, 0.9)),
        child: makeListTile(project),
      ),
    ); 

/*
 * crea la barra superiore
 */
    final topAppBar = AppBar(
      elevation: 0.1,
      backgroundColor: Color.fromRGBO(58, 66, 86, 1),
      title: Text(widget.user.displayName),
    );

    Future<Null> _showAddUserDialogBox(BuildContext context) {
      TextEditingController _nameTextController = new TextEditingController(); 
      TextEditingController _descrTextController = new TextEditingController();
 
      return showDialog<Null>(
        context: context,
        builder: (BuildContext context) {
          return new AlertDialog(
            title: const Text("Add a project"),
            content: Container(
              height: 200.0,
              width: 140.0,
              child: ListView(
                children: <Widget>[
                  new TextField(
                    controller: _nameTextController,
                    decoration: const InputDecoration(labelText: "Name: "),
                  ),
                  new TextField(
                    controller: _descrTextController,
                    decoration: const InputDecoration(labelText: "Description: "),
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                  ),
                ]
              ),
            ),
            actions: <Widget>[
              new FlatButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("Cancel")
              ),
              // This button results in adding the contact to the database
              new FlatButton(
                  onPressed: () {
                    CloudFunctions.instance.call(
                      functionName: "CreateNewProject",
                      parameters: {
                        "nome": _nameTextController.text,
		                    "descrizione": _descrTextController.text,
                        "proprietario": widget.user.uid,
                        "user_story": [],
                        "completato": false,
		                    "sviluppatori": [widget.user.uid],
		                    "amministratori": [],
		                  }
                    );
                    Navigator.of(context).pop();
                },
                child: const Text("Confirm")
              )
            ],
          );
        }
      );
    }

    
    StreamBuilder<QuerySnapshot> _retrieveProject() {
      return new StreamBuilder<QuerySnapshot>(
      // Interacts with Firestore (not CloudFunction)
      //stream: new CollectionReference collection('progetti').snapshots(),
      stream: Firestore.instance.collection('progetti').where('sviluppatori', arrayContains: widget.user.uid ).snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return Container();
          }
          return ListView.builder(
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemCount: snapshot.data.documents.length,
            itemBuilder: (context, index) {
              var v = snapshot.data.documents[index];
              Project p = new Project(v['nome'],v['proprietario'],v['descrizione'],v['completato'],v['uid']);
              return makeCard(p);
              //return new ListTile(
              //  title: new Text(snapshot.data.documents[index]['name']),
              //  subtitle: new Text(snapshot.data.documents[index]['email'])
              //);
            }
          );
        }
      );
    }

    FutureBuilder _loadProject(){
      return new FutureBuilder<List>(
        future: Project.getProjects(widget.user.uid),
        builder: (context, AsyncSnapshot<dynamic> snapshot) {
          if (!snapshot.hasData)
            return new Container();
          var content = snapshot.data;
          return new ListView.builder(
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemCount: content.length,
            itemBuilder: (BuildContext context, int index){
              Project pr = content[index] as Project;
              return Dismissible(
                key: Key(UniqueKey().toString()),
                background: Container(color: Colors.red),
                direction: DismissDirection.endToStart,
                onDismissed: (DismissDirection direction){
                  setState(() {
                    Firestore.instance.collection('progetti').document(pr.id).delete();
                  });
                  Scaffold
                    .of(context)
                    .showSnackBar(SnackBar(content: Text("Project "+pr.nome+" removed")));
                },
                child: makeCard(pr),
              );
            }
          );
        }
        
      );
    }

    return Scaffold(
      appBar: topAppBar,
      backgroundColor: Colors.grey,
      body: _loadProject(),
     
      floatingActionButton: new FloatingActionButton.extended(
        backgroundColor: Color.fromRGBO(58, 66, 86, 0.9),
        onPressed: () => _showAddUserDialogBox(context),
        tooltip: 'Increment',
        label: Text("new project!"),
        icon: new Icon(Icons.add),
      ),
    );
  }
}