// import 'package:flutter/material.dart';

// import 'package:chess/chess.dart' as chess;
// import 'package:flutter_slchess/core/models/match.dart';
// import 'package:flutter_slchess/core/services/matchmaking_service.dart';
// import 'package:flutter_slchess/core/services/cognito_auth_service.dart';

// import 'dart:async'; // Thêm import này
// import 'dart:math' as math; // Thêm import này
// import 'dart:convert'; // Để sử dụng jsonEncode

// import 'package:web_socket_channel/web_socket_channel.dart';
// import 'package:web_socket_channel/io.dart';

// class ChessboardOffline extends StatefulWidget {
//   // final Game game;
//   final MatchModel match;
//   const ChessboardOffline({super.key, required this.match});
//   @override
//   State<ChessboardOffline> createState() => _ChessboardOfflineState();
// }

// class _ChessboardOfflineState extends State<ChessboardOffline> {
//   chess.Chess game = chess.Chess();

//   List<String> listFen = [];
//   int halfmove = 0;
//   late List<List<String?>> board;
//   late String fen;
//   late String timeControl; // Khai báo biến timeControl
//   late int timeIncrement; // Khai báo biến timeControl
//   late int whiteTime; // Thời gian còn lại cho bên trắng
//   late int blackTime; // Thời gian còn lại cho bên đen
//   late DateTime lastUpdate;
//   Timer? timer; // Timer để trừ thời gian
//   Set<String> validSquares = {}; // Danh sách các ô hợp lệ
//   List<chess.Move> validMoves = [];
//   String? selectedSquare; // Ô được chọn ban đầu
//   bool isWhiteTurn = true; // Biến để theo dõi lượt đi
//   late Stopwatch _stopwatch; // Thêm biến Stopwatch
//   late ScrollController _scrollController; // Thêm ScrollController
//   late bool isOnline;
//   bool isPaused = false; // Biến để theo dõi trạng thái tạm dừng
//   late String server;

//   // bool isFlipped = false; // Trạng thái xoay bàn cờ
//   bool enableFlip = true;
//   bool isWhite = true;

//   // Websocket server
//   CognitoAuth cognitoAuth = CognitoAuth();
//   late MatchModel match;
//   late WebSocketChannel channel;

//   @override
//   void initState() {
//     super.initState();
//     match = widget.match;
//     isWhite = match.isWhite;
//     isOnline = match.isOnline;
//     timeControl = match.gameMode.split("+")[0];
//     timeIncrement = int.parse(match.gameMode.split("+")[1]);
//     server = match.server;

//     whiteTime = int.parse(timeControl) * 60 * 1000;
//     blackTime = whiteTime;

//     fen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
//     listFen.add(fen);
//     game.load(fen);

//     board = parseFEN(listFen.last);

//     _stopwatch = Stopwatch();
//     _scrollController = ScrollController(); // Khởi tạo ScrollController
//     _scrollToBottomAfterBuild();

//     // Bắt đầu đếm thời gian ngay khi init
//     _stopwatch.start();

//     timer = Timer.periodic(const Duration(milliseconds: 100), (Timer t) {
//       if (!_stopwatch.isRunning) return;
//       final elapsed = _stopwatch.elapsedMilliseconds;
//       _stopwatch.reset(); // Reset sau mỗi lần tính toán
//       _stopwatch.start();
//       setState(() {
//         if (isWhiteTurn) {
//           if (halfmove > 0) {
//             whiteTime -= elapsed;
//             if (whiteTime <= 0) {
//               whiteTime = 0;
//               t.cancel();
//               print("White time out!");
//               showGameEndDialog(context, "White loss", "onTime");
//             }
//           }
//         } else {
//           blackTime -= elapsed;
//           if (blackTime <= 0) {
//             blackTime = 0;
//             t.cancel();
//             print("Black time out!");
//             showGameEndDialog(context, "Black loss", "onTime");
//           }
//         }
//       });
//     });

//     _initializeGame();
//   }

//   Future<void> _initializeGame() async {
//     if (isOnline) {
//       String? storedIdToken = await cognitoAuth.getStoredIdToken();
//       print(storedIdToken!.length);
//       channel =
//           MatchMakingSerice.startGame(match.matchId, storedIdToken, server);

