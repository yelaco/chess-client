import 'package:flutter/material.dart';

import 'package:chess/chess.dart' as chess;
import 'package:flutter_slchess/core/models/match_model.dart';
import 'package:flutter_slchess/core/models/gamestate_model.dart';
import 'package:flutter_slchess/core/models/moveset_model.dart';
import 'package:flutter_slchess/core/models/historymatch_model.dart';
import 'package:flutter_slchess/core/services/match_ws_service.dart';
import 'package:flutter_slchess/core/services/amplify_auth_service.dart';
import 'package:flutter_slchess/core/services/moveset_service.dart';
import 'package:flutter_slchess/core/services/evaluation_service.dart';
import 'package:flutter_slchess/core/models/evaluation_model.dart';

import 'dart:math' as math;

class ChessboardAnalysis extends StatefulWidget {
  final HistoryMatchModel historyMatch;
  final String? initialFen;

  const ChessboardAnalysis({
    super.key,
    required this.historyMatch,
    this.initialFen,
  });

  @override
  State<ChessboardAnalysis> createState() => _ChessboardAnalysisState();
}

class _ChessboardAnalysisState extends State<ChessboardAnalysis> {
  chess.Chess game = chess.Chess();
  late List<Map<String, dynamic>> moves = [];

  int halfmove = 0;
  late List<List<String?>> board;
  late String fen;
  bool isWhiteTurn = true;
  bool isPaused = false;
  String? lastMoveFrom;
  String? lastMoveTo;

  // Move validation
  Set<String> validSquares = {};
  List<chess.Move> validMoves = [];
  String? selectedSquare;

  // UI control
  late ScrollController _scrollController;
  bool _isEvaluationVisible = false;

  // Evaluation
  EvaluationService? _evaluationService;
  EvaluationModel? _currentEvaluation;
  bool _isEvaluating = false;
  bool _isWebsocketConnected = false;
  bool _isConnecting = false; // Biến để kiểm tra đang trong quá trình kết nối
  bool _disposed = false; // Flag để kiểm tra widget đã bị dispose chưa

  // Websocket and services
  late MoveSetService moveSetService;
  final AmplifyAuthService _amplifyAuthService = AmplifyAuthService();

  String? storedIdToken;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _initializeHistoryGame();
    _connectAndAnalyze();
  }

  // Phương thức an toàn để cập nhật state
  void _safeSetState(VoidCallback fn) {
    if (mounted && !_disposed) {
      setState(fn);
    }
  }

  Future<void> _connectAndAnalyze() async {
    // Đánh dấu là đang trong quá trình kết nối
    _safeSetState(() {
      _isConnecting = true;
    });

    // Khởi tạo kết nối websocket và đăng ký lắng nghe sự kiện
    await _initializeEvaluationService();

    if (mounted && !_disposed) {
      _safeSetState(() {
        _isConnecting = false; // Kết thúc quá trình kết nối
      });
    }

    // Tự động hiển thị đánh giá khi vào màn hình
    if (_evaluationService != null && mounted && !_disposed) {
      _safeSetState(() {
        _isEvaluationVisible = true;
        _sendEvaluationRequest();
      });
    }
  }

  Future<void> _initializeEvaluationService() async {
    if (_disposed) return;

    try {
      // Lấy token trước khi khởi tạo dịch vụ đánh giá
      storedIdToken = await _amplifyAuthService.getIdToken();

      if (storedIdToken != null && !_disposed) {
        // Khởi tạo dịch vụ đánh giá với token đã lấy được và đăng ký callback khi thay đổi trạng thái kết nối
        _evaluationService = EvaluationService.startGame(
          storedIdToken!,
          onConnectionChange: _handleConnectionChange,
        );

        // Đánh dấu là đã kết nối thành công, vì khi gọi startGame là đã kết nối
        _safeSetState(() {
          _isWebsocketConnected = true;
        });

        // Đăng ký lắng nghe sự kiện từ websocket
        _evaluationService!.listen(
          onEvaluation: _handleEvaluation,
          onError: _handleEvaluationError,
          context: context,
        );

        print("Đã kết nối thành công đến websocket đánh giá");
        return;
      }

      print("Không thể kết nối đến websocket: Token không hợp lệ");
    } catch (e) {
      print("Lỗi khi kết nối đến websocket đánh giá: $e");
    }
  }

  void _handleConnectionChange(bool isConnected) {
    if (_disposed) return;

    print("Trạng thái kết nối thay đổi: $isConnected");
    _safeSetState(() {
      _isWebsocketConnected = isConnected;

      if (isConnected && _isEvaluationVisible) {
        // Nếu kết nối lại được và panel đánh giá đang hiển thị, gửi lại yêu cầu
        _sendEvaluationRequest();
      }
    });
  }

  void _handleEvaluationError(dynamic error) {
    if (_disposed) return;

    print("Lỗi đánh giá: $error");
    _safeSetState(() {
      _isEvaluating = false;
    });

    // Hiển thị thông báo lỗi cho người dùng nếu cần
    if (_isEvaluationVisible && mounted && !_disposed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi phân tích: ${error.toString()}'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Thử lại',
            onPressed: _sendEvaluationRequest,
          ),
        ),
      );
    }
  }

  void _handleEvaluation(EvaluationModel evaluationModel) {
    if (_disposed) return;

    _safeSetState(() {
      _currentEvaluation = evaluationModel;
      _isEvaluating = false;
    });
  }

  void _sendEvaluationRequest() {
    if (_disposed) return;

    // Kiểm tra kết nối trước khi gửi yêu cầu
    if (_evaluationService != null && !_isEvaluating) {
      if (_evaluationService!.isConnected) {
        _safeSetState(() {
          _isEvaluating = true;
        });
        _evaluationService!.sendEvaluation(fen);
      } else {
        // Nếu mất kết nối, hiển thị thông báo và đánh dấu là không đang đánh giá
        _safeSetState(() {
          _isEvaluating = false;
        });

        // Hiển thị thông báo cho người dùng
        if (mounted && !_disposed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Mất kết nối đến máy chủ phân tích'),
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Thử lại',
                onPressed: () async {
                  // Thử kết nối lại
                  await _initializeEvaluationService();
                  if (_evaluationService?.isConnected == true) {
                    _sendEvaluationRequest();
                  }
                },
              ),
            ),
          );
        }
      }
    }
  }

  void _toggleEvaluation() {
    setState(() {
      _isEvaluationVisible = !_isEvaluationVisible;
      if (_isEvaluationVisible) {
        _sendEvaluationRequest();
      }
    });
  }

  String _formatEvaluationScore(int cp) {
    if (cp > 0) {
      return "+${(cp / 100).toStringAsFixed(2)}";
    } else {
      return (cp / 100).toStringAsFixed(2);
    }
  }

  void _initializeHistoryGame() {
    // Sử dụng initialFen nếu được cung cấp, nếu không thì dùng vị trí ban đầu
    String initFen = widget.initialFen ??
        "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";

    // Đặt bàn cờ về vị trí từ FEN
    if (widget.initialFen != null) {
      game = chess.Chess.fromFEN(widget.initialFen!);
    }

    board = parseFEN(initFen);
    fen = initFen;

    moves.clear();
    moves.add({'fen': initFen});

    if (widget.historyMatch.items.isNotEmpty) {
      List<HistoryMatchItem> moveList = [];
      moveList = widget.historyMatch.items.reversed.toList();

      for (var item in moveList) {
        final move = item.move;
        final from = move.uci.substring(0, 2);
        final to = move.uci.substring(2, 4);
        if (move.uci.length > 4) {
          final promotion = move.uci.substring(4, 5);
          game.move({'from': from, 'to': to, 'promotion': promotion});
        } else {
          game.move({'from': from, 'to': to});
        }
      }
    }

    for (var move in game.getHistory()) {
      moves.add({'move': move, 'uci': move.uci, 'fen': game.fen});
    }
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
    // Đánh dấu là đã dispose để ngăn các callback không gọi setState
    _disposed = true;

    // Đóng ScrollController
    if (_scrollController.hasClients) {
      _scrollController.dispose();
    }

    // Đóng websocket một cách an toàn
    if (_evaluationService != null) {
      try {
        // Tắt WebSocket trước khi gọi super.dispose()
        _isWebsocketConnected = false;
        final service = _evaluationService;
        _evaluationService = null; // Tránh tham chiếu vòng tròn
        service!.close();
      } catch (e) {
        print("Lỗi khi đóng websocket trong dispose: $e");
      }
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Hiển thị màn hình loading toàn màn hình chỉ khi đang trong quá trình kết nối
    // hoặc đã có service nhưng chưa kết nối thành công
    if (_isConnecting ||
        (!_isWebsocketConnected && _evaluationService != null)) {
      return Scaffold(
        backgroundColor: Colors.black87,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo.png',
                width: 120,
                height: 120,
              ),
              const SizedBox(height: 30),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 20),
              const Text(
                'Đang kết nối đến máy chủ phân tích...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Vui lòng đợi trong giây lát',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  // Thử kết nối lại
                  _connectAndAnalyze();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text('Thử lại kết nối'),
              ),
            ],
          ),
        ),
      );
    }

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
            // Nếu có đánh giá, hiển thị thanh đánh giá lớn theo chiều ngang
            if (_isEvaluationVisible &&
                _currentEvaluation != null &&
                _currentEvaluation!.pvs.isNotEmpty)
              _buildHorizontalEvalBar(_currentEvaluation!.pvs[0].cp),
            if (_isEvaluationVisible) _buildEvaluationPanel(),
            Expanded(child: handleChessBoard()),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomAppBar(),
    );
  }

  Widget _buildEvaluationPanel() {
    // Hiển thị trạng thái đang kết nối nếu chưa kết nối được websocket
    if (!_isWebsocketConnected) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        color: Colors.black54,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                strokeWidth: 2,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Đang kết nối đến máy chủ phân tích...',
              style: TextStyle(color: Colors.white),
            ),
            const Spacer(),
            TextButton(
              onPressed: () async {
                await _initializeEvaluationService();
              },
              child: const Text(
                'Thử lại',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      );
    }

    if (_isEvaluating) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        color: Colors.black54,
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Đang phân tích vị trí...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentEvaluation == null) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        color: Colors.black54,
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Chưa có đánh giá',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _sendEvaluationRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                child: const Text('Phân tích ngay'),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentEvaluation?.pvs != null) {
      for (var pv in _currentEvaluation!.pvs) {
        print("PV: ${pv.cp}");
        print("PV: ${_evaluationService!.convertUciToSan(pv.moves, fen)}");
      }
    }

    final pv =
        _currentEvaluation!.pvs.isNotEmpty ? _currentEvaluation!.pvs[0] : null;
    if (pv == null) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        color: Colors.black54,
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Không có đánh giá cho vị trí này',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: _sendEvaluationRequest,
                child:
                    const Text('Thử lại', style: TextStyle(color: Colors.blue)),
              ),
            ],
          ),
        ),
      );
    }

    // Chuyển đổi nước đi từ UCI sang SAN
    var sanMoves = _evaluationService!.convertUciToSan(pv.moves, fen);
    var firstMove = sanMoves.isNotEmpty ? sanMoves[0].toString() : "...";

    // Xác định màu sắc dựa trên điểm đánh giá
    bool isPositive = pv.cp > 0;
    bool isNeutral = pv.cp >= -50 && pv.cp <= 50;

    Color scoreColor;
    if (isNeutral) {
      scoreColor = Colors.grey;
    } else if (isPositive) {
      scoreColor = Colors.green;
    } else {
      scoreColor = Colors.red;
    }

    return SizedBox(
      height: 40,
      child: Container(
        color: Colors.black54,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hiển thị các dòng nước đi từ phân tích
                    for (var i = 0;
                        i < _currentEvaluation!.pvs.length;
                        i++) ...[
                      _buildVariationRow(_currentEvaluation!.pvs[i], i),
                      const Divider(
                        color: Colors.grey,
                        height: 1,
                      ),
                    ],
                    const Divider(
                      color: Colors.grey,
                      height: 1,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget hiển thị một dòng nước đi
  Widget _buildVariationRow(PvModel variation, int index) {
    final sanMoves = _evaluationService!.convertUciToSan(variation.moves, fen);

    // Tạo chuỗi hiển thị nước đi
    String moveText = '';
    for (var i = 0; i < sanMoves.length; i++) {
      if (i > 0) moveText += ' ';
      moveText += sanMoves[i].toString();
    }

    // Màu sắc của dòng đầu tiên được nhấn mạnh
    final isMainLine = index == 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Số hiệu dòng
              SizedBox(
                width: 20,
                child: Text(
                  '${index + 1}.',
                  style: TextStyle(
                    fontSize: 10,
                    color: isMainLine ? Colors.white : Colors.grey,
                    fontWeight:
                        isMainLine ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              // Điểm đánh giá
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: variation.cp > 0 ? Colors.white : Colors.black,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatEvaluationScore(variation.cp),
                    style: TextStyle(
                      fontSize: 10,
                      color: variation.cp > 0 ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 4),
              Text(
                moveText,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                // Cho phép text wrap xuống dòng
                softWrap: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget hiển thị thanh đánh giá ngang phía dưới gameHistory
  Widget _buildHorizontalEvalBar(int cp) {
    // Lấy lượt đi hiện tại từ FEN (w = trắng, b = đen)
    bool isWhiteTurn = fen.contains(' w ');

    // Điều chỉnh giá trị CP theo lượt đi hiện tại
    // Nếu lượt đi của đen, đảo ngược giá trị CP để dương = có lợi cho đen
    int adjustedCp = isWhiteTurn ? cp : -cp;

    // Giới hạn giá trị cp để thanh đánh giá không quá dài
    const double maxCp = 1000.0; // Giới hạn là +/- 10 pawn

    // Xử lý giá trị centipawn thành phần trăm
    double percentage = 50.0; // Mặc định 50% là trận đấu cân bằng

    if (cp >= maxCp) {
      percentage = 95.0; // Trắng thắng tuyệt đối, để lại 5% cho đen
    } else if (cp <= -maxCp) {
      percentage = 5.0; // Đen thắng tuyệt đối, để lại 5% cho trắng
    } else {
      // Công thức chuyển đổi cp sang phần trăm với độ lệch phi tuyến
      // Dùng hàm sigmoid để tạo độ lệch tự nhiên hơn
      double normalizedCp = cp / maxCp; // giá trị từ -1 đến 1
      double sigmoid =
          1.0 / (1.0 + math.exp(-normalizedCp * 5)); // giá trị từ 0 đến 1
      percentage = 50 + (sigmoid - 0.5) * 90; // chuyển 0-1 thành 5-95%
    }

    // Màu có lợi thế (theo cách hiểu của người dùng):
    // Nếu lượt đi của màu nào và adjustedCp > 0, màu đó có lợi thế
    bool isCurrentTurnAdvantage = adjustedCp >= 0;

    // Vị trí hiển thị điểm đánh giá và màu sắc
    Alignment textAlignment;
    Color textColor;
    EdgeInsets textPadding;
    Color textBgColor;
    String displayScore =
        _formatEvaluationScore(cp); // Giữ nguyên định dạng hiển thị

    if (isWhiteTurn) {
      // Lượt của trắng
      if (isCurrentTurnAdvantage) {
        // Trắng có lợi thế (cp >= 0)
        textAlignment = Alignment.centerLeft;
        textColor = Colors.black;
        textPadding = const EdgeInsets.only(left: 8);
        textBgColor = Colors.white70;
      } else {
        // Đen có lợi thế (cp < 0)
        textAlignment = Alignment.centerRight;
        textColor = Colors.white;
        textPadding = const EdgeInsets.only(right: 8);
        textBgColor = Colors.black54;
      }
    } else {
      // Lượt của đen
      if (isCurrentTurnAdvantage) {
        // Đen có lợi thế (adjusted cp >= 0, tức là cp <= 0)
        textAlignment = Alignment.centerRight;
        textColor = Colors.white;
        textPadding = const EdgeInsets.only(right: 8);
        textBgColor = Colors.black54;
      } else {
        // Trắng có lợi thế (adjusted cp < 0, tức là cp > 0)
        textAlignment = Alignment.centerLeft;
        textColor = Colors.black;
        textPadding = const EdgeInsets.only(left: 8);
        textBgColor = Colors.white70;
      }
    }

    return SizedBox(
      height: 24,
      child: Stack(
        children: [
          // Thanh đánh giá nền
          Container(
            height: 24, // Chiều cao của thanh
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              border: Border.all(color: Colors.grey.shade800, width: 1),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Row(
              children: [
                // Phần trắng bên trái
                Container(
                  width: MediaQuery.of(context).size.width * (percentage / 100),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: percentage > 90
                        ? const BorderRadius.horizontal(
                            left: Radius.circular(2), right: Radius.circular(2))
                        : const BorderRadius.horizontal(
                            left: Radius.circular(2)),
                  ),
                ),
                // Phần đen bên phải
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: percentage < 10
                          ? const BorderRadius.horizontal(
                              right: Radius.circular(2),
                              left: Radius.circular(2))
                          : const BorderRadius.horizontal(
                              right: Radius.circular(2)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Điểm cp hiển thị theo điều kiện vị trí
          Align(
            alignment: textAlignment,
            child: Padding(
              padding: textPadding,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: textBgColor,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  displayScore,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
              "Đánh giá",
              _toggleEvaluation,
              icon: Icons.analytics,
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

  void _moveBackward() {
    if (moves.isNotEmpty && halfmove > 0) {
      setState(() {
        halfmove--;

        fen = moves[halfmove]['fen'];
        // Lấy move từ mảng moves
        final moveString = moves[halfmove]['uci'];
        // Phân tích move để lấy from và to
        if (moveString != null && moveString.length >= 4) {
          lastMoveFrom = moveString.substring(0, 2);
          lastMoveTo = moveString.substring(2, 4);
        }
        board = parseFEN(fen);
        scrollToIndex(halfmove);

        // Nếu panel đánh giá đang hiển thị, gửi yêu cầu đánh giá mới
        if (_isEvaluationVisible) {
          _sendEvaluationRequest();
        }
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
        final moveString = moves[halfmove]['uci']?.toString();
        // Phân tích move để lấy from và to
        if (moveString != null && moveString.length >= 4) {
          lastMoveFrom = moveString.substring(0, 2);
          lastMoveTo = moveString.substring(2, 4);
        }
        board = parseFEN(fen);
        scrollToIndex(halfmove);

        // Nếu panel đánh giá đang hiển thị, gửi yêu cầu đánh giá mới
        if (_isEvaluationVisible) {
          _sendEvaluationRequest();
        }
      });
    }
  }

  Widget handleChessBoard() {
    return Stack(
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(
              children: [
                // Chessboard
                GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: 64,
                  itemBuilder: (context, index) => _buildChessSquare(index),
                ),

                // Tọa độ hàng (rank)
                _buildRankCoordinates(),

                // Tọa độ cột (file)
                _buildFileCoordinates(),
              ],
            ),
          ),
        ),
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
    return Row(
      children: [
        // Cột tọa độ bên trái
        SizedBox(
          // width: 15,
          child: Column(
            children: List.generate(8, (row) {
              return Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 30),
                    child: Text(
                      "${8 - row}",
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: (row % 2 != 0)
                            ? const Color(0xFFEEEED2) // Màu ô trắng
                            : const Color(0xFF769656),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        // Phần bàn cờ
        const Expanded(child: SizedBox()),
      ],
    );
  }

  Widget _buildFileCoordinates() {
    return Column(
      children: [
        // Phần bàn cờ
        const Expanded(child: SizedBox()),
        // Hàng tọa độ bên dưới
        SizedBox(
          height: 15,
          child: Row(
            children: List.generate(8, (col) {
              return Expanded(
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 2, bottom: 0),
                    child: Text(
                      String.fromCharCode(97 + col), // a-h
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: (col % 2 == 0)
                            ? const Color(0xFFEEEED2) // Màu ô trắng
                            : const Color(0xFF769656),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
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
    setState(() {
      if (selectedSquare == null || !validSquares.contains(coor)) {
        // Chọn quân cờ
        selectedSquare = coor;
        validMoves = _genMove(coor, game);
        validSquares = _toSanMove(validMoves).toSet();
      } else if (validSquares.contains(coor)) {
        // Thực hiện nước đi
        final move = validMoves.firstWhere((m) => m.toAlgebraic == coor);
        final moveObj = {'from': selectedSquare, 'to': coor};

        // Thêm promotion nếu cần
        if (_isPromotion(move)) {
          moveObj['promotion'] =
              'q'; // Luôn chọn hậu khi phong cấp cho đơn giản
        }

        game.move(moveObj);
        fen = game.fen;

        // Cập nhật moves
        moves.add({'move': move, 'uci': "$selectedSquare$coor", 'fen': fen});
        halfmove = moves.length - 1;

        // Cập nhật bàn cờ
        board = parseFEN(fen);

        // Reset selection
        selectedSquare = null;
        validSquares = {};

        // Tự động gửi yêu cầu phân tích
        _sendEvaluationRequest();

        // Hiển thị panel đánh giá nếu chưa hiển thị
        if (!_isEvaluationVisible) {
          _isEvaluationVisible = true;
        }

        // Kiểm tra kết thúc trò chơi
        _checkGameEnd();
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

                      // Gửi yêu cầu phân tích khi chọn một nước đi
                      if (_isEvaluationVisible) {
                        _sendEvaluationRequest();
                      }
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
              _buildMenuItem(context, Icons.analytics, "Đánh giá nước đi", () {
                Navigator.pop(context);
                _toggleEvaluation();
              }),
              _buildMenuItem(context, Icons.copy, "Phân tích chuyên sâu", () {
                // TODO: Implement copy PGN
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
