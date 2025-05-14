import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String identifier = dotenv.env['API_IDENTIFIER'] ?? 'default-api';
  static String baseUrl =
      "https://$identifier.execute-api.ap-southeast-2.amazonaws.com/dev";
  static String get matchMaking => "$baseUrl/matchmaking";
  static String get activeMatch => "$baseUrl/active-matches";

  static String get getUserInfo => "$baseUrl/user";
  static String get getUploadImageUrl => "$baseUrl/avatar/upload";
  static String get getPulzzesUrl => "$baseUrl/puzzles";
  static String get getPulzzeUrl => "$baseUrl/puzzle";
  static String get matchResult => "$baseUrl/matchResults";

  static String get getFriendUrl => "$baseUrl/friends";
  static String get friendUrl => "$baseUrl/friend";

  static String getHistoryMatchUrl(String matchId) =>
      "$baseUrl/match/$matchId/states?limit=1000";
}

class WebsocketConstants {
  static String wsIdentifier =
      dotenv.env['WEBSOCKET_IDENTIFIER'] ?? 'default-ws';
  static const String serverEndpoint = "localhost:7202";

  static String get wsUrl =>
      "wss://$wsIdentifier.execute-api.ap-southeast-2.amazonaws.com/dev";
  static String get game => "ws://$serverEndpoint/game/";
  static String get graphqlUrl => "$wsUrl/graphql";
}

List<Map<String, String>> timeControls = [
  {"key": "1 phút", "value": "1+0"},
  {"key": "1 | 1", "value": "1+1"},
  {"key": "1 | 2", "value": "1+2"},
  {"key": "2 | 1", "value": "2+1"},
  {"key": "2 | 2", "value": "2+2"},
  {"key": "3 phút", "value": "3+0"},
  {"key": "3 | 2", "value": "3+2"},
  {"key": "5 phút", "value": "5+0"},
  {"key": "5 | 3", "value": "5+3"},
  {"key": "5 | 5", "value": "5+5"},
  {"key": "10 phút", "value": "10+0"},
  {"key": "10 | 5", "value": "10+5"},
  {"key": "15 | 10", "value": "15+10"},
  {"key": "25 | 10", "value": "25+10"},
  {"key": "30 phút", "value": "30+0"},
  {"key": "45 | 15", "value": "45+15"},
  {"key": "60 | 30", "value": "60+30"},
];