//       channel.stream.listen(
//         (message) {
//           final data = jsonDecode(message);

//           if (data['type'] == "gameState" && data['game']['outcome'] == "*") {
//             fen = data['game']['fen'];
//             listFen.add(fen);
//             board = parseFEN(fen);
//             game.load(fen);

//             isWhiteTurn = game.turn.name == "WHITE" ? true : false;
//           }
//         },
//         onError: (error) => print("WebSocket Error1: $error"),
//         onDone: () => print(
//             "WebSocket closed (Code: ${channel.closeCode}, Reason: ${channel.closeReason})"),
//       );
//     }
//   }

//   void _scrollToBottomAfterBuild() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _scrollToBottom();
//     });
//   }

//   void _scrollToBottom() {
//     if (_scrollController.hasClients) {
//       _scrollController.animateTo(
//         _scrollController.position.maxScrollExtent,
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeOut,
//       );
//     }
//   }

//   void switchTurn() {
//     _stopwatch.reset();
//     _stopwatch.start();
//     setState(() {
//       isWhiteTurn = !isWhiteTurn;
//     });
//   }

//   @override
//   void dispose() {
//     timer?.cancel();
//     _stopwatch.stop();
//     _scrollController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Offline Chess Games',
//           style: TextStyle(
//               fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
//         ),
//         backgroundColor: const Color(0xFF0E1416),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () {
//             _showConfirmationDialog(context); // Hiển thị hộp thoại xác nhận
//           },
//         ),
//       ),
//       body: Column(
//         children: [
//           gameHistory(game),

//           playerWidget(
//               playerName: match.player2.user.username,
//               // playerName: match.player2.id,
//               timeRemaining: formatTime(
//                   blackTime)), // Hiển thị thời gian còn lại cho bên đen
//           handleChessBoard(),
//           playerWidget(
//               playerName: match.player1.user.username,
//               // playerName: match.player2.id,
//               timeRemaining: formatTime(
//                   whiteTime)), // Hiển thị thời gian còn lại cho bên trắng
//         ],
//       ),

//       // Thêm footer với các tùy chọn

//       bottomNavigationBar: BottomAppBar(
//         color: const Color(0xFF282F33),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceAround,
//           children: [
//             Expanded(
//               child: _bottomAppBarBtn(
//                 "Tùy chọn",
//                 () {
//                   _showOptionsMenu(context);
//                 },
//                 icon: Icons.storage,
//               ),
//             ),
//             if (!isOnline)
//               Expanded(
//                 child: _bottomAppBarBtn(
//                   isPaused ? "Tiếp tục" : "Tạm dừng",
//                   () {
//                     setState(() {
//                       if (isPaused) {
//                         _stopwatch.start();
//                       } else {
//                         _stopwatch.stop();
//                       }
//                       isPaused = !isPaused;
//                     });
//                   },
//                   icon: isPaused ? Icons.play_arrow : Icons.pause,
//                 ),
//               ),
//             Expanded(
//               child: _bottomAppBarBtn(
//                 "Quay lại",
//                 () {
//                   if (listFen.length > 1) {
//                     setState(() {
//                       if (halfmove > 0) {
//                         halfmove--;
//                       }
//                       fen = listFen[halfmove];
//                       board = parseFEN(fen);
//                       scrollToIndex(halfmove);
//                     });
//                   }
//                 },
//                 icon: Icons.arrow_back_ios_new,
//               ),
//             ),
//             Expanded(
//               child: _bottomAppBarBtn(
//                 "Tiếp",
//                 () {
//                   if (listFen.length > 1) {
//                     setState(() {
//                       if (halfmove < listFen.length - 1) {
//                         halfmove++;
//                       }
//                       fen = listFen[halfmove];
//                       board = parseFEN(fen);
//                       scrollToIndex(halfmove);
//                     });
//                   }
//                 },
//                 icon: Icons.arrow_forward_ios,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDraggablePiece(String? piece, String coor) {
//     if (piece == null) return const SizedBox.shrink();

