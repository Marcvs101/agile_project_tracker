import 'package:apt/model/user_story.dart';
import 'package:apt/model/project.dart';
import 'package:flutter/material.dart';
import 'package:apt/common/apt_secure_storage.dart' as globals;
import 'package:github/server.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'common/helpers/auth_helper.dart';

class UserStoryPage extends StatefulWidget {
  final UserStory userStory;
  final Project project;
  final String devUid;

  UserStoryPage({Key key, this.userStory, this.devUid, this.project})
      : super(key: key);

  @override
  _UserStoryPageState createState() => new _UserStoryPageState();
}

class _UserStoryPageState extends State<UserStoryPage> {
  @override
  Widget build(BuildContext context) {
    final status = Container(
      padding: const EdgeInsets.all(10.0),
      decoration: new BoxDecoration(
          border: new Border.all(color: Color.fromRGBO(58, 66, 86, 0.9)),
          borderRadius: BorderRadius.circular(5.0)),
      child: widget.userStory.completed == "" ? new Text(
        "Status: not completed",
        style:
            TextStyle(color: Color.fromRGBO(58, 66, 86, 0.9), fontSize: 16.0),
        textAlign: TextAlign.left,
      ):new Text(
        "Status: "+widget.userStory.completed.substring(0,7),
        style:
            TextStyle(color: Color.fromRGBO(58, 66, 86, 0.9), fontSize: 16.0),
        textAlign: TextAlign.left,
      )
    );

    void _complete() {
      globals.github.users.getCurrentUser().then((user) {
        globals.github.repositories
            .listCommits(new RepositorySlug(user.login, widget.project.name))
            .toList()
            .then((commits) {
          return showDialog(
            context: context,
            builder: (BuildContext context) {
              return new SimpleDialog(
                title: new Text("Select a git commit"),
                children: <Widget>[
                  for (var commit in commits)
                    SimpleDialogOption(
                      child: Text(commit.commit.sha.substring(0, 7) +
                          " - " +
                          commit.commit.message),
                      onPressed: () {
                        /*
                        CloudFunctions.instance.call(
                          functionName: "completeUs",
                          parameters: {
                            "completed":commit.commit.sha,
                            "userStory": widget.userStory.id
                          }
                        );*/
                        print("userstory " +
                            widget.userStory.id +
                            " completed by commit: " +
                            commit.commit.sha);
                      },
                    )
                ],
              );
            },
          );
        });
      });
    }

    void _revoke() {
      /*
        CloudFunctions.instance.call(
          functionName: "revokeUs",
          parameters: {
            "userStory": widget.userStory.id,
            "sprint": widget.userStory.sprint
          }
        );
      */
    }

    void _delete() {
      /*
        CloudFunctions.instance.call(
          functionName: "deleteUs",
          parameters: {
            "userStory": widget.userStory.id,
          }
        );
      */
    }

    return Scaffold(
        appBar: new AppBar(
            title: new Text(
              widget.userStory.name,
              style: TextStyle(color: Colors.white, fontSize: 30.0),
            ),
            backgroundColor: Color.fromRGBO(58, 66, 86, 0.9),
            actions: <Widget>[
              new PopupMenuButton<int>(
                  itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 1,
                          child: Text("Complete this user story"),
                        ),
                        if (widget.project.admins.contains(widget.devUid))
                          PopupMenuItem(
                            value: 2,
                            child: Text("Revoke user story"),
                          ),
                        if (widget.project.admins.contains(widget.devUid))
                          PopupMenuItem(
                            value: 3,
                            child: Text("Delete user story"),
                          ),
                      ],
                  onSelected: (value) {
                    switch (value) {
                      case 1:
                        _complete();
                        break;
                      case 2:
                        _revoke();
                        break;
                      case 3:
                        _delete();
                        break;
                      default:
                    }
                    Navigator.of(context).pop();
                  })
            ]),
        body: Column(children: <Widget>[
          Container(
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.all(20.0),
              child: new SingleChildScrollView(
                  child: new Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                    status,
                    Text("Score: " + widget.userStory.score.toString(),
                        style: TextStyle(fontSize: 16.0)),
                  ]))),
          Container(
            width: 300.0,
            child: new Divider(color: Color.fromRGBO(58, 66, 86, 0.9)),
          ),
          Container(
              height: 450,
              padding: EdgeInsets.all(20.0),
              width: MediaQuery.of(context).size.width,
              child: SingleChildScrollView(
                  child: Text(
                widget.userStory.description,
                style: TextStyle(fontSize: 18.0),
              )))
        ]));
  }
}
