import 'package:flutter/material.dart';
import 'model/user_story.dart';
import 'model/developer.dart';
import 'model/project.dart';
import 'user_story_page.dart';



class DevUserStoryPage extends StatefulWidget{
  DevUserStoryPage({Key key, this.dev, this.pr}) : super(key: key);

  final String title = 'User stories of ';
  final Developer dev;
  final Project pr;

  @override
  _DevUserStoryPageState createState() => _DevUserStoryPageState();
}

class _DevUserStoryPageState extends State<DevUserStoryPage>{

  List userstory;


  @override
  void initState(){
    userstory = UserStory.getUserStoryFromDev(widget.dev, widget.pr);
    super.initState();
  }
  
  @override
  Widget build(BuildContext context){

/* 
 * Viene chiamato dalla funzione makecard
 * genera il contenuto che va all'interno della card
 */
    ListTile makeListTile(UserStory userstory) => ListTile(
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
          child: Icon(userstory.getIcon(),color: userstory.getColor(),size: 35,
            ),
        ),
        title: Text(
          userstory.name,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold,fontSize: 25),
        ),
        subtitle: Text(
          widget.pr.nome, style: TextStyle(color: Colors.white, fontStyle: FontStyle.italic),
        ),
        trailing:
          Icon(Icons.keyboard_arrow_right, color: Colors.white,size: 30.0),
        onTap: (){
          /* il metodo serve a renderizzare la pagina della userstory selezionata
           * quindi prendo l'id userstory come parametro nel costruttore
           */
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => 
              UserStoryPage(userStory: userstory)
            )
          );
        },
    );

/* 
 * codice che crea la struttura della card
 * che conterrà una userstory
 */
    Card makeCard(UserStory userstory) => Card(
      elevation: 8.0,
      margin: new EdgeInsets.symmetric(
        horizontal: 10.0,
        vertical:6.0
      ),
      child: Container(
        decoration: BoxDecoration(color: Color.fromRGBO(58, 66, 86, 0.9)),
        child: makeListTile(userstory),
      ),
    ); 

/*
 * crea la sezione scrollabile che conterrà le card
 */
    final makeBody = Container(
      child: ListView.builder(
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        itemCount: userstory.length,
        itemBuilder: (BuildContext context, int index){
          return makeCard(userstory[index]);
        },
      ),
    );

/*
 * crea la barra superiore
 */
    final topAppBar = AppBar(
      elevation: 0.1,
      backgroundColor: Color.fromRGBO(58, 66, 86, 1),
      title: Text(widget.title+''+widget.dev.nome),
    );

    return Scaffold(
      appBar: topAppBar,
      backgroundColor: Colors.grey,
      body: makeBody,
    );    
  }
}