import 'package:cloud_firestore/cloud_firestore.dart';
class Sprint {
  String id;
  String name;
  String description;
  bool status;
  String project; //link field
  String schedule;
  List userStories; //link field

  Sprint({this.id,this.name, this.description, this.status, this.project,this.schedule, this.userStories});

  factory Sprint.fromJson(DocumentSnapshot json) => Sprint(
      id: json.documentID,
      name: json["name"],
      description: json["description"],
      status: json["status"],
      project: json["project"],
      schedule: json["schedule"],
      userStories: json["userStories"],
  );

  dynamic toJson() => {
    "id": id,
    "name": name,
    "description": description,
    "status": status,
    "project": project,
    "schedule": schedule,
    "userStories": userStories,
  };

}