//     return Draggable<String>(
//       data: coor,
//       feedback: Image.asset(
//         getPieceAsset(piece),
//         width: 40,
//         height: 40,
//         colorBlendMode: BlendMode.modulate,
//       ),
//       childWhenDragging: const SizedBox.shrink(),
//       onDragStarted: () {
//         // <-- Thêm callback khi bắt đầu kéo
//         setState(() {
//           selectedSquare = coor; // Lưu vị trí quân đang kéo
//           validMoves = _genMove(coor, game); // Tính toán nước đi hợp lệ
//           validSquares = _toSanMove(validMoves).toSet(); // Cập nhật ô hợp lệ
//         });
//       },
//       onDragEnd: (details) {
//         // <-- Xử lý khi kết thúc kéo
//         if (!details.wasAccepted) {
//           setState(() {
//             selectedSquare = null; // Reset nếu không thả vào ô hợp lệ
//             validSquares = {};
//           });
//         }
//       },
//       child: Image.asset(
//         getPieceAsset(piece),
//         fit: BoxFit.contain,
//       ),
//     );
//   }

//   String getPieceAsset(String piece) {
//     switch (piece) {
//       case 'r':
//         return 'assets/pieces/Chess_rdt60.png';
//       case 'n':
//         return 'assets/pieces/Chess_ndt60.png';
//       case 'b':
//         return 'assets/pieces/Chess_bdt60.png';
//       case 'q':
//         return 'assets/pieces/Chess_qdt60.png';
//       case 'k':
//         return 'assets/pieces/Chess_kdt60.png';
//       case 'p':
//         return 'assets/pieces/Chess_pdt60.png';
//       case 'R':
//         return 'assets/pieces/Chess_rlt60.png';
//       case 'N':
//         return 'assets/pieces/Chess_nlt60.png';
//       case 'B':
//         return 'assets/pieces/Chess_blt60.png';
//       case 'Q':
//         return 'assets/pieces/Chess_qlt60.png';
//       case 'K':
//         return 'assets/pieces/Chess_klt60.png';
//       case 'P':
//         return 'assets/pieces/Chess_plt60.png';
//       default:
//         return '';
//     }
//   }

//   Widget handleChessBoard() {
//     return Stack(
//       children: [
//         // Bàn cờ chính
//         Center(
//           child: AspectRatio(
//             aspectRatio: 1,
//             child: GridView.builder(
//               physics: const NeverScrollableScrollPhysics(),
//               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                 crossAxisCount: 8,
//                 childAspectRatio: 1.0,
//               ),
//               itemCount: 64,
//               itemBuilder: (context, index) {
//                 int transformedIndex =
//                     enableFlip && !isWhite ? 63 - index : index;
//                 int row = transformedIndex ~/ 8;
//                 int col = transformedIndex % 8;
//                 String coor = parsePieceCoordinate(col, row);
//                 bool isValidSquare = validSquares.contains(coor);
//                 String? piece = board[row][col];

