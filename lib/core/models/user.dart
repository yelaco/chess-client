import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 2)
enum Membership {
  @HiveField(0)
  guest,
  @HiveField(1)
  premium
}

@HiveType(typeId: 3)
class UserModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String username;

  @HiveField(2)
  String locate;

  @HiveField(3)
  String picture;

  @HiveField(4)
  double rating;

  @HiveField(5)
  Membership membership;

  @HiveField(6)
  DateTime createAt;

  UserModel({
    required this.id,
    required this.username,
    this.locate = "",
    this.picture = "",
    this.rating = 0,
    this.membership = Membership.guest,
    DateTime? createAt,
  }) : createAt = createAt ?? DateTime.now().toUtc();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      locate: json['locale'] ?? '',
      picture: json['avatar'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      membership: Membership.values.byName(json['membership']),
      createAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'locale': locate,
      'picture': picture,
      'rating': rating,
      'membership': membership.name.toLowerCase(),
      'createdAt': createAt.toIso8601String(),
    };
  }
}
