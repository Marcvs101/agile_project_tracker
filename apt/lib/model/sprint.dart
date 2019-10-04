import 'package:apt/model/project.dart';
import 'package:apt/model/user_story.dart';

class Sprint {
  String id;
  String name;
  String description;
  bool status;
  String project; //link field
  List<String> userStories; //link field

  Sprint({this.name, this.description, this.status, this.project, this.userStories});

  factory Sprint.fromJson(Map<String, dynamic> json) => Sprint(
      name: json["name"],
      description: json["description"],
      status: json["status"],
      project: json["project"],
      userStories: json["userStories"],
  );

  dynamic toJson() => {
    "name": name,
    "description": description,
    "status": status,
    "project": project,
    "userStories": userStories,
  };

}
