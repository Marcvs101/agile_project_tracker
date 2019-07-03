import 'package:flutter/material.dart';
import 'developer.dart';

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
  
  static List getProjects(){
    /* 
     * Query da implementare:
     * la chiamata proviene dal costruttore in homepage
     * dovrebbe prendere in input l'id dell'utente
     * e ritornare una List dei progetti cui l'utente
     * ha collaborato, non solo quelli in cui
     * è il proprietario
     */
    return pp;
  }
}