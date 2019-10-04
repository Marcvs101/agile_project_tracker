class GitHubLoginResponse {
  String accessToken;
  String tokenType;
  String scope;

  GitHubLoginResponse({this.accessToken, this.tokenType, this.scope});

  factory GitHubLoginResponse.fromJson(Map<String, dynamic> json) => GitHubLoginResponse(
    accessToken: json["access_token"],
    tokenType: json["token_type"],
    scope: json["scope"],
  );

}