class Move {
  final String from; // Vị trí bắt đầu (ví dụ: "e2")
  final String to; // Vị trí đích (ví dụ: "e4")
  final String? promotion; // Quân cờ phong cấp (nếu có)
  final bool isCapture; // Có phải là nước ăn quân không
  final bool isCheck; // Có chiếu không
  final bool isCheckmate; // Có chiếu hết không

  Move({
    required this.from,
    required this.to,
    this.promotion,
    this.isCapture = false,
    this.isCheck = false,
    this.isCheckmate = false,
  });

  String toPGN() {
    // Chuyển đổi nước đi sang định dạng PGN
    String pgn = '';

    if (isCapture) pgn += 'x';
    pgn += to;
    if (promotion != null) pgn += '=$promotion';
    if (isCheckmate) {
      pgn += '#';
    } else if (isCheck) pgn += '+';

    return pgn;
  }

  factory Move.fromPGN(String pgn) {
    // TODO: Implement PGN parsing
    throw UnimplementedError();
  }
}

//wraper class
// class MoveWrapper {
//   final Move move;
//   final String? comment;
  
// }

