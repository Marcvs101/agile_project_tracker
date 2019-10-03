import 'package:apt/sign_in_page.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:firebase/firestore.dart';
import 'package:flutter/material.dart';
import 'model/project.dart';
import 'project_page.dart';
import 'new_project.dart';



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

    void logout() {
      FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SignInPage(auth: FirebaseAuth.instance)));
    }

    final topAppBar = AppBar(
      elevation: 0.1,
      backgroundColor: Color.fromRGBO(58, 66, 86, 1),
      title: Text(widget.user.displayName),
      actions: <Widget>[
        new IconButton(icon: new Icon(Icons.exit_to_app),
          onPressed: (){
              logout();
            },
        ),
      ],
    );

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
                child: makeCard(pr),
                key: Key(UniqueKey().toString()),
                background: Container(color: Colors.red),
                direction: DismissDirection.endToStart,
                onDismissed: (DismissDirection direction){
                  bool removed = false;
                  setState(() {
                    if(widget.user.uid == pr.proprietario){
                      removed = true;
                      Firestore.instance.collection('progetti').document(pr.id).delete();
                    }
                  });
                  removed?
                  Scaffold.of(context).showSnackBar(SnackBar(content: Text("Project "+pr.nome+" removed"))):
                  Scaffold.of(context).showSnackBar(SnackBar(content: Text("Project "+pr.nome+" cannot be removed")));
                },
                //child: makeCard(pr),
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
        onPressed: () =>  Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NewProjectPage(user: widget.user)
                            )
                          ),//_showAddUserDialogBox(context),
        tooltip: 'Increment',
        label: Text("new project!"),
        icon: new Icon(Icons.add),
      ),
    );
  }
}