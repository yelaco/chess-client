import 'package:flutter/material.dart';

import 'package:chess/chess.dart' as chess;
import 'package:flutter_slchess/core/models/match_model.dart';
import 'package:flutter_slchess/core/models/gamestate_model.dart';
import 'package:flutter_slchess/core/models/moveset_model.dart';
import 'package:flutter_slchess/core/services/match_ws_service.dart';
import 'package:flutter_slchess/core/services/amplify_auth_service.dart';
import 'package:flutter_slchess/core/services/moveset_service.dart';
import 'package:flutter_slchess/core/services/message_service.dart';
import 'package:flutter_slchess/core/models/message_model.dart';
import 'package:flutter_slchess/core/models/user.dart';

import 'dart:async';
import 'dart:math' as math;

class Chessboard extends StatefulWidget {
  final MatchModel matchModel;
  final bool isOnline;
  final bool isWhite;
  final bool enableSwitchBoard;

  const Chessboard(
      {super.key,
      required this.matchModel,
      required this.isOnline,
      required this.isWhite,
      this.enableSwitchBoard = false});

  @override
  State<Chessboard> createState() => _ChessboardState();
}

class _ChessboardState extends State<Chessboard> {
  // Game state
  chess.Chess game = chess.Chess();
  // List<String> listFen = [];
  MoveSet? moveSet;

  late UserModel currentUser;

  int halfmove = 0;
  late List<List<String?>> board;
  late String fen;
  bool isWhiteTurn = true;
  bool isPaused = false;
  String? lastMoveFrom;
  String? lastMoveTo;

  // Time control
  late String timeControl;
  late int timeIncrement;
  late int whiteTime;
  late int blackTime;
  late DateTime lastUpdate;
  Timer? timer;
  late Stopwatch _stopwatch;

  // Move validation
  Set<String> validSquares = {};
  List<chess.Move> validMoves = [];
  String? selectedSquare;

  // UI control
  late ScrollController _scrollController;
  late bool isOnline;
  late String server;
  bool enableFlip = true;
  late bool isWhite;
  bool _isChatVisible = false;

  // Chat
  final TextEditingController _chatController = TextEditingController();
  final List<ChatMessage> _chatMessages = [];
  final ScrollController _chatScrollController = ScrollController();
  late MessageService _messageService;
  bool _isChatConnected = false;

  // Websocket and services
  late MatchWebsocketService matchService;
  late MatchModel matchModel;
  late MoveSetService moveSetService;
  final AmplifyAuthService _amplifyAuthService = AmplifyAuthService();

  String? storedIdToken;

  @override
  void initState() {
    super.initState();
    _initializeGameState();
    _initializeTimeControl();

    if (isOnline) {
      _initializeOnlineGame();
    } else {
      _initializeOfflineGame();
    }

    _initializeUIControls();
    _startClock();

    // Thêm tin nhắn demo nếu đang chơi online
    if (isOnline) {
      _addWelcomeMessage();
    }
  }

  // Thêm một số tin nhắn demo để minh họa
  void _addWelcomeMessage() {
    _chatMessages.add(
      ChatMessage(
        sender: "",
        message: 'Chúc một ván đấu vui vẻ!',
        time: DateTime.now().subtract(const Duration(minutes: 2)),
        isCurrentUser: false,
      ),
    );
  }

  Future<void> _initializeGameState() async {
    matchModel = widget.matchModel;
    isWhite = widget.isWhite;
    isOnline = widget.isOnline;
    server = matchModel.server;

    storedIdToken = await _amplifyAuthService.getIdToken();

    moveSetService = MoveSetService();
    await moveSetService.init();

    if (storedIdToken != null) {
      moveSet = await moveSetService.getGameMoves(
          widget.matchModel.matchId, storedIdToken!, isOnline);

      print("moveSet: ${moveSet!.toJson()}");

      // Nếu moveset đã có nước đi, cập nhật game state đến trạng thái hiện tại
      if (moveSet != null && moveSet!.moves.isNotEmpty) {
        // Load từng nước đi vào game để cập nhật lịch sử
        for (var moveItem in moveSet!.moves) {
          String move = moveItem.move;
          if (move.length >= 4) {
            String from = move.substring(0, 2);
            String to = move.substring(2, 4);
            String promotion = move.length > 4 ? move[4] : '';

            game.move({
              'from': from,
              'to': to,
              'promotion': promotion.isEmpty ? null : promotion,
            });
          }
        }

        // Load FEN cuối cùng vào game
        fen = moveSet!.moves.last.fen;
        game.load(fen);
        board = parseFEN(fen);

        // Cập nhật lastMove
        lastMoveFrom = moveSet!.moves.last.move.substring(0, 2);
        lastMoveTo = moveSet!.moves.last.move.substring(2, 4);

        // Cập nhật halfmove
        halfmove = moveSet!.moves.length - 1;

        // Cập nhật lượt đi
        isWhiteTurn = game.turn.name == "WHITE";
      }
    }
  }

  void _initializeTimeControl() {
    timeControl = matchModel.gameMode.split("+")[0];
    timeIncrement = int.parse(matchModel.gameMode.split("+")[1]);
    whiteTime = int.parse(timeControl) * 60 * 1000;
    blackTime = whiteTime;
  }

  void _initializeUIControls() {
    _stopwatch = Stopwatch();
    _scrollController = ScrollController();
    _scrollToBottomAfterBuild();
  }

  void _startClock() {
    _stopwatch.start();
    timer = Timer.periodic(const Duration(milliseconds: 100), _updateClock);
  }

  void _updateClock(Timer t) {
    if (!_stopwatch.isRunning) return;

    final elapsed = _stopwatch.elapsedMilliseconds;
    _stopwatch.reset();
    _stopwatch.start();

    setState(() {
      if (isWhiteTurn) {
        if (halfmove > 0 || isOnline) {
          whiteTime -= elapsed;
          if (whiteTime <= 0) {
            whiteTime = 0;
            t.cancel();
            showGameEndDialog(context, "White loss", "onTime");
          }
        }
      } else {
        blackTime -= elapsed;
        if (blackTime <= 0) {
          blackTime = 0;
          t.cancel();
          showGameEndDialog(context, "Black loss", "onTime");
        }
      }
    });
  }

  Future<void> _initializeOfflineGame() async {
    board = parseFEN(game.fen);
  }

  Future<void> _initializeOnlineGame() async {
    try {
      board =
          parseFEN('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1');
      storedIdToken = await _amplifyAuthService.getIdToken();
      currentUser = isWhite ? matchModel.player1.user : matchModel.player2.user;

      // Thêm xử lý lỗi khi khởi tạo WebSocket
      try {
        matchService = MatchWebsocketService.startGame(
            matchModel.matchId, storedIdToken!, server);

        matchService.listen(
          onGameState: _handleGameStateUpdate,
          onEndgame: _handleGameEnd,
          onStatusChange: _handleStatusChange,
          context: context,
        );
      } catch (e) {
        print("Lỗi kết nối WebSocket: $e");
        // Hiển thị thông báo lỗi cho người dùng
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Không thể kết nối đến máy chủ. Vui lòng thử lại sau.'),
            ),
          );
        }
        return;
      }

      // Khởi tạo MessageService cho chat
      _messageService = MessageService.startMessage(
          matchModel.conversationId, storedIdToken!);
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
      print(matchModel.conversationId);
      // Tham gia vào conversation
      _messageService.joinConversation(
        conversationId: matchModel.conversationId,
        idToken: storedIdToken!,
      );
    } catch (e) {
      print("Lỗi khởi tạo game online: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Có lỗi xảy ra khi khởi tạo game. Vui lòng thử lại sau.'),
          ),
        );
      }
    }
  }

  void _handleGameStateUpdate(GameState gameState) {
    setState(() {
      if (moveSet != null) {
        fen = gameState.fen;

        // Kiểm tra xem nước đi này đã tồn tại chưa
        if ((moveSet!.moves.isEmpty || moveSet!.moves.last.fen != fen) &&
            fen != MoveSetService.initFen) {
          // Lấy nước đi từ FEN trước đó
          String lastFen = moveSet!.moves.isEmpty
              ? MoveSetService.initFen
              : moveSet!.moves.last.fen;
          chess.Move move = moveSetService.getMoveFromFenDiff(lastFen, fen);
          String moveString = move.fromAlgebraic + move.toAlgebraic;

          // Kiểm tra xem nước đi này đã tồn tại trong moveset chưa
          bool moveExists =
              moveSet!.moves.any((m) => m.move == moveString && m.fen == fen);

          if (!moveExists) {
            bool success = game.move(move);
            if (success) {
              board = parseFEN(game.fen);
              // Thêm nước đi mới vào moveset
              moveSet!.moves.add(MoveItem(move: moveString, fen: fen));
              moveSetService.addMove(matchModel.matchId, fen, moveString);

              // Cập nhật lastMove
              if (moveString.length >= 4) {
                lastMoveFrom = moveString.substring(0, 2);
                lastMoveTo = moveString.substring(2, 4);
              }
            } else {
              print("move failed: $move");
            }
          }
        }

        // Cập nhật halfmove
        halfmove = (moveSet?.moves.length ?? 1) - 1;
      }

      // Cập nhật thời gian và lượt đi
      whiteTime = gameState.clocks[0];
      blackTime = gameState.clocks[1];
      isWhiteTurn = game.turn.name == "WHITE";
    });
  }

  void _handleGameEnd(GameState gameState) {
    if (!mounted) return;
    final winner = gameState.outcome == "1-0"
        ? "WHITE"
        : gameState.outcome == "0-1"
            ? "BLACK"
            : null;
    showGameEndDialog(context, "$winner WON", gameState.method ?? "Unknown");
  }

  void _handleStatusChange() {
    // Cập nhật UI khi trạng thái người chơi thay đổi
    setState(() {});
  }

  void _scrollToBottomAfterBuild() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _scrollChatToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void switchTurn() {
    _stopwatch.reset();
    _stopwatch.start();
    setState(() {
      isWhiteTurn = !isWhiteTurn;
    });
  }

  // Gửi tin nhắn chat
  void _sendMessage() {
    if (_chatController.text.trim().isEmpty) return;

    final message = _chatController.text.trim();
    _chatController.clear();

    _messageService
        .sendMessage(
      conversationId: matchModel.conversationId,
      senderId: currentUser.id,
      content: message,
      senderUsername: currentUser.username,
      idToken: storedIdToken!,
    )
        .then((sentMessage) {
      if (sentMessage != null) {
        setState(() {
          _chatMessages.add(
            ChatMessage(
              sender: sentMessage.senderUsername,
              message: sentMessage.content,
              time: DateTime.parse(sentMessage.createdAt),
              isCurrentUser: true,
            ),
          );
        });
        _scrollChatToBottom();
      }
    });
  }

  // Chuyển đổi hiển thị chat
  void _toggleChat() {
    setState(() {
      _isChatVisible = !_isChatVisible;
    });

    if (_isChatVisible) {
      _scrollChatToBottom();
    }
  }

  void _handleNewMessage(Message message) {
    if (!mounted) return;
    if (message.senderId != currentUser.id) {
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
  }

  @override
  void dispose() {
    timer?.cancel();
    _stopwatch.stop();
    _scrollController.dispose();
    _chatScrollController.dispose();
    _chatController.dispose();
    if (isOnline) {
      _messageService.leaveConversation(conversationId: matchModel.matchId);
      _messageService.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg_dark.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                if (!isOnline) gameHistory(game),
                _buildPlayerPanel(!isWhite),
                handleChessBoard(),
                _buildPlayerPanel(isWhite),
              ],
            ),
            if (_isChatVisible) _buildChatOverlay(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomAppBar(),
    );
  }

  Widget _buildChatOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Column(
          children: [
            Container(
              color: const Color(0xFF0E1416),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Text(
                    'Trò chuyện',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: _toggleChat,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _chatScrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _chatMessages.length,
                itemBuilder: (context, index) {
                  final message = _chatMessages[index];
                  return _buildChatMessage(message);
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              color: const Color(0xFF1A1B1A),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade800,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
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
      ),
    );
  }

  Widget _buildChatMessage(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isCurrentUser
                    ? Colors.blue.shade700
                    : Colors.grey.shade800,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!message.isCurrentUser)
                    Text(
                      message.sender,
                      style: TextStyle(
                        color: Colors.blue.shade300,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    message.message,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.time),
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        '${isOnline ? "Online" : "Offline"} Chess Games',
        style: const TextStyle(
            fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      backgroundColor: const Color(0xFF0E1416),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => _showConfirmationDialog(context),
      ),
    );
  }

  Widget _buildPlayerPanel(bool isCurrentPlayer) {
    final player =
        isCurrentPlayer ? matchModel.player1.user : matchModel.player2.user;

    final playerName = player.username;
    final time = formatTime(isCurrentPlayer ? whiteTime : blackTime);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: const BoxDecoration(
          color: Colors.black87,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: player.picture.isNotEmpty
                      ? NetworkImage("${player.picture}/large")
                      : const AssetImage('assets/default_avt.jpg')
                          as ImageProvider,
                  backgroundColor: Colors.grey[300],
                ),
                const SizedBox(width: 8),
                Text(
                  playerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer, size: 16, color: Colors.white),
                  const SizedBox(width: 5),
                  Text(
                    time,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  BottomAppBar _buildBottomAppBar() {
    return BottomAppBar(
      color: const Color(0xFF282F33),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: _bottomAppBarBtn(
              "Tùy chọn",
              () => _showOptionsMenu(context),
              icon: Icons.storage,
            ),
          ),
          if (isOnline)
            Expanded(
              child: _bottomAppBarBtn(
                "Chat",
                _toggleChat,
                icon: Icons.chat,
              ),
            ),
          if (!isOnline) ...[
            Expanded(
              child: _bottomAppBarBtn(
                isPaused ? "Tiếp tục" : "Tạm dừng",
                _togglePause,
                icon: isPaused ? Icons.play_arrow : Icons.pause,
              ),
            ),
            Expanded(
              child: _bottomAppBarBtn(
                "Quay lại",
                _moveBackward,
                icon: Icons.arrow_back_ios_new,
              ),
            ),
            Expanded(
              child: _bottomAppBarBtn(
                "Tiếp",
                _moveForward,
                icon: Icons.arrow_forward_ios,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _togglePause() {
    setState(() {
      if (isPaused) {
        _stopwatch.start();
      } else {
        _stopwatch.stop();
      }
      isPaused = !isPaused;
    });
  }

  void _moveBackward() {
    if (moveSet != null && moveSet!.moves.length > 1) {
      setState(() {
        if (halfmove > 0) {
          halfmove--;
        }

        fen = moveSet!.moves[halfmove].fen;
        lastMoveFrom = moveSet!.moves[halfmove].move.substring(0, 2);
        lastMoveTo = moveSet!.moves[halfmove].move.substring(2, 4);
        board = parseFEN(fen);
        scrollToIndex(halfmove);
      });
    }
  }

  void _moveForward() {
    if (moveSet != null && moveSet!.moves.length > 1) {
      setState(() {
        if (halfmove < moveSet!.moves.length - 1) {
          halfmove++;
        }
        fen = moveSet!.moves[halfmove].fen;
        lastMoveFrom = moveSet!.moves[halfmove].move.substring(0, 2);
        lastMoveTo = moveSet!.moves[halfmove].move.substring(2, 4);
        board = parseFEN(fen);
        scrollToIndex(halfmove);
      });
    }
  }

  Widget handleChessBoard() {
    return Stack(
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: 1,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                childAspectRatio: 1.0,
              ),
              itemCount: 64,
              itemBuilder: (context, index) => _buildChessSquare(index),
            ),
          ),
        ),
        _buildRankCoordinates(),
        _buildFileCoordinates(),
      ],
    );
  }

  Widget _buildChessSquare(int index) {
    int transformedIndex = enableFlip && !isWhite ? 63 - index : index;
    int row = transformedIndex ~/ 8;
    int col = transformedIndex % 8;
    String coor = parsePieceCoordinate(col, row);
    bool isValidSquare = validSquares.contains(coor);
    bool isLastMoveFrom = coor == lastMoveFrom;
    bool isLastMoveTo = coor == lastMoveTo;
    String? piece = board[row][col];

    return DragTarget<String>(
      onWillAcceptWithDetails: (data) => isValidSquare,
      onAcceptWithDetails: (data) => _handleMove(coor),
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          onTap: () => _handleMove(coor),
          child: Container(
            decoration: BoxDecoration(
              color: (row + col) % 2 == 0
                  ? const Color(0xFFEEEED2) // Màu ô trắng
                  : const Color(0xFF769656), // Màu ô xanh
              border: Border.all(
                color: isValidSquare
                    ? Colors.green
                    : isLastMoveFrom || isLastMoveTo
                        ? Colors.blueAccent
                        : Colors.transparent,
                width: isValidSquare || isLastMoveFrom || isLastMoveTo ? 2 : 0,
              ),
              boxShadow: isLastMoveTo
                  ? [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 2,
                      )
                    ]
                  : null,
            ),
            child: Center(
              child: _buildDraggablePiece(piece, coor),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRankCoordinates() {
    return Positioned.fill(
      child: Column(
        children: List.generate(8, (row) {
          return Expanded(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 2, top: 2),
                child: Text(
                  isWhite ? "${8 - row}" : "${row + 1}",
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: (row % 2 == 0) ? Colors.grey : Colors.white,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFileCoordinates() {
    return Positioned.fill(
      child: Row(
        children: List.generate(8, (col) {
          return Expanded(
            child: Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 2, right: 2),
                child: Text(
                  isWhite
                      ? String.fromCharCode(97 + col)
                      : String.fromCharCode(104 - col),
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: (col % 2 == 0) ? Colors.white : Colors.grey,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDraggablePiece(String? piece, String coor) {
    if (piece == null) return const SizedBox.shrink();

    final canDrag = (isWhiteTurn == isWhite || !isOnline) &&
        !isPaused &&
        (piece.toUpperCase() == piece) == isWhiteTurn;

    if (!canDrag) {
      return Image.asset(
        getPieceAsset(piece),
        fit: BoxFit.contain,
      );
    }

    return Draggable<String>(
      data: coor,
      feedback: Image.asset(
        getPieceAsset(piece),
        colorBlendMode: BlendMode.modulate,
      ),
      childWhenDragging: const SizedBox.shrink(),
      onDragStarted: () {
        setState(() {
          selectedSquare = coor;
          validMoves = _genMove(coor, game);
          validSquares = _toSanMove(validMoves).toSet();
        });
      },
      onDragEnd: (details) {
        if (!details.wasAccepted) {
          setState(() {
            selectedSquare = null;
            validSquares = {};
          });
        }
      },
      child: Image.asset(
        getPieceAsset(piece),
        fit: BoxFit.contain,
      ),
    );
  }

  void _handleMove(String coor) {
    // Kiểm tra các điều kiện khi di chuyển
    if (whiteTime <= 0 || blackTime <= 0) {
      return;
    }

    if (isOnline && isWhiteTurn != isWhite) {
      return;
    }

    // if (halfmove != moveSet!.moves.length - 1 || !isOnline) {
    //   return;
    // }

    setState(() {
      if (selectedSquare == null || !validSquares.contains(coor)) {
        // Chọn quân cờ
        selectedSquare = coor;
        validMoves = _genMove(coor, game);
        validSquares = _toSanMove(validMoves).toSet();
      } else if (validSquares.contains(coor)) {
        // Di chuyển quân cờ
        _processMove(coor);
      } else {
        // Reset selection
        selectedSquare = null;
        validSquares = {};
      }
    });
  }

  void _processMove(String coor) {
    chess.Move move = validMoves.firstWhere(
        (m) => m.fromAlgebraic == selectedSquare && m.toAlgebraic == coor);

    // Kiểm tra nếu là nước đi phong cấp (promotion)
    if (_isPromotion(move)) {
      _showPromotionDialog(move, coor);
      return;
    }

    _executeMove(move, coor);
  }

  // Kiểm tra xem nước đi có phải là phong cấp không
  bool _isPromotion(chess.Move move) {
    String? piece = move.piece.toLowerCase();
    String to = move.toAlgebraic;
    int rank = int.parse(to[1]);

    // Tốt trắng đến hàng 8 hoặc tốt đen đến hàng 1
    return piece == 'p' &&
        ((move.color.name == 'WHITE' && rank == 8) ||
            (move.color.name == 'BLACK' && rank == 1));
  }

  // Hiển thị dialog chọn quân cờ cho phong cấp
  void _showPromotionDialog(chess.Move move, String coor) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Chọn quân cờ phong cấp'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPromotionChoice(
                  context, move, coor, move.color.name == 'WHITE' ? 'Q' : 'q'),
              _buildPromotionChoice(
                  context, move, coor, move.color.name == 'WHITE' ? 'R' : 'r'),
              _buildPromotionChoice(
                  context, move, coor, move.color.name == 'WHITE' ? 'B' : 'b'),
              _buildPromotionChoice(
                  context, move, coor, move.color.name == 'WHITE' ? 'N' : 'n'),
            ],
          ),
        );
      },
    );
  }

  // Xây dựng widget cho từng lựa chọn phong cấp
  Widget _buildPromotionChoice(BuildContext context, chess.Move move,
      String coor, String promotionPiece) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();

        // Tạo chuỗi nước đi với thông tin phong cấp (ví dụ: e7e8q)
        String moveString =
            "${move.fromAlgebraic}${move.toAlgebraic}${promotionPiece.toLowerCase()}";

        print("moveString: $moveString");
        // Thực hiện nước đi
        game.move({
          'from': move.fromAlgebraic,
          'to': move.toAlgebraic,
          'promotion': promotionPiece.toLowerCase(),
        });

        setState(() {
          fen = game.fen;
          if (moveSet != null) {
            moveSet!.moves.add(MoveItem(
                move: move.fromAlgebraic + move.toAlgebraic, fen: fen));

            moveSetService.addMove(widget.matchModel.matchId, fen, moveString);
          }
          board = parseFEN(fen);

          // Lưu thông tin nước đi gần nhất
          lastMoveFrom = move.fromAlgebraic;
          lastMoveTo = move.toAlgebraic;

          // Tăng thời gian sau khi di chuyển
          if (isWhiteTurn) {
            whiteTime += timeIncrement * 1000;
          } else {
            blackTime += timeIncrement * 1000;
          }

          _scrollToBottomAfterBuild();
          halfmove = (moveSet?.moves.length ?? 1) - 1;

          // Gửi nước đi đến server nếu đang chơi online
          if (isOnline) {
            matchService.makeMove(moveString);
          }

          // Đổi lượt
          isWhiteTurn = !isWhiteTurn;

          if (enableFlip && !isOnline) {
            isWhite = !isWhite;
          }

          // Kiểm tra kết thúc ván đấu
          _checkGameEnd();
        });

        // Reset trạng thái lựa chọn
        selectedSquare = null;
        validSquares = {};
      },
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.all(4),
        child: Image.asset(
          getPieceAsset(promotionPiece),
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  // Thực hiện nước đi (đã được tách từ _processMove)
  void _executeMove(chess.Move move, String coor) {
    bool success = game.move(move);
    if (success) {
      fen = game.fen;
      if (moveSet != null) {
        moveSet!.moves.add(
            MoveItem(move: move.fromAlgebraic + move.toAlgebraic, fen: fen));
        moveSetService.addMove(widget.matchModel.matchId, fen,
            move.fromAlgebraic + move.toAlgebraic);
      }
      board = parseFEN(fen);

      // Lưu thông tin nước đi gần nhất
      lastMoveFrom = selectedSquare;
      lastMoveTo = coor;

      // Tăng thời gian sau khi di chuyển
      if (isWhiteTurn) {
        whiteTime += timeIncrement * 1000;
      } else {
        blackTime += timeIncrement * 1000;
      }

      _scrollToBottomAfterBuild();
      halfmove = (moveSet?.moves.length ?? 1) - 1;

      String sanMove = move.fromAlgebraic + move.toAlgebraic;
      // Thêm thông tin phong cấp nếu có
      if (move.promotion != null) {
        sanMove += move.promotion!.toLowerCase();
      }

      if (isOnline) {
        matchService.makeMove(sanMove);
      }

      // Đổi lượt
      isWhiteTurn = !isWhiteTurn;

      if (enableFlip && !isOnline) {
        isWhite = !isWhite;
      }

      // Kiểm tra kết thúc ván đấu
      _checkGameEnd();
    }

    // Reset trạng thái lựa chọn
    selectedSquare = null;
    validSquares = {};
  }

  void _checkGameEnd() {
    if (game.game_over) {
      var turnColor = game.turn.name;

      if (game.in_checkmate) {
        showGameEndDialog(context,
            "${turnColor == 'WHITE' ? 'BLACK' : 'WHITE'} WON", "CHECKMATE");
      } else if (game.in_draw) {
        String resultStr;

        if (game.in_stalemate) {
          resultStr = "Stalemate";
        } else if (game.in_threefold_repetition) {
          resultStr = "Repetition";
        } else if (game.insufficient_material) {
          resultStr = "Insufficient material";
        } else {
          resultStr = "Draw";
        }

        showGameEndDialog(context, "Draw", resultStr);
      }

      // Xóa cache moveset khi kết thúc ván đấu
      if (moveSet != null) {
        moveSetService.deleteGame(matchModel.matchId);
        moveSet = null;
      }
    }
  }

  String getPieceAsset(String piece) {
    switch (piece) {
      case 'r':
        return 'assets/pieces/Chess_rdt60.png';
      case 'n':
        return 'assets/pieces/Chess_ndt60.png';
      case 'b':
        return 'assets/pieces/Chess_bdt60.png';
      case 'q':
        return 'assets/pieces/Chess_qdt60.png';
      case 'k':
        return 'assets/pieces/Chess_kdt60.png';
      case 'p':
        return 'assets/pieces/Chess_pdt60.png';
      case 'R':
        return 'assets/pieces/Chess_rlt60.png';
      case 'N':
        return 'assets/pieces/Chess_nlt60.png';
      case 'B':
        return 'assets/pieces/Chess_blt60.png';
      case 'Q':
        return 'assets/pieces/Chess_qlt60.png';
      case 'K':
        return 'assets/pieces/Chess_klt60.png';
      case 'P':
        return 'assets/pieces/Chess_plt60.png';
      default:
        return '';
    }
  }

  Widget gameHistory(chess.Chess game) {
    var moves = game.getHistory();
    if (moves.isEmpty) {
      return const SizedBox.shrink();
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxHeight: 22, // giới hạn cao nhất thôi
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        controller: _scrollController,
        itemCount: moves.length,
        itemBuilder: (context, index) {
          final move = moves[index];
          return Container(
            margin: const EdgeInsets.only(left: 8),
            child: InkWell(
                onTap: () {
                  setState(() {
                    halfmove = index;
                    // Sử dụng moveSet để cập nhật game state
                    if (moveSet != null && moveSet!.moves.length > index) {
                      fen = moveSet!.moves[halfmove].fen;
                      lastMoveFrom =
                          moveSet!.moves[halfmove].move.substring(0, 2);
                      lastMoveTo =
                          moveSet!.moves[halfmove].move.substring(2, 4);
                      board = parseFEN(fen);
                      // Cập nhật game state
                      game.load(fen);
                    }
                  });
                },
                child: index % 2 == 0
                    ? Row(
                        children: [
                          Text(
                            "${(index / 2 + 1).toInt()}. ",
                            style: const TextStyle(color: Colors.white),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: index == halfmove
                                ? const BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      topRight: Radius.circular(8),
                                      bottomLeft: Radius.circular(2),
                                      bottomRight: Radius.circular(2),
                                    ),
                                  )
                                : const BoxDecoration(),
                            child: Text(
                              move.toString(),
                              style: TextStyle(
                                  color: index == halfmove
                                      ? Colors.black
                                      : Colors.white),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: index == halfmove
                                ? const BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      topRight: Radius.circular(8),
                                      bottomLeft: Radius.circular(2),
                                      bottomRight: Radius.circular(2),
                                    ),
                                  )
                                : const BoxDecoration(),
                            child: Text(
                              move.toString(),
                              style: TextStyle(
                                  color: index == halfmove
                                      ? Colors.black
                                      : Colors.white),
                            ),
                          ),
                        ],
                      )),
          );
        },
      ),
    );
  }

  void scrollToIndex(int index) {
    if (index >= 0 && index < (moveSet?.moves.length ?? 0)) {
      double position = index * 50.0;
      _scrollController.animateTo(
        position,
        duration: const Duration(milliseconds: 300),
        curve: Curves.linearToEaseOut,
      );
    }
  }

  String formatTime(int milliseconds) {
    int seconds = (milliseconds ~/ 1000);
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    int remainingMilliseconds = milliseconds % 1000;

    if (milliseconds < 10000) {
      return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')},${(remainingMilliseconds ~/ 100).toString()}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }
  }

  List<List<String?>> parseFEN(String fen) {
    List<List<String?>> board =
        List.generate(8, (_) => List<String?>.filled(8, null));
    List<String> rows = fen.split('/');

    if (rows.isNotEmpty && rows[0].contains(' ')) {
      rows[0] = rows[0].split(' ')[0];
    }

    for (int i = 0; i < math.min(8, rows.length); i++) {
      String row = rows[i];
      int col = 0;

      for (int j = 0; j < row.length; j++) {
        String char = row[j];

        if (RegExp(r'\d').hasMatch(char)) {
          int emptyCount = int.parse(char);
          col += emptyCount;
        } else {
          if (col < 8) {
            board[i][col] = char;
            col++;
          }
        }
      }
    }

    return board;
  }

  List<String> _toSanMove(List<chess.Move> moves) {
    return moves.map((move) => move.toAlgebraic).toList();
  }

  List<chess.Move> _genMove(String move, chess.Chess game) {
    return game.generate_moves({'square': move});
  }

  String parsePieceCoordinate(int col, int row) {
    const columns = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    row = 8 - row;
    return columns[col] + row.toString();
  }

  Widget _bottomAppBarBtn(String text, VoidCallback onPressed,
      {IconData? icon}) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null)
              Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isOnline) ...[
                _buildMenuItem(context, Icons.flag, "Chấp nhận thua", () {
                  Navigator.pop(context);
                  matchService.resign();
                }),
                _buildMenuItem(context, Icons.flag, "Hòa cờ", () {
                  Navigator.pop(context);
                  matchService.offerDraw();
                }),
              ],
              if (!isOnline)
                _buildMenuItem(context, Icons.sync_disabled,
                    "${enableFlip ? "Tắt" : "Bật"} chức năng xoay bàn cờ", () {
                  setState(() {
                    enableFlip = !enableFlip;
                  });
                  Navigator.pop(context);
                }),
              _buildMenuItem(context, Icons.copy, "Sao chép PGN", () {
                // TODO: Implement copy PGN
                Navigator.pop(context);
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(
      BuildContext context, IconData icon, String text, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, size: 28),
      title: Text(text, style: const TextStyle(fontSize: 16)),
      onTap: onTap,
    );
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Xác nhận"),
          content: const Text("Bạn có chắc chắn muốn hủy ván đấu không?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Không"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text("Có"),
            ),
          ],
        );
      },
    );
  }

  void showGameEndDialog(
      BuildContext context, String resultTitle, String resultContent) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 30),
                    Text(
                      resultTitle,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                Text(resultContent, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildButton(context, "Tái đấu", () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    }),
                    _buildButton(context, "Ván cờ mới", () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    }),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildButton(BuildContext context, String text, VoidCallback onPress) {
    return ElevatedButton(
      onPressed: onPress,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[300],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child:
          Text(text, style: const TextStyle(fontSize: 16, color: Colors.black)),
    );
  }
}

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
