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
  List sviluppatori;

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