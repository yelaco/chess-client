class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderUsername;
  final String content;
  final String createdAt;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderUsername,
    required this.content,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['Id'],      
      conversationId: json['ConversationId'],
      senderId: json['SenderId'],
      senderUsername: json['Username'],
      content: json['Content'],
      createdAt: json['CreatedAt'],
    );
  }
}
