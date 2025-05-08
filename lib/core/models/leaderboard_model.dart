import 'user.dart';

/// Model cho xếp hạng của người chơi
class LeaderboardEntry {
  final UserModel user;
  final int rank;
  final int games;
  final int wins;
  final int draws;
  final int losses;

  LeaderboardEntry({
    required this.user,
    required this.rank,
    required this.games,
    required this.wins,
    required this.draws,
    required this.losses,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      user: UserModel.fromJson(json['user']),
      rank: json['rank'] ?? 0,
      games: json['games'] ?? 0,
      wins: json['wins'] ?? 0,
      draws: json['draws'] ?? 0,
      losses: json['losses'] ?? 0,
    );
  }

  /// Tính tỷ lệ thắng
  double get winRate {
    if (games == 0) return 0;
    return wins / games * 100;
  }
}

/// Model cho bảng xếp hạng tổng thể
class LeaderboardModel {
  final List<LeaderboardEntry> entries;
  final int total;
  final int limit;
  final int offset;

  LeaderboardModel({
    required this.entries,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory LeaderboardModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> items = json['items'] ?? [];

    return LeaderboardModel(
      entries: items.map((item) => LeaderboardEntry.fromJson(item)).toList(),
      total: json['total'] ?? 0,
      limit: json['limit'] ?? 0,
      offset: json['offset'] ?? 0,
    );
  }
}
