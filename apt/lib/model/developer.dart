import 'package:cloud_firestore/cloud_firestore.dart';

class Developer{
  String id;
  String name;
  String email;

  Developer({this.id, this.name, this.email});

  factory Developer.fromJson(DocumentSnapshot json) => Developer(
    id: json.documentID,
    name: json["name"],
    email: json["email"],
  );

  dynamic toJson() =>
  {
    "id": id,
    "name": name,
    "email": email,
  };

}