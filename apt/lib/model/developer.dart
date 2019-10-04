import 'package:apt/model/project.dart';

class Developer{
  String id;
  String name;
  String email;
  List<Project> projects; //link field



}

/*
class Developer{

  String id;
  List projects;
  String nome;
  

  Developer(String id){
    /*
     * Dovrò fare la query che dato un id ritorno un developer 
     */
    this.id = id;
    this.projects = [];
    this.nome = "dev_"+id;
  }

  static List getDevelopersByProject(projectId){
    /* 
     * Query da implementare:
     * dato un id di un progetto ritorna una lista di developers
     */
    List ds = [Developer('1'),Developer('2')];
    return ds;
  }

}
*/