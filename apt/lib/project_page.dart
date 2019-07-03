import 'developer_page.dart';
import 'model/project.dart';
import 'package:flutter/material.dart';
import 'pr_user_story_page.dart';


class ProjectPage extends StatelessWidget{
  
  final Project project;
  ProjectPage({Key key, this.project}): super(key: key);

  @override
  Widget build(BuildContext context){

/*
 * TextBox contenete il proprietario
 */
    final owner = Container(      
      padding:  const EdgeInsets.all(10.0),
      decoration: new BoxDecoration(
        border: new Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(5.0)
      ),
      child: new Text(
        "Owner:  "+project.proprietario,
        style: TextStyle(color: Colors.white), textAlign: TextAlign.left,
      ),
    );

/*
 * Box superiore contenente:
 * Titolo, stato del progetto e proprietario
 */
    final topContentText = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(height: 50.0),
        Text(
              project.nome,
              style: TextStyle(color: Colors.white,fontSize: 35.0),
            ),
        SizedBox(height: 15.0),
        Container(
          width: 180.0,
          child: new Divider(color: Colors.white),
        ),
        SizedBox(height: 15.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,         
          children: <Widget>[            
            owner,           
            Icon(
              project.getIcon(),
              color: project.getColor(),
              size: 40.0,
            ),
          ],
        ),
      ],
    );

/*
 * Container dove mettere il Box superiore 
 * e il collegamento per tornare indietro all'elenco progetti
 */
    final topContent = Stack(
      children: <Widget>[
        Container(
          height: MediaQuery.of(context).size.height *0.4,
          padding: EdgeInsets.all(40.0),
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(color: Color.fromRGBO(58, 66, 86, 0.9)),
          child: Center(child: topContentText),
        ),
        Positioned(
          left: 14.0,
          top: 40.0,
          child: InkWell(
            onTap: (){
              Navigator.pop(context);
            },
            child: Icon(Icons.arrow_back,color: Colors.white),
          )
        )
      ],
    );


/*
 * Tasto per andare nella pagina delle user stories
 */
    final userStoryButton = Container(
      padding: EdgeInsets.symmetric(vertical: 8.0,horizontal: 7.0),
      width: MediaQuery.of(context).size.width*0.3,
      child: RaisedButton(
        onPressed: () =>{
          /*
           * Il costruttore della pagina prende in input il progetto selezionato
           * (voglio tutte le user stories per quel progetto) 
           */
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => 
              PrUserStoryPage(pr: project)
            )
          )
        },
        color: Color.fromRGBO(58, 66, 86, 1.0),
         child: Text("User Stories", style: TextStyle(color: Colors.white)),
      ),
    );

/*
 * Tasto per andare nella pagina con gli sviluppatori
 */
    final developerButton = Container(
      padding: EdgeInsets.symmetric(vertical: 8.0,horizontal: 7.0),
      width: MediaQuery.of(context).size.width*0.3,
      child: RaisedButton(
          /*
           * Il costruttore della pagina prende in input il progetto selezionato
           * (voglio tutti i developer per il progetto)
           */
        onPressed: () =>{
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => 
              DeveloperPage(
                pr: project,
              )
            )
          )
        },
        color: Color.fromRGBO(58, 66, 86, 1.0),
        child:Text("Developers", style: TextStyle(color: Colors.white)),
      ),
    );

/*
 * Container scrollabile dove inserire la descrizione 
 */
    final textScrollable = Expanded(
      flex: 1,
      child: Container(
        width: MediaQuery.of(context).size.width,
        padding: EdgeInsets.all(20.0),
        child: Center(
          child: new SingleChildScrollView(
            child: Text(
              project.descrizione,
              style: TextStyle(fontSize: 18.0),
            )
          )
        )
      ),
    );

/*
 * Container dove agganciare i due tasti
 */
    final makeBottom = Container(
      width: MediaQuery.of(context).size.width,
      height: 65.0,
      child: BottomAppBar(
        child: Center(         
          child: Column(
            children:<Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[developerButton,userStoryButton],
              )]
          ),
          )
        )
    );

    return Scaffold(
      body: Column(children: <Widget>[topContent,textScrollable],),
      bottomNavigationBar: makeBottom
      );
  }
}