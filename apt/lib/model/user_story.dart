import 'package:cloud_firestore/cloud_firestore.dart';


class UserStory{
  String id;
  String completed; //contiene commit o stringa vuota
  int score;
  String name;
  String description;
  String project; //link field
  String sprint; //link field

  UserStory({this.id, this.completed, this.name, this.score,this.description, this.project, this.sprint});

  factory UserStory.fromJson(DocumentSnapshot json) => UserStory(
    id: json.documentID,
    completed: json["completed"],
    name: json["name"],
    score: json["score"],
    description: json["description"],
    project: json["project"],
    sprint: json["sprint"],
  );


  dynamic toJson() => {
    "id": id,
    "completed": completed,
    "name": name,
    "score": score,
    "description": description,
    "project": project,
    "developer": sprint,
  };

}