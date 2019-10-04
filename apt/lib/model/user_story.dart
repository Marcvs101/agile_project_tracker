/*
import 'developer.dart';
import 'project.dart';

class UserStory{
  String id;
  bool completed = false;
  String name;
  String description;
  Project project; //link field
  Developer developer; //link field

  UserStory({this.id, this.completed, this.name, this.description, this.project, this.developer});

  factory UserStory.fromJson(Map<String, dynamic> json) => UserStory(
    id: json["id"],
    completed: json["completed"],
    name: json["name"],
    description: json["description"],
    project: json["project"],
    developer: json["developer"],
  );

  dynamic toJson() => {
    "id": id,
    "completed": completed,
    "name": name,
    "description": description,
    "project": project,
    "developer": developer,
  };

}
*/

import 'package:flutter/material.dart';
import 'developer.dart';
import 'project.dart';

class UserStory{

  String id;
  static Project project;
  String nome;
  String desc;
  static Developer developer;
  bool completata;

  IconData _icona;
  Color _c;

  UserStory(Project project){
    setPr(project);
  }

  IconData getIcon(){
    return _icona;
  }
  
  Color getColor(){
    if (completata)  
      this._c =  Colors.green;
    else
      this._c = Colors.red;
    return this._c;
  }

  void setPr(Project p){
    project = p;
  }

  Project getPr(){
    return project;
  }

  Developer getDev(){
    return developer;
  }
  void setDev(Developer d){
    developer = d;
  }
  
  static List getUserStoryFromDev(Developer d, Project p){
    /*
     * Query che dato un dev 
     * ritorna le sue userstories per il project p
     */
    UserStory u = new UserStory(p);
    u.id = '11111';
    u.desc = 'papapap';
    u.nome = 'UStory '+d.nome;
    u.completata = false;
    if (u.completata)  
      u._icona =  Icons.check;
    else
      u._icona = Icons.clear;
    //u.setPr(p);
    u.setDev(d);
    return [u];
  }

  static List getUserStoryFromPr(Project p){
    /*
     * Query che dato un project 
     * ritorna le sue userstories
     */
    UserStory u = new UserStory(p);
    u.id = '2222';
    u.desc = 'qqqqq';
    u.nome = 'Us Pr';
    u.completata = false;
    if (u.completata)  
      u._icona =  Icons.check;
    else
      u._icona = Icons.clear;
    u.setDev(Developer('3'));
    //u.setPr(p);
    return [u];
  }


}