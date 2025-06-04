import 'package:chess/chess.dart';

String indexToChessCoordinate(int index) {
  const columns = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
  int row = 8 - (index ~/ 8); // Tính hàng từ chỉ số
  int column = index % 8; // Tính cột từ chỉ số
  return '${columns[column]}$row';
}

void main() {
  // Tạo một đối tượng Chess
  Chess chess = Chess();
// Lấy danh sách các nước đi hợp lệ từ ô 'e2'
  List<Move> moves = chess.generate_moves({'square': 'b1'});

// Chuyển đổi các nước đi sang SAN (tùy chọn)
  List<String> sanMoves = [];
  for (Move move in moves) {
    sanMoves.add(chess.move_to_san(move));
  }
// In kết quả
  print(chess.ascii);
  print("Các nước đi hợp lệ từ ô b1: ${sanMoves.join(', ')}");
  chess.move(moves[0]);
  print(chess.ascii);
}
