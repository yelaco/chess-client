class FriendshipModel {
  final List<FriendshipItem> items;
  final String? nextPageToken;

  FriendshipModel({
    required this.items,
    this.nextPageToken,
  });

  factory FriendshipModel.fromJson(Map<String, dynamic> json) {
    return FriendshipModel(
      items: (json['items'] as List<dynamic>)
          .map((item) => FriendshipItem.fromJson(item))
          .toList(),
      nextPageToken: json['nextPageToken'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'nextPageToken': nextPageToken,
    };
  }
}

class FriendshipItem {
  final String userId;
  final String friendId;
  final String conversationId;
  final DateTime startedAt;

  FriendshipItem({
    required this.userId,
    required this.friendId,
    required this.conversationId,
    required this.startedAt,
  });

  factory FriendshipItem.fromJson(Map<String, dynamic> json) {
    return FriendshipItem(
      userId: json['userId'] as String,
      friendId: json['friendId'] as String,
      conversationId: json['conversationId'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'friendId': friendId,
      'conversationId': conversationId,
      'startedAt': startedAt.toIso8601String(),
    };
  }
}

class FriendshipRequestModel {
  final List<FriendshipRequestItem> items;
  final String? nextPageToken;

  FriendshipRequestModel({
    required this.items,
    this.nextPageToken,
  });

  factory FriendshipRequestModel.fromJson(Map<String, dynamic> json) {
    return FriendshipRequestModel(
      items: (json['items'] as List<dynamic>)
          .map((item) => FriendshipRequestItem.fromJson(item))
          .toList(),
      nextPageToken: json['nextPageToken'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'nextPageToken': nextPageToken,
    };
  }
}

class FriendshipRequestItem {
  final String senderId;
  final String receiverId;
  final DateTime createdAt;

  FriendshipRequestItem({
    required this.senderId,
    required this.receiverId,
    required this.createdAt,
  });

  factory FriendshipRequestItem.fromJson(Map<String, dynamic> json) {
    return FriendshipRequestItem(
      senderId: json['senderId'] as String,
      receiverId: json['receiverId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
