import 'package:apt/model/developer.dart';
import 'package:apt/model/project.dart';

class Event {
  String id;
  String name;
  DateTime dateTime;
  String description;
  String type;
  Project project; //link field
  Developer developer; //link field

  Event({this.id, this.name, this.dateTime, this.description, this.type, this.project, this.developer});

  factory Event.fromJson(Map<String, dynamic> json) => Event(
    id: json["id"],
    name: json["name"],
    dateTime: json["dateTime"],
    description: json["description"],
    type: json["type"],
    project: json["project"],
    developer: json["developer"],
  );

  dynamic toJson() => {
    "id": id,
    "name": name,
    "dateTime": dateTime,
    "description": description,
    "type": type,
    "project": project,
    "developer": developer,
  };

}