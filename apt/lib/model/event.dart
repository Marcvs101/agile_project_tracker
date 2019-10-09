import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  String id;
  String name;
  String description;
  String type;
  String date;
  String project; //link field
  String developer; //link field

  Event({this.id, this.name, this.description, this.type,this.date, this.project, this.developer});

  factory Event.fromJson(DocumentSnapshot json) => Event(
    id: json.documentID,
    name: json["name"],
    description: json["description"],
    type: json["type"],
    date: json["date"],
    project: json["project"],
    developer: json["developer"],
  );

  dynamic toJson() => {
    "id": id,
    "name": name,
    "description": description,
    "type": type,
    "date": date,
    "project": project,
    "developer": developer,
  };

}