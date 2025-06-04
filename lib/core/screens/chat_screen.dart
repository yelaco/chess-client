import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/message_service.dart';
import 'package:flutter_slchess/core/models/message_model.dart';
import '../services/amplify_auth_service.dart';
import '../widgets/widgets.dart';
import '../services/user_service.dart';

class ChatMessage {
  final String sender;
  final String message;
  final DateTime time;
  final bool isCurrentUser;

  ChatMessage({
    required this.sender,
    required this.message,
    required this.time,
    required this.isCurrentUser,
  });
}

class ChatScreen extends StatefulWidget {
  final UserModel friend;
  final String conversationId;

  const ChatScreen(
      {super.key, required this.friend, required this.conversationId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late MessageService _messageService;
  final AmplifyAuthService _authService = AmplifyAuthService();
  final UserService _userService = UserService();
  final List<ChatMessage> _chatMessages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  bool _isChatConnected = false;
  bool _isConnecting = true;
  String? storedIdToken;

  late String conversationId;
  late UserModel friend;
  late UserModel currentUser;

  @override
  void initState() {
    super.initState();
    conversationId = widget.conversationId;
    friend = widget.friend;

    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      final player = await _userService.getPlayer();
      if (player == null) {
        throw Exception('Không thể lấy thông tin người dùng');
      }
      currentUser = player;
      storedIdToken = await _authService.getIdToken();

      _messageService =
          MessageService.startMessage(conversationId, storedIdToken!);
      _messageService.listen(
        onMessage: _handleNewMessage,
        onStatusChange: () {
          if (mounted) {
            setState(() {
              _isChatConnected = !_isChatConnected;
            });
          }
        },
      );
      print("join conversation");
      print(conversationId);
      // Tham gia vào conversation
      _messageService.joinConversation(
        conversationId: conversationId,
        idToken: storedIdToken!,
      );

      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    } catch (e) {
      print('Lỗi khi khởi tạo chat: $e');
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Avatar(widget.friend.picture),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.friend.username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Rating: ${widget.friend.rating.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              // TODO: Show more options
            },
          ),
        ],
      ),
      body: _isConnecting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Đang kết nối...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                if (!_isChatConnected)
                  Container(
                    color: Colors.red.withOpacity(0.8),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: const Center(
                      child: Text(
                        'Mất kết nối',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      image: const DecorationImage(
                        image: AssetImage('assets/bg_dark.png'),
                        fit: BoxFit.cover,
                      ),
                      color: Colors.black.withOpacity(0.3),
                    ),
                    child: ListView.builder(
                      controller: _chatScrollController,
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: _chatMessages.length,
                      itemBuilder: (context, index) {
                        final message =
                            _chatMessages[_chatMessages.length - 1 - index];
                        return _buildMessageBubble(message);
                      },
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, -1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.attach_file, color: Colors.grey),
                        onPressed: () {
                          // TODO: Implement file attachment
                        },
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: _messageController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Nhập tin nhắn...',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: _sendMessage,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  void _scrollChatToBottom() {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          0, // Vì ListView đang reverse: true nên scroll tới 0 là cuộn xuống dưới
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleNewMessage(Message message) {
    if (!mounted) return;
    setState(() {
      _chatMessages.add(
        ChatMessage(
          sender: message.senderUsername,
          message: message.content,
          time: DateTime.parse(message.createdAt),
          isCurrentUser: message.senderId == currentUser.id,
        ),
      );
    });
    _scrollChatToBottom();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text.trim();
    _messageController.clear();

    _messageService
        .sendMessage(
      conversationId: conversationId,
      senderId: currentUser.id,
      content: message,
      senderUsername: currentUser.username,
      idToken: storedIdToken!,
    )
        .then((sentMessage) {
      if (sentMessage != null) {
        setState(() {
          // _chatMessages.add(
          //   ChatMessage(
          //     sender: sentMessage.senderUsername,
          //     message: sentMessage.content,
          //     time: DateTime.parse(sentMessage.createdAt),
          //     isCurrentUser: true,
          //   ),
          // );
        });
        _scrollChatToBottom();
      }
    });
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isCurrentUser) ...[
            Avatar(
              message.sender == currentUser.username
                  ? currentUser.picture
                  : widget.friend.picture,
              size: 32,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: message.isCurrentUser
                    ? Colors.blue
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(message.isCurrentUser ? 20 : 4),
                  bottomRight: Radius.circular(message.isCurrentUser ? 4 : 20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!message.isCurrentUser)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        message.sender,
                        style: TextStyle(
                          color: message.isCurrentUser
                              ? Colors.white
                              : Colors.blue[300],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Text(
                    message.message,
                    style: TextStyle(
                      color:
                          message.isCurrentUser ? Colors.white : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.time),
                    style: TextStyle(
                      color: message.isCurrentUser
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey[400],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isCurrentUser) ...[
            const SizedBox(width: 8),
            Avatar(
              message.sender == currentUser.username
                  ? currentUser.picture
                  : widget.friend.picture,
              size: 32,
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _chatScrollController.dispose();
    _messageController.dispose();
    _messageService.leaveConversation(conversationId: conversationId);
    _messageService.close();
    super.dispose();
  }
}