//                 return DragTarget<String>(
//                   onWillAcceptWithDetails: (data) {
//                     // Kiểm tra nước đi hợp lệ
//                     return isValidSquare;
//                   },
//                   onAcceptWithDetails: (data) {
//                     // Cập nhật vị trí quân cờ
//                     _handleMove(coor);
//                   },
//                   builder: (context, candidateData, rejectedData) {
//                     return GestureDetector(
//                       onTap: () => _handleMove(coor),
//                       child: Container(
//                         decoration: BoxDecoration(
//                           color:
//                               (row + col) % 2 == 0 ? Colors.white : Colors.grey,
//                           border: Border.all(
//                             color:
//                                 isValidSquare ? Colors.green : Colors.black12,
//                             width: isValidSquare ? 2 : 1,
//                           ),
//                         ),
//                         child: Center(
//                           child: _buildDraggablePiece(piece, coor),
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   void _handleMove(String coor) {
//     // print(halfmove);
//     // print(listFen.length);

//     // print(isWhiteTurn);
//     // print(isWhite);
//     // Kiểm tra điều kiện halfmove
//     if (whiteTime <= 0) {
//       print("White time out!");
//       return;
//     }

//     if (blackTime <= 0) {
//       print("Black time out!");
//       return;
//     }

//     if (isOnline && isWhiteTurn != isWhite) {
//       print("Không thể di chuyển quân, vui lòng chờ lượt.");
//       return;
//     }

//     setState(() {
//       if (selectedSquare == null || !validSquares.contains(coor)) {
//         selectedSquare = coor;
//         validMoves = _genMove(coor, game);
//         validSquares = _toSanMove(validMoves).toSet();
//       } else if (validSquares.contains(coor)) {
//         // Nếu ô hiện tại là ô hợp lệ, thực hiện di chuyển
//         chess.Move move = validMoves.firstWhere(
//             (m) => m.fromAlgebraic == selectedSquare && m.toAlgebraic == coor);
//         bool success = game.move(move);
//         if (success) {
//           // Cập nhật FEN và bàn cờ
//           fen = game.fen; // Cập nhật FEN mới
//           listFen.add(fen); // Lưu FEN vào listFen
//           board = parseFEN(fen); // Cập nhật bàn cờ
//           if (isWhiteTurn) {
//             whiteTime += timeIncrement * 1000; // Cộng thời gian cho bên trắng
//           } else {
//             blackTime += timeIncrement * 1000; // Cộng thời gian cho bên đen
//           }
//           _scrollToBottomAfterBuild();
//           halfmove = listFen.length - 1; // Tăng số lượt đi

//           String sanMove = move.fromAlgebraic + move.toAlgebraic;
//           print("Game halfmove: $halfmove, $sanMove");

//           if (isOnline) {
//             MatchMakingSerice.makeMove(sanMove, channel);
//           }
//           // Đổi lượt
//           isWhiteTurn = !isWhiteTurn;

//           if (enableFlip && !isOnline) {
//             isWhite = !isWhite;
//           }
//         }
//         // Đặt lại trạng thái
//         selectedSquare = null;
//         validSquares = {};
//         if (game.game_over) {
//           print("Game over");
//           var turnColor = game.turn.name;
//           if (game.in_checkmate) {
//             print("$turnColor CHECKMATE");
//             showGameEndDialog(context, "$turnColor WON", "CHECKMATE");
//           } else if (game.in_draw) {
//             late String resultStr;

//             if (game.in_stalemate) {
//               resultStr = "Stalemate";
//             } else if (game.in_threefold_repetition) {
//               resultStr = "Repetition";
//             } else if (game.insufficient_material) {
//               resultStr = "Insufficient material";
//             }
//             showGameEndDialog(context, "Draw", resultStr);
//           }
//         }
//       } else {
//         // Nếu nhấn vào ô không hợp lệ, đặt lại trạng thái
//         selectedSquare = null;
//         validSquares = {};
//       }
//     });
//   }

//   void scrollToIndex(int index) {
//     // Kiểm tra xem chỉ số có hợp lệ không
//     if (index >= 0 && index < listFen.length) {
//       // Tính toán vị trí cuộn
//       double position = index * 50.0; // Giả sử mỗi item có chiều cao 50.0
//       _scrollController.animateTo(
//         position,
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.linearToEaseOut,
//       );
//     }
//   }

//   String formatTime(int milliseconds) {
//     int seconds = (milliseconds ~/ 1000);

//     int minutes = seconds ~/ 60;

//     int remainingSeconds = seconds % 60;

//     int remainingMilliseconds = milliseconds % 1000;

//     if (milliseconds < 10000) {
//       // Nếu còn dưới 10 giây

//       return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')},${(remainingMilliseconds ~/ 100).toString()}'; // Hiển thị mm:ss,ms
//     } else {
//       return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}'; // Hiển thị mm:ss
//     }
//   }

//   Widget gameHistory(chess.Chess game) {
//     List<dynamic> moves = game.getHistory();

//     // Nếu không có nước đi nào, trả về một widget thông báo

//     if (moves.isEmpty) {
//       return Container(
//         color: const Color(0xFF0E1416),
//         alignment: Alignment.centerLeft,
//         padding: const EdgeInsets.symmetric(horizontal: 10),
//         child: const Text(" "),
//       );
//     }
//     // Gom 2 nước vào một số thứ tự

//     List<Widget> formattedMoves = List.generate(
//       (moves.length / 2).floor(), // Chia đôi danh sách nước đi

//       (index) {
//         String moveNumber = "${index + 1}.";

//         String firstMove = moves[index * 2]; // Nước đầu tiên

//         String secondMove = moves[index * 2 + 1]; // Nước thứ hai

//         return Row(
//           children: [
//             GestureDetector(
//                 onTap: () => {
//                       onMoveSelected(index * 2)
//                     }, // Gọi hàm khi nhấn vào nước đầu tiên

//                 child: Row(children: [
//                   Text(
//                     moveNumber,
//                     style: const TextStyle(color: Colors.white),
//                   ),
//                   moveSelect(index * 2 + 1, firstMove),
//                 ])),
//             if (index * 2 + 1 <
//                 moves.length) // Kiểm tra nước thứ hai có tồn tại không

//               GestureDetector(
//                   onTap: () => onMoveSelected(
//                       index * 2 + 1), // Gọi hàm khi nhấn vào nước thứ hai

//                   child: moveSelect(index * 2 + 1 + 1, secondMove)),
//             const SizedBox(width: 4),
//           ],
//         );
//       },
//     );

//     // Nếu còn 1 nước lẻ ở cuối, thêm nó vào danh sách

//     if (moves.length % 2 != 0) {
//       formattedMoves.add(GestureDetector(
//         onTap: () =>
//             onMoveSelected(moves.length - 1), // Gọi hàm khi nhấn vào nước lẻ

//         child: Row(
//           children: [
//             Text("${(moves.length / 2).ceil()}. ",
//                 style: const TextStyle(color: Colors.white)),
//             moveSelect((moves.length).ceil(), moves.last)
//           ],
//         ),
//       ));
//     }

//     return SingleChildScrollView(
//       scrollDirection: Axis.horizontal,
//       controller: _scrollController,
//       child: Container(
//         color: const Color(0xFF0E1416),
//         // padding: const EdgeInsets.symmetric(vertical: 1),
//         child: Row(
//           children: formattedMoves,
//         ),
//       ),
//     );
//   }

//   Widget moveSelect(int index, String text) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 4),
//       decoration: BoxDecoration(
//         borderRadius: const BorderRadius.only(
//           topLeft: Radius.circular(6), // Góc trên bên trái
//           topRight: Radius.circular(6), // Góc trên bên phải
//           bottomLeft: Radius.circular(2), // Góc trên bên trái
//           bottomRight: Radius.circular(2), // Góc trên bên phải
//         ),
//         color: halfmove == index ? Colors.grey : null,
//       ),
//       // color: halfmove == index ? Colors.grey : null,
//       child: Text(
//         text,
//         style: TextStyle(
//           color: halfmove == index
//               ? const Color(0xFF282F33)
//               : Colors.white, // Thay đổi màu sắc nếu được chọn

//           fontWeight: halfmove == index ? FontWeight.bold : FontWeight.normal,
//         ),
//       ),
//     );
//   }

//   Widget playerWidget({
//     required String playerName,
//     required String timeRemaining,
//   }) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//       decoration: const BoxDecoration(
//         color: Colors.black87,

//         // borderRadius: BorderRadius.circular(10),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Row(
//             children: [
//               Icon(
//                 Icons.supervised_user_circle, // Biểu tượng quân cờ

//                 color: Colors.grey.shade300,

//                 size: 24,
//               ),
//               const SizedBox(width: 8),
//               Text(
//                 playerName,
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 16,
//                 ),
//               ),
//             ],
//           ),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//             decoration: BoxDecoration(
//               color: Colors.white24,
//               borderRadius: BorderRadius.circular(5),
//             ),
//             child: Row(
//               children: [
//                 const Icon(Icons.timer, size: 16, color: Colors.white),
//                 const SizedBox(width: 5),
//                 Text(
//                   timeRemaining,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 14,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   /// Hàm parseFEN: chuyển chuỗi FEN thành mảng 2 chiều 8x8

//   List<List<String?>> parseFEN(String fen) {
//     // Khởi tạo bàn cờ 8x8 với giá trị mặc định là null (ô trống)

//     List<List<String?>> board =
//         List.generate(8, (_) => List<String?>.filled(8, null));

//     // Tách chuỗi FEN theo dấu '/' để lấy từng hàng

//     List<String> rows = fen.split('/');

//     // Duyệt qua từng hàng (FEN bắt đầu từ hàng trên cùng)

//     for (int i = 0; i < 8; i++) {
//       String row = rows[i];

//       int col = 0;

//       // Duyệt từng ký tự trong chuỗi của hàng đó

//       for (int j = 0; j < row.length; j++) {
//         String char = row[j];

//         // Nếu ký tự là số thì nghĩa là có số ô trống liên tiếp

//         if (RegExp(r'\d').hasMatch(char)) {
//           int emptyCount = int.parse(char);

//           col += emptyCount;
//         } else {
//           // Kiểm tra xem col có nằm trong khoảng hợp lệ không

//           if (col < 8) {
//             // Nếu ký tự là chữ, đặt quân cờ tương ứng tại ô [i][col]

//             board[i][col] = char;

//             col++;
//           }
//         }
//       }
//     }

//     return board;
//   }

//   List<String> _toSanMove(List<chess.Move> moves) {
//     return moves.map((move) => move.toAlgebraic).toList();
//   }

//   List<chess.Move> _genMove(String move, chess.Chess game) {
//     // Lấy danh sách các nước đi hợp lệ

//     List<chess.Move> moves = game.generate_moves({'square': move});

//     return moves; // Trả về danh sách các nước đi hợp lệ
//   }

//   /// Hàm chuyển ký hiệu quân cờ thành đường dẫn ảnh

//   Widget _buildPiece(String? piece) {
//     if (piece == null) return const SizedBox.shrink();

//     String assetName = '';

//     switch (piece) {
//       case 'r':
//         assetName = 'assets/pieces/Chess_rdt60.png';

//         break;

//       case 'n':
//         assetName = 'assets/pieces/Chess_ndt60.png';

//         break;

//       case 'b':
//         assetName = 'assets/pieces/Chess_bdt60.png';

//         break;

//       case 'q':
//         assetName = 'assets/pieces/Chess_qdt60.png';

//         break;

//       case 'k':
//         assetName = 'assets/pieces/Chess_kdt60.png';

//         break;

//       case 'p':
//         assetName = 'assets/pieces/Chess_pdt60.png';

//         break;

//       case 'R':
//         assetName = 'assets/pieces/Chess_rlt60.png';

//         break;

//       case 'N':
//         assetName = 'assets/pieces/Chess_nlt60.png';

//         break;
//       case 'B':
//         assetName = 'assets/pieces/Chess_blt60.png';

//         break;

//       case 'Q':
//         assetName = 'assets/pieces/Chess_qlt60.png';

//         break;

//       case 'K':
//         assetName = 'assets/pieces/Chess_klt60.png';

//         break;

//       case 'P':
//         assetName = 'assets/pieces/Chess_plt60.png';

//         break;

//       default:
//         return const SizedBox.shrink();
//     }

//     return Image.asset(
//       assetName,
//       fit: BoxFit.contain,
//     );
//   }

//   String parsePieceCoordinate(int col, int row) {
//     const columns = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];

//     row = 8 - row;

//     return columns[col] + row.toString();
//   }

//   // Hàm để cập nhật board và lưu FEN mới

//   void updateBoard() {
//     fen = game.fen; // Cập nhật FEN mới

//     board = parseFEN(fen); // Lưu FEN vào board

//     // Cuộn về cuối khi có nước đi mới

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
//     });

//     print(board);
//   }

//   void showGameEndDialog(
//       BuildContext context, String resultTitle, String resultContent) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return Dialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//           ),
//           child: Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 // Tiêu đề
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     const SizedBox(width: 30), // Để căn giữa tiêu đề
//                     Text(
//                       resultTitle, // Ví dụ: "Trắng thắng"
//                       style: const TextStyle(
//                           fontSize: 22, fontWeight: FontWeight.bold),
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.close),
//                       onPressed: () => Navigator.of(context).pop(),
//                     ),
//                   ],
//                 ),
//                 Text(resultContent, style: const TextStyle(color: Colors.grey)),
//                 const SizedBox(height: 10),
//                 // Thống kê
//                 // Row(
//                 //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 //   children: [
//                 //     _buildStat("1", "Nước đi hay", Colors.blue),
//                 //     _buildStat("0", "Bỏ lỡ", Colors.red),
//                 //     _buildStat("1", "Nước sai nghiêm trọng", Colors.red),
//                 //   ],
//                 // ),
//                 // const SizedBox(height: 10),
//                 // Nút hành động
//                 // ElevatedButton(
//                 //   onPressed: () {
//                 //     // Xử lý xem lại ván đấu
//                 //     Navigator.of(context).pop();
//                 //   },
//                 //   style: ElevatedButton.styleFrom(
//                 //     backgroundColor: Colors.green,
//                 //     shape: RoundedRectangleBorder(
//                 //         borderRadius: BorderRadius.circular(10)),
//                 //   ),
//                 //   child: const Text("Xem lại ván đấu",
//                 //       style: TextStyle(fontSize: 18, color: Colors.white)),
//                 // ),
//                 // const SizedBox(height: 10),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     _buildButton(context, "Tái đấu"),
//                     _buildButton(context, "Ván cờ mới"),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

// // Hàm tạo widget thống kê

//   Widget _buildStat(String number, String text, Color color) {
//     return Column(
//       children: [
//         Container(
//           padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
//           decoration: BoxDecoration(
//               color: color, borderRadius: BorderRadius.circular(10)),
//           child: Text(number,
//               style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold)),
//         ),
//         const SizedBox(height: 4),
//         Text(text, style: TextStyle(color: color)),
//       ],
//     );
//   }

// // Hàm tạo nút bấm

//   Widget _buildButton(BuildContext context, String text) {
//     return ElevatedButton(
//       onPressed: () {
//         Navigator.of(context).pop();

//         // Xử lý logic tái đấu hoặc ván mới tại đây
//       },
//       style: ElevatedButton.styleFrom(
//         backgroundColor: Colors.grey[300],
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       ),
//       child:
//           Text(text, style: const TextStyle(fontSize: 16, color: Colors.black)),
//     );
//   }

//   // Hàm xử lý sự kiện khi nhấn vào nước đi trong lịch sử

//   void onMoveSelected(int index) {
//     setState(() {
//       fen = listFen[index + 1]; // Cập nhật FEN với nước đi đã chọn

//       board = parseFEN(fen); // Cập nhật bàn cờ

//       halfmove = index + 1; // Cập nhật halfmove
//     });
//   }

//   void _showOptionsMenu(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//       ),
//       builder: (BuildContext context) {
//         return Container(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               _buildMenuItem(context, Icons.flag, "Chấp nhận thua", () {
//                 Navigator.pop(context);
//                 // Xử lý logic đầu hàng ở đây
//               }),
//               _buildMenuItem(context, Icons.sync_disabled,
//                   "${enableFlip ? "Tắt" : "Bật"} chức năng xoay bàn cờ", () {
//                 enableFlip = !enableFlip;

//                 Navigator.pop(context);
//                 // Xử lý logic tắt xoay bàn cờ ở đây
//               }),
//               _buildMenuItem(context, Icons.copy, "Sao chép PGN", () {
//                 Navigator.pop(context);
//                 // Xử lý sao chép PGN ở đây
//               }),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildMenuItem(
//       BuildContext context, IconData icon, String text, VoidCallback onTap) {
//     return ListTile(
//       leading: Icon(icon, size: 28),
//       title: Text(text, style: const TextStyle(fontSize: 16)),
//       onTap: onTap,
//     );
//   }

//   Widget _bottomAppBarBtn(String text, VoidCallback onPressed,
//       {IconData? icon}) {
//     return InkWell(
//       onTap: onPressed, // Gọi trực tiếp hàm được truyền vào
//       child: Container(
//         decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
//         // padding:
//         //     const EdgeInsets.symmetric(vertical: 5), // Thêm padding cho nút
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             if (icon != null)
//               Icon(
//                 icon,
//                 color: Colors.white,
//                 size: 20,
//               ), // Hiển thị icon nếu có
//             const SizedBox(width: 8), // Khoảng cách giữa icon và text
//             Text(
//               text,
//               style: const TextStyle(
//                   color: Colors.white, fontSize: 11), // Đặt màu chữ
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // Hàm hiển thị hộp thoại xác nhận

//   void _showConfirmationDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text("Xác nhận"),
//           content: const Text("Bạn có chắc chắn muốn hủy ván đấu không?"),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop(); // Đóng hộp thoại
//               },
//               child: const Text("Không"),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop(); // Đóng hộp thoại

//                 Navigator.of(context).pop(); // Quay lại màn hình trước đó
//               },
//               child: const Text("Có"),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }
