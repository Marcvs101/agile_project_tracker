
import 'developer.dart';
import 'project.dart';

class UserStory{
  String id;
  bool completed = false;
  String name;
  String description;
  String project; //link field
  String developer; //link field

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