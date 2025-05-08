import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess;
import 'package:flutter_slchess/core/models/puzzle_model.dart';
import 'package:flutter_slchess/core/services/puzzle_service.dart';
import 'package:flutter_slchess/core/constants/app_styles.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:amplify_flutter/amplify_flutter.dart';

class PuzzleChessboard extends StatefulWidget {
  final Puzzle puzzle;
  final String idToken;

  const PuzzleChessboard({
    super.key,
    required this.puzzle,
    required this.idToken,
  });

  @override
  State<PuzzleChessboard> createState() => _PuzzleChessboardState();
}

class _PuzzleChessboardState extends State<PuzzleChessboard>
    with SingleTickerProviderStateMixin {
  late chess.Chess game;
  late List<List<String?>> board;
  late List<String> solutionMoves;
  int currentMoveIndex = 0;
  bool isPlayerTurn = true;
  bool isPuzzleSolved = false;
  bool isPuzzleFailed = false;
  String? message;
  String? lastMoveFrom;
  String? lastMoveTo;
  String? lastHintMoveFrom;
  String? lastHintMoveTo;
  int? newRating;
  bool isLoading = false;
  double boardOpacity = 1.0;
  double messageOpacity = 0.0;

  // Các biến UI
  Set<String> validSquares = {};
  List<chess.Move> validMoves = [];
  String? selectedSquare;
  bool enableFlip = false;
  bool isWhite = true;
  late ScrollController _scrollController;
  bool isHint = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Service
  final PuzzleService _puzzleService = PuzzleService();

  Timer? _timer;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _initializePuzzle();
    _scrollController = ScrollController();

    // Đợi 1 giây sau khi khởi tạo, máy sẽ đi nước đầu tiên
  }

  void _initializePuzzle() {
    setState(() {
      isLoading = true;
      boardOpacity = 0.0;
    });

    game = chess.Chess();

    // Kiểm tra FEN hợp lệ
    if (widget.puzzle.fen.isEmpty) {
      print("Lỗi: FEN trống");
      return;
    }

    game.load(widget.puzzle.fen);

    // Khởi tạo các biến trạng thái
    solutionMoves = widget.puzzle.moves.isEmpty
        ? []
        : List<String>.from(widget.puzzle.moves);
    board = parseFEN(widget.puzzle.fen);
    isWhite = widget.puzzle.fen.contains(' w ');
    isPlayerTurn = false;

    // Hiệu ứng fade in cho bàn cờ
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          boardOpacity = 1.0;
          isLoading = false;
        });
      }
    });

    // Đợi 1 giây rồi thực hiện nước đi đầu tiên của máy
    Timer(const Duration(seconds: 1), () {
      if (solutionMoves.isNotEmpty) {
        _makeOpponentMove();
      }
    });
  }

  void _handleSquareSelected(String coor) {
    if (!isPlayerTurn || isPuzzleSolved || isPuzzleFailed) return;

    if (selectedSquare == null || !validSquares.contains(coor)) {
      // Chọn quân cờ
      final row = 8 - int.parse(coor[1]);
      final col = coor.codeUnitAt(0) - 'a'.codeUnitAt(0);

      if (board[row][col] != null) {
        setState(() {
          selectedSquare = coor;
          validMoves = _genMove(coor, game);
          validSquares = _generateValidSquares(validMoves);
        });
      }
    } else if (selectedSquare == coor) {
      // Bỏ chọn quân cờ
      setState(() {
        selectedSquare = null;
        validSquares = {};
        validMoves = [];
      });
    } else {
      // Di chuyển quân cờ
      _handleMove(coor);
    }
  }

  void _handleMove(String to) {
    if (selectedSquare == null || !isPlayerTurn || !validSquares.contains(to)) {
      return;
    }

    final from = selectedSquare!;

    // Tìm nước đi hợp lệ
    chess.Move? validMove;
    for (var move in validMoves) {
      if (move.fromAlgebraic == from && move.toAlgebraic == to) {
        validMove = move;
        break;
      }
    }

    if (validMove != null) {
      String moveAlgebraic = validMove.fromAlgebraic + validMove.toAlgebraic;

      if (currentMoveIndex < solutionMoves.length) {
        String expectedMove = solutionMoves[currentMoveIndex];
        String expectedFrom = expectedMove.substring(0, 2);
        String expectedTo = expectedMove.substring(2, 4);

        // Kiểm tra ô bắt đầu và ô đích
        if (validMove.fromAlgebraic != expectedFrom ||
            validMove.toAlgebraic != expectedTo) {
          setState(() {
            message = "Nước đi không chính xác!";
            isPuzzleFailed = true;
            isPlayerTurn = false;
          });
          return;
        }
      }

      // Kiểm tra xem đây có phải là nước đi phong cấp không
      if (_isPromotion(validMove)) {
        _showPromotionDialog(validMove);
        return;
      }

      _makeMove(validMove);

      setState(() {
        message = "Chính xác!";
        selectedSquare = null;
        validSquares = {};
        validMoves = [];
        isPlayerTurn = false;
        currentMoveIndex++;
      });

      // Kiểm tra xem puzzle đã được giải chưa
      if (currentMoveIndex >= solutionMoves.length) {
        _onPuzzleSolved();
      } else {
        // Thực hiện nước đi của máy sau 1 giây
        Timer(const Duration(milliseconds: 500), _makeOpponentMove);
      }
    }
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
  void _showPromotionDialog(chess.Move move) {
    final isWhitePiece = move.color.name == 'WHITE';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Chọn quân cờ phong cấp'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPromotionChoice(context, move, isWhitePiece ? 'Q' : 'q'),
              _buildPromotionChoice(context, move, isWhitePiece ? 'R' : 'r'),
              _buildPromotionChoice(context, move, isWhitePiece ? 'B' : 'b'),
              _buildPromotionChoice(context, move, isWhitePiece ? 'N' : 'n'),
            ],
          ),
        );
      },
    );
  }

  // Xây dựng widget cho từng lựa chọn phong cấp
  Widget _buildPromotionChoice(
      BuildContext context, chess.Move move, String promotionPiece) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();

        String moveString =
            "${move.fromAlgebraic}${move.toAlgebraic}${promotionPiece.toLowerCase()}";

        print("moveString: $moveString");
        // Thực hiện nước đi
        game.move({
          'from': move.fromAlgebraic,
          'to': move.toAlgebraic,
          'promotion': promotionPiece.toLowerCase(), // 'q', 'n', 'b', 'r'
        });

        // Kiểm tra nước đi cần thiết cho puzzle
        String baseMoveRequired =
            solutionMoves[currentMoveIndex].substring(0, 4);
        String promotionRequired = solutionMoves[currentMoveIndex].length > 4
            ? solutionMoves[currentMoveIndex].substring(4)
            : '';

        // Kiểm tra nếu cần thiết phải phong cấp đúng quân cờ cho puzzle
        if (promotionRequired.isNotEmpty &&
            promotionPiece.toLowerCase() != promotionRequired) {
          setState(() {
            message = "Không đúng quân cờ phong cấp!";
            isPuzzleFailed = true;
            isPlayerTurn = false;
          });
          return;
        }

        // Lưu lại trạng thái bàn cờ sau khi thực hiện nước đi
        setState(() {
          lastMoveFrom = move.fromAlgebraic;
          lastMoveTo = move.toAlgebraic;
          board = parseFEN(game.fen);
          message = "Chính xác!";
          selectedSquare = null;
          validSquares = {};
          validMoves = [];
          isPlayerTurn = false;
          currentMoveIndex++;
        });

        // Kiểm tra xem puzzle đã được giải chưa
        if (currentMoveIndex >= solutionMoves.length) {
          _onPuzzleSolved();
        } else {
          // Thực hiện nước đi của máy sau 1 giây
          Timer(const Duration(milliseconds: 500), _makeOpponentMove);
        }
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

  String _formatMoveForComparison(String move) {
    // Chuyển đổi nước đi để so sánh với định dạng trong puzzle
    // Ví dụ: "e2e4" -> "e2e4"
    return move;
  }

  void _makeMove(chess.Move move) {
    setState(() {
      lastMoveFrom = move.fromAlgebraic;
      lastMoveTo = move.toAlgebraic;
      game.move(move);
      board = parseFEN(game.fen);
    });
    selectedSquare = null;
    validSquares = {};
  }

  void _makeOpponentMove() {
    if (currentMoveIndex < solutionMoves.length) {
      final moveString = solutionMoves[currentMoveIndex];
      final from = moveString.substring(0, 2);
      final to = moveString.substring(2, 4);
      final promotion = moveString.length > 4 ? moveString.substring(4) : null;

      // Tìm nước đi hợp lệ
      chess.Move? validMove;
      for (var m in game.generate_moves()) {
        if (m.fromAlgebraic == from && m.toAlgebraic == to) {
          validMove = m;
          break;
        }
      }

      if (validMove != null) {
        // Nếu là nước đi phong cấp
        if (promotion != null) {
          game.move({
            'from': from,
            'to': to,
            'promotion': promotion,
          });

          setState(() {
            lastMoveFrom = from;
            lastMoveTo = to;
            board = parseFEN(game.fen);
            currentMoveIndex++;
            isPlayerTurn = true;
          });
        } else {
          // Nước đi thông thường
          _makeMove(validMove);

          setState(() {
            currentMoveIndex++;
            isPlayerTurn = true;
          });
        }

        if (currentMoveIndex >= solutionMoves.length) {
          _onPuzzleSolved();
        }
      }
    }
  }

  Future<void> _onPuzzleSolved() async {
    try {
      if (!mounted) return;

      setState(() {
        isPuzzleSolved = true;
        message = "Puzzle đã được giải thành công!";
      });

      // Gửi thông báo đến server và đợi kết quả
      final updatedRating =
          await _puzzleService.solvedPuzzle(widget.idToken, widget.puzzle);

      if (!mounted) return;

      setState(() {
        newRating = updatedRating;
      });

      // Đợi một chút để người dùng thấy thông báo thành công
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      // Quay về màn hình trước với kết quả true
      Navigator.of(context).pop(true);
    } catch (e) {
      safePrint('Lỗi khi xử lý giải puzzle: $e');
      if (!mounted) return;

      setState(() {
        message = "Có lỗi xảy ra khi cập nhật kết quả!";
      });
    }
  }

  void _resetPuzzle() {
    setState(() {
      _initializePuzzle();
      selectedSquare = null;
      validSquares = {};
      validMoves = [];
      currentMoveIndex = 0;
      isPlayerTurn = true;
      isPuzzleSolved = false;
      isPuzzleFailed = false;
      message = null;
      lastMoveFrom = null;
      lastMoveTo = null;
      lastHintMoveFrom = null;
      lastHintMoveTo = null;
      isHint = false;
    });
  }

  void _showMessage(String msg, bool isSuccess) {
    setState(() {
      message = msg;
      messageOpacity = 0.0;
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          messageOpacity = 1.0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Puzzle #${widget.puzzle.puzzleId}',
            style: AppStyles.heading4),
        backgroundColor: AppStyles.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/bg_dark.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Column(
              children: [
                // Status bar
                Container(
                  padding: AppStyles.smallPadding,
                  color: AppStyles.primaryColor.withOpacity(0.8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        newRating != null
                            ? 'Rating: $newRating'
                            : 'Rating: ${widget.puzzle.rating}',
                        style: AppStyles.bodyMedium,
                      ),
                      Text(
                        isPlayerTurn ? 'Lượt của bạn' : 'Đợi máy...',
                        style: AppStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),

                // Chessboard
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: boardOpacity,
                  child: _buildChessboard(),
                ),

                // Message
                if (message != null)
                  Container(
                    width: double.infinity,
                    padding: AppStyles.smallPadding,
                    color: isPuzzleSolved
                        ? AppStyles.successColor
                        : isPuzzleFailed
                            ? AppStyles.errorColor
                            : AppStyles.primaryColor,
                    child: Text(
                      message!,
                      style: AppStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Actions
                Container(
                  padding: AppStyles.mediumPadding,
                  color: AppStyles.primaryColor,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _resetPuzzle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyles.warningColor,
                          foregroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppStyles.defaultBorderRadius,
                          ),
                        ),
                        child: const Text('Thử lại'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (isPuzzleSolved) {
                            Navigator.pop(context, true);
                          } else {
                            setState(() {
                              validSquares = {};
                              if (!isHint) {
                                lastHintMoveFrom =
                                    solutionMoves[currentMoveIndex]
                                        .substring(0, 2);
                                isHint = true;
                              } else if (isHint) {
                                lastHintMoveTo = solutionMoves[currentMoveIndex]
                                    .substring(2, 4);
                                isHint = false;
                              }
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isPuzzleSolved
                              ? AppStyles.successColor
                              : AppStyles.infoColor,
                          foregroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppStyles.defaultBorderRadius,
                          ),
                        ),
                        child: Text(isPuzzleSolved ? 'Tiếp theo' : 'Gợi ý'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChessboard() {
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
        _buildFileCoordinates(),
        _buildRankCoordinates()
      ],
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

  Widget _buildChessSquare(int index) {
    int transformedIndex = isWhite ? 63 - index : index;
    int row = transformedIndex ~/ 8;
    int col = transformedIndex % 8;
    String coor = parsePieceCoordinate(col, row);
    bool isValidSquare = validSquares.contains(coor);
    bool isLastMoveFrom = coor == lastMoveFrom;
    bool isLastMoveTo = coor == lastMoveTo;
    bool isLastHintMoveFrom = coor == lastHintMoveFrom;
    bool isLastHintMoveTo = coor == lastHintMoveTo;
    String? piece = board[row][col];

    return DragTarget<String>(
      onWillAcceptWithDetails: (data) => isValidSquare,
      onAcceptWithDetails: (data) => _handleMove(coor),
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          onTap: () => _handleSquareSelected(coor),
          child: Container(
            decoration: BoxDecoration(
              color: (row + col) % 2 == 0
                  ? const Color(0xFFEEEED2) // Màu ô trắng
                  : const Color(0xFF769656), // Màu ô xanh
              border: Border.all(
                color: isValidSquare
                    ? Colors.green
                    : isLastMoveFrom ||
                            isLastMoveTo ||
                            isLastHintMoveFrom ||
                            isLastHintMoveTo
                        ? Colors.blueAccent
                        : Colors.transparent,
                width: isValidSquare ||
                        isLastMoveFrom ||
                        isLastMoveTo ||
                        isLastHintMoveFrom ||
                        isLastHintMoveTo
                    ? 2
                    : 0,
              ),
              boxShadow: isLastMoveTo
                  ? [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.4),
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

  Widget _buildDraggablePiece(String? piece, String coor) {
    if (piece == null) return const SizedBox.shrink();

    final canDrag = isPlayerTurn &&
        !isPuzzleSolved &&
        !isPuzzleFailed &&
        ((piece.toUpperCase() == piece) == isWhite);

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
        width: 50,
        height: 50,
      ),
      childWhenDragging: const SizedBox.shrink(),
      onDragStarted: () {
        setState(() {
          selectedSquare = coor;
          validMoves = _genMove(coor, game);
          validSquares = _generateValidSquares(validMoves);
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

  List<chess.Move> _genMove(String move, chess.Chess game) {
    return game.generate_moves({'square': move});
  }

  Set<String> _generateValidSquares(List<chess.Move> moves) {
    return moves.map((move) => move.toAlgebraic).toSet();
  }

  String parsePieceCoordinate(int col, int row) {
    const columns = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    row = 8 - row;
    return columns[col] + row.toString();
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

  @override
  void dispose() {
    _animationController.dispose();
    _timer?.cancel();
    super.dispose();
  }
}
