import 'package:hive/hive.dart';

part 'matchresults_model.g.dart';

@HiveType(typeId: 8)
class MatchResultsModel {
  @HiveField(0)
  final List<MatchResultItem> items;

  MatchResultsModel({required this.items});

  factory MatchResultsModel.fromJson(Map<String, dynamic> json) {
    return MatchResultsModel(
      items: (json['items'] as List)
          .map((item) => MatchResultItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

@HiveType(typeId: 7)
class MatchResultItem {
  @HiveField(0)
  final String userId;

  @HiveField(1)
  final String matchId;

  @HiveField(2)
  final String opponentId;

  @HiveField(3)
  final double opponentRating;

  @HiveField(4)
  final double result;

  @HiveField(5)
  final String timestamp;

  MatchResultItem({
    required this.userId,
    required this.matchId,
    required this.opponentId,
    required this.opponentRating,
    required this.result,
    required this.timestamp,
  });

  factory MatchResultItem.fromJson(Map<String, dynamic> json) {
    return MatchResultItem(
      userId: json['userId'] as String,
      matchId: json['matchId'] as String,
      opponentId: json['opponentId'] as String,
      opponentRating: (json['opponentRating'] as num).toDouble(),
      result: (json['result'] as num).toDouble(),
      timestamp: json['timestamp'] as String,
    );
  }
}
