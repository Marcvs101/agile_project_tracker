import 'package:apt/model/project.dart';
import 'package:apt/model/user_story.dart';

class Sprint {
  String id;
  String name;
  String description;
  String status;
  DateTime expiration;
  Project project; //link field
  List<UserStory> userStories; //link field

  Sprint({this.name, this.description, this.status, this.expiration, this.project, this.userStories});

  factory Sprint.fromJson(Map<String, dynamic> json) => Sprint(
      name: json["name"],
      description: json["description"],
      status: json["status"],
      expiration: json["expiration"],
      project: json["project"],
      userStories: json["userStories"],
  );

  dynamic toJson() => {
    "name": name,
    "description": description,
    "status": status,
    "expiration": expiration,
    "project": project,
    "userStories": userStories,
  };

}
