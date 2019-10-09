import 'package:cloud_firestore/cloud_firestore.dart';


class Project {
  String id;
  String name;
  String description;
  String owner; //link field
  List admins; //link field
  List developers; //link field
  List events; //link field
  List sprints; //link field
  List userStories; //link field

  Project(
      {this.id, this.name, this.description, this.owner, this.admins, this.developers, this.events, this.sprints, this.userStories});

  factory Project.fromJson(DocumentSnapshot json) =>
      Project(
        id: json.documentID,
        name: json["name"],
        description: json["description"],
        owner: json["owner"],
        admins: json["admins"],
        developers: json["developers"],
        events: json["events"],
        sprints: json["sprints"],
        userStories: json["userStories"],
      );

  dynamic toJson() =>
      {
        "id": id,
        "name": name,
        "description": description,
        "owner": owner,
        "admins": admins,
        "developers": developers,
        "events": events,
        "sprints": sprints,
        "userStories": userStories,
      };
}