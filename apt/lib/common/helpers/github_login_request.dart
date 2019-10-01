class GitHubLoginRequest {
  String clientId;
  String clientSecret;
  String code;

  GitHubLoginRequest({this.clientId, this.clientSecret, this.code});

  dynamic toJson() => {
    "client_id": clientId,
    "client_secret": clientSecret,
    "code": code,
  };
}