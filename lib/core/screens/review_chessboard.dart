import 'package:flutter/material.dart';

import 'package:chess/chess.dart' as chess;
import 'package:flutter_slchess/core/models/match_model.dart';
import 'package:flutter_slchess/core/models/gamestate_model.dart';
import 'package:flutter_slchess/core/models/moveset_model.dart';
import 'package:flutter_slchess/core/models/historymatch_model.dart';
import 'package:flutter_slchess/core/services/match_ws_service.dart';
import 'package:flutter_slchess/core/services/amplify_auth_service.dart';
import 'package:flutter_slchess/core/services/moveset_service.dart';

import 'dart:async';
import 'dart:math' as math;

class ReviewChessboard extends StatefulWidget {
  final HistoryMatchModel historyMatch;

  const ReviewChessboard({
    super.key,
    required this.historyMatch,
  });

  @override
  State<ReviewChessboard> createState() => _ReviewChessboardState();
}

class _ReviewChessboardState extends State<ReviewChessboard> {
  chess.Chess game = chess.Chess();
  late List<Map<String, dynamic>> moves = [];

  int halfmove = 0;
  late List<List<String?>> board;
  late String fen;
  bool isWhiteTurn = true;
  bool isPaused = false;
  String? lastMoveFrom;
  String? lastMoveTo;

  // Time control
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

  // Websocket and services
  late MoveSetService moveSetService;
  final AmplifyAuthService _amplifyAuthService = AmplifyAuthService();

  String? storedIdToken;

  @override
  void initState() {
    super.initState();
    _initializeHistoryGame();
    _initializeTimeControl();
    _initializeUIControls();
  }

  void _initializeHistoryGame() {
    board = parseFEN(widget.historyMatch.items.last.gameState);
    fen = widget.historyMatch.items.last.gameState;
    lastMoveFrom = widget.historyMatch.items.last.move.uci.substring(0, 2);
    lastMoveTo = widget.historyMatch.items.last.move.uci.substring(2, 4);
    whiteTime = parseTime(widget.historyMatch.items[0].playerStates[0].clock);
    blackTime = parseTime(widget.historyMatch.items[0].playerStates[1].clock);

    for (var i = widget.historyMatch.items.length - 1; i >= 0; i--) {
      print(widget.historyMatch.items[i].move.uci);
      final item = widget.historyMatch.items[i];
      final from = item.move.uci.substring(0, 2);
      final to = item.move.uci.substring(2, 4);
      if (item.move.uci.length > 4) {
        final promotion = item.move.uci.substring(4, 5);
        game.move({'from': from, 'to': to, 'promotion': promotion});
      } else {
        game.move({'from': from, 'to': to});
      }
    }

    moves.clear();
    int moveIndex = 0;
    for (var move in game.getHistory()) {
      if (moveIndex < widget.historyMatch.items.length) {
        int itemIndex = widget.historyMatch.items.length - 1 - moveIndex;
        moves.add({
          'move': move,
          'uci': widget.historyMatch.items[itemIndex].move.uci,
          'fen': widget.historyMatch.items[itemIndex].gameState,
          'whiteTime': parseTime(
              widget.historyMatch.items[itemIndex].playerStates[0].clock),
          'blackTime': parseTime(
              widget.historyMatch.items[itemIndex].playerStates[1].clock)
        });
        moveIndex++;
      }
    }
  }

  void _initializeTimeControl() {
    // timeControl = widget.historyMatch.items[0].gameMode.split("+")[0];
    // timeIncrement = int.parse(widget.historyMatch.items[0].gameMode.split("+")[1]);
    // whiteTime = int.parse(timeControl) * 60 * 1000;
    // blackTime = whiteTime;
  }

  void _initializeUIControls() {
    _stopwatch = Stopwatch();
    _scrollController = ScrollController();
    _scrollToBottomAfterBuild();
  }

  void _handleGameEnd(GameState gameState) {
    final winner = gameState.outcome == "1-0"
        ? "WHITE"
        : gameState.outcome == "0-1"
            ? "BLACK"
            : null;
    showGameEndDialog(context, "$winner WON", gameState.method ?? "Unknown");
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

  @override
  void dispose() {
    timer?.cancel();
    _stopwatch.stop();
    _scrollController.dispose();
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
        child: Column(
          children: [
            gameHistory(game),
            _buildPlayerPanel("Black", blackTime),
            handleChessBoard(),
            _buildPlayerPanel("White", whiteTime),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomAppBar(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(
        'Review Chess Games',
        style: TextStyle(
            fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      backgroundColor: const Color(0xFF0E1416),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  Widget _buildPlayerPanel(String playerName, int time) {
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: Image.asset(
                    'assets/default_avt.jpg',
                    fit: BoxFit.cover,
                    width: 30,
                    height: 30,
                  ),
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
                    formatTime(time),
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
    if (moves.isNotEmpty && halfmove > 0) {
      setState(() {
        halfmove--;

        fen = moves[halfmove]['fen'];
        // Lấy move từ mảng moves
        final moveString = moves[halfmove]['uci'];
        // Phân tích move để lấy from và to
        if (moveString.length >= 4) {
          lastMoveFrom = moveString.substring(0, 2);
          lastMoveTo = moveString.substring(2, 4);
        }
        board = parseFEN(fen);
        whiteTime = moves[halfmove]['whiteTime'];
        blackTime = moves[halfmove]['blackTime'];
        scrollToIndex(halfmove);
      });
    }
  }

  void _moveForward() {
    if (moves.isNotEmpty && halfmove < moves.length - 1) {
      setState(() {
        halfmove++;

        fen = moves[halfmove]['fen'];

        if (halfmove == moves.length - 1) {
          print("Game over");
        }
        // Lấy move từ mảng moves
        final moveString = moves[halfmove]['uci'].toString();
        // Phân tích move để lấy from và to
        if (moveString.length >= 4) {
          lastMoveFrom = moveString.substring(0, 2);
          lastMoveTo = moveString.substring(2, 4);
        }
        board = parseFEN(fen);
        whiteTime = moves[halfmove]['whiteTime'];
        blackTime = moves[halfmove]['blackTime'];
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
    int transformedIndex = index;
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
                  "${8 - row}",
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
                  String.fromCharCode(97 + col),
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

    setState(() {
      if (selectedSquare == null || !validSquares.contains(coor)) {
        // Chọn quân cờ
        selectedSquare = coor;
        validMoves = _genMove(coor, game);
        validSquares = _toSanMove(validMoves).toSet();
      } else if (validSquares.contains(coor)) {
      } else {
        // Reset selection
        selectedSquare = null;
        validSquares = {};
      }
    });
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
    var historyMoves = game.getHistory();
    if (historyMoves.isEmpty) {
      return const SizedBox.shrink();
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxHeight: 22, // giới hạn cao nhất thôi
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        controller: _scrollController,
        itemCount: historyMoves.length,
        itemBuilder: (context, index) {
          final move = historyMoves[index];
          return Container(
            margin: const EdgeInsets.only(left: 8),
            child: InkWell(
                onTap: () {
                  setState(() {
                    halfmove = index;
                    if (index < moves.length) {
                      fen = moves[index]['fen'];
                      final moveString = moves[index]['move'].toString();
                      if (moveString.length >= 4) {
                        lastMoveFrom = moveString.substring(0, 2);
                        lastMoveTo = moveString.substring(2, 4);
                      }
                      board = parseFEN(fen);
                      whiteTime = moves[index]['whiteTime'];
                      blackTime = moves[index]['blackTime'];
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
    if (index >= 0 && index < moves.length) {
      double position = index * 50.0;
      _scrollController.animateTo(
        position,
        duration: const Duration(milliseconds: 300),
        curve: Curves.linearToEaseOut,
      );
    }
  }

  int parseTime(String time) {
    int milliseconds = 0;

    // Parse minutes
    RegExp minutesRegex = RegExp(r'(\d+)m');
    var minutesMatch = minutesRegex.firstMatch(time);
    if (minutesMatch != null) {
      int minutes = int.parse(minutesMatch.group(1)!);
      milliseconds += minutes * 60 * 1000;
    }

    // Parse seconds (including fractional part)
    RegExp secondsRegex = RegExp(r'(\d+\.\d+|\d+)s');
    var secondsMatch = secondsRegex.firstMatch(time);
    if (secondsMatch != null) {
      double seconds = double.parse(secondsMatch.group(1)!);
      milliseconds += (seconds * 1000).round();
    }

    return milliseconds;
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
              _buildMenuItem(context, Icons.copy, "Phân tích chuyên sâu", () {
                // TODO: Implement copy PGN
                Navigator.pop(context);
              }),
              //     setState(() {
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
