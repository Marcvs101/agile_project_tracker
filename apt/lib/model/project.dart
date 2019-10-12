import 'package:apt/project_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as prefix0;


class Project {
  String id;
  String name;
  String description;
  String owner; //link field
  bool github;
  List admins; //link field
  List developers; //link field
  List events; //link field
  List sprints; //link field
  List userStories; //link field

  static int description_page = 0;
  static int events_page = 1;
  static int progress_page = 2;
  static int developers_page = 3;
  static int userstories_page = 4;

  Project(
      {this.id, this.name, this.description, this.owner, this.github, this.admins, this.developers, this.events, this.sprints, this.userStories});

  factory Project.fromJson(DocumentSnapshot json) =>
      Project(
        id: json.documentID,
        name: json["name"],
        description: json["description"],
        owner: json["owner"],
        github: json["github"],
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
        "github": github,
        "admins": admins,
        "developers": developers,
        "events": events,
        "sprints": sprints,
        "userStories": userStories,
      };

  static void refreshProject(context, id, page) {
    Firestore.instance.collection('projects').document(id).get().then((ds) {
      Project project = new Project.fromJson(ds);
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
          builder: (context) => new ProjectPage(project: project, devUid: project.owner, page: page,)), (route) => route.isFirst);
    });
  }

}