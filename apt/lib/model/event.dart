class Event {
  String id;
  String name;
  String description;
  String type;
  String project; //link field
  String developer; //link field

  Event({this.id, this.name, this.description, this.type, this.project, this.developer});

  factory Event.fromJson(Map<String, dynamic> json) => Event(
    id: json["id"],
    name: json["name"],
    description: json["description"],
    type: json["type"],
    project: json["project"],
    developer: json["developer"],
  );

  dynamic toJson() => {
    "id": id,
    "name": name,
    "description": description,
    "type": type,
    "project": project,
    "developer": developer,
  };

}