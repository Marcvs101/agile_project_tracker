/*

import 'package:flutter/material.dart';
import 'model/developer.dart';
import 'model/project.dart';
import 'dev_user_story_page.dart';

class DeveloperPage extends StatefulWidget{
  
  static String projectId;
  DeveloperPage({Key key, this.pr }):super(key: key);
  final Project pr;
  
  @override 
  _DeveloperPageState createState() => _DeveloperPageState();
}

class _DeveloperPageState extends State<DeveloperPage>{

  List developers;
  @override 
  void initState(){
    //developers = Developer.getDevelopersByProject(widget.pr);
    super.initState();
  }

  @override
  Widget build(BuildContext context){

/* 
 * Viene chiamato dalla funzione makecard
 * genera il contenuto che va all'interno della card
 */
    ListTile makeListTile(Developer developer) => ListTile(
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
          child: Icon(Icons.account_circle,color: Colors.white,size: 35,
            ),
        ),
        title: Text(
          developer.name,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold,fontSize: 25),
        ),
        
//        potrei aprire la pagina delle userstory per l'utente corrente
        trailing:
          Icon(Icons.keyboard_arrow_right, color: Colors.white,size: 30.0),
        onTap: (){
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => 
              DevUserStoryPage(dev: developer, pr: widget.pr)
            )
          );
        },
    );

/* 
 * codice che crea la struttura della card
 * che conterrà un progetto
 */
    Card makeCard(Developer developer) => Card(
      elevation: 8.0,
      margin: new EdgeInsets.symmetric(
        horizontal: 10.0,
        vertical:6.0
      ),
      child: Container(
        decoration: BoxDecoration(color: Color.fromRGBO(58, 66, 86, 0.9)),
        child: makeListTile(developer),
      ),
    );

/*
 * crea la sezione scrollabile che conterrà le card
 */    
    final makeBody = Container(
      child: ListView.builder(
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        itemCount: developers.length,
        itemBuilder: (BuildContext context, int index){
          return makeCard(developers[index]);
        },
      ),
    );

/*
 * crea la barra superiore
 */    
    final topAppBar = AppBar(
      elevation: 0.1,
      backgroundColor: Color.fromRGBO(58, 66, 86, 1),
      title: Text("Developers"),
    );

    return Scaffold(
      appBar: topAppBar,
      backgroundColor: Colors.grey,
      body: makeBody,
    );
  }
}


*/