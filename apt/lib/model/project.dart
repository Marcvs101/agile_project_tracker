import 'package:apt/model/event.dart';
import 'package:apt/model/sprint.dart';
import 'package:apt/model/user_story.dart';
//import 'package:firebase/firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'developer.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

/*
class Project {
  String id;
  String name;
  String description;
  bool completed = false;
  Developer leader; //link field
  List<Developer> admins; //link field
  List<Developer> developers; //link field
  List<Event> events; //link field
  List<Sprint> sprints; //link field
  List<UserStory> userStories; //link field

  Project({this.id, this.name, this.description, this.completed, this.leader, this.admins, this.developers, this.events, this.sprints, this.userStories});

  factory Project.fromJson(Map<String, dynamic> json) => Project(
    id: json["id"],
    name: json["name"],
    description: json["description"],
    completed: json["completed"],
    leader: json["leader"],
    admins: json["admins"],
    developers: json["developers"],
    events: json["events"],
    sprints: json["sprints"],
    userStories: json["userStories"],
  );

  dynamic toJson() => {
    "id": id,
    "name": name,
    "description": description,
    "completed": completed,
    "leader": leader,
    "admins": admins,
    "developers": developers,
    "events": events,
    "sprints": sprints,
    "userStories": userStories,
  };
*/
  /*

  //to move in view element
  IconData _icona;
  Color _c;

  Project(String n, String p, String d, bool c, this.id){
    this.nome = n;
    this.proprietario = p;
    this.descrizione = d;
    this.completato = c;
    this.sviluppatori = Developer.getDevelopersByProject(this.id);
    if (completato)  
      this._icona =  Icons.check;
    else
      this._icona = Icons.clear;
  }

  IconData getIcon(){
    return _icona;
  }
  
  Color getColor(){
    if (completato)  
      this._c =  Colors.green;
    else
      this._c = Colors.red;
    return this._c;
  }
  
  static Future<List> getProjects(String uid) async {
 
    /* Query:
     * la chiamata prende in input l'id dell'utente tramite user.uid
     * e ritorna una List dei progetti cui l'utente ha collaborato,
     * non solo quelli di cui ne è il proprietario
     */
    var url = 'https://us-central1-agile-project-tracker.cloudfunctions.net/GetProjectsForUser'+'/'+uid;
    var response = await http.get(url);
    
    //Stampe utili per il debug:
    //print('Response status: ${response.statusCode}');
    //print('Response parsed:${json.decode(response.body)}');
    
    List<Project> projects = [];
    Map<String, dynamic> projectsMap = json.decode(response.body);
    projectsMap.forEach( (k,v) =>  
        projects.add(new Project(v['nome'],v['proprietario'],v['descrizione'],v['completato'],k))
    );

    return projects;
  }


}
*/

import 'package:flutter/material.dart';
import 'developer.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';


class Project {
  
  final String id;
  String nome;
  String proprietario;
  String descrizione;
  bool completato = false;
  List <String> sviluppatori;
  
  IconData _icona;
  Color _c;


  Project(String n, String p, String d, bool c, this.id){
    this.nome = n;
    this.proprietario = p;
    this.descrizione = d;
    this.completato = c;
    this.sviluppatori = [];
    if (completato)  
      this._icona =  Icons.check;
    else
      this._icona = Icons.clear;
  }

  factory Project.fromJson(DocumentSnapshot d ) => Project(d['nome'], d['proprietario'],d['descrizione'], d['completato'], d.documentID);

  

  IconData getIcon(){
    return _icona;
  }
  
  Color getColor(){
    if (completato)  
      this._c =  Colors.green;
    else
      this._c = Colors.red;
    return this._c;
  }
  
  static Future<List> getProjects(String uid) async {
 
    /* Query:
     * la chiamata prende in input l'id dell'utente tramite user.uid
     * e ritorna una List dei progetti cui l'utente ha collaborato,
     * non solo quelli di cui ne è il proprietario
     */
    var url = 'https://us-central1-agile-project-tracker.cloudfunctions.net/GetProjectsForUser'+'/'+uid;
    var response = await http.get(url);
    
    //Stampe utili per il debug:
    //print('Response status: ${response.statusCode}');
    //print('Response parsed:${json.decode(response.body)}');
    
    List<Project> projects = [];
    Map<String, dynamic> projectsMap = json.decode(response.body);
    projectsMap.forEach( (k,v) =>  
        projects.add(new Project(v['nome'],v['proprietario'],v['descrizione'],v['completato'],k))
    );

    return projects;
  }

}
