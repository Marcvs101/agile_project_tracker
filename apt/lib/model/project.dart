import 'package:flutter/material.dart';
import 'developer.dart';

import 'package:cloud_functions/cloud_functions.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';


class Project {
  
  final String id;
  String nome;
  String proprietario;
  String descrizione;
  bool completato = false;
  List sviluppatori;

  IconData _icona;
  Color _c;

  static List pp = [
    Project(
      "Progetto numero 1", 
      "salvo", 
      "questo è il progetto numero 1, bla bla bla...\n aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbaaaaaaa\n\n\naaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaapapapapapa",
      false,
      "1111",
    ),
    Project(
      "progetto 2",
      "leonardo",
      "questo è il progetto numero 2, bla bla bla...",
      true,
      "2222"
    ),
    Project(
      "progetto 3",
      "marco",
      "questo è il progetto numero 3, bla bla bla...",
      false,
      "3333"
    )
  ];


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
  
 /* 
  //prendo in input l'id dell'utente
  static List<Project> getProjects(String uid) {
    /* 
     * Query da implementare:
     * la chiamata proviene dal costruttore in homepage
     * dovrebbe prendere in input l'id dell'utente -> viene passato tramite user.uid
     * e ritornare una List dei progetti cui l'utente
     * ha collaborato, non solo quelli in cui
     * è il proprietario
     */
    print(uid);
    var a = query(uid);
    a.then((val){
      return val;
    });
    //List<Project> res = Future..result(a, secondsToWait 1);

    //var future = new Future(query(uid).then(value){return value;}
    //return l;
  }*/

  static Future<List> getProjects(String uid) async {
    /* 
     * Query da implementare:
     * la chiamata proviene dal costruttore in homepage
     * dovrebbe prendere in input l'id dell'utente -> viene passato tramite user.uid
     * e ritornare una List dei progetti cui l'utente
     * ha collaborato, non solo quelli in cui
     * è il proprietario
     */
    var url = 'https://us-central1-agile-project-tracker.cloudfunctions.net/GetProjectsForUser'+'/'+uid;
    var response = await http.get(url);//, body: {uid});
    
    //http.post(url, body);
    print('Response status: ${response.statusCode}');
    print('Response parsed:${json.decode(response.body)}');
    
    List<Project> projects = [];
    Map<String, dynamic> projectsMap = json.decode(response.body);
    projectsMap.forEach( (k,v) =>  
        projects.add(new Project(v['nome'],v['proprietario'],v['descrizione'],v['completato'],k))
    );

    return projects;
  }

}