import 'package:flutter/material.dart';
import 'package:flutter_slchess/core/models/puzzle_model.dart';
import 'package:flutter_slchess/core/services/puzzle_service.dart';
import 'package:flutter_slchess/core/services/amplify_auth_service.dart';

class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({super.key});

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  final PuzzleService _puzzleService = PuzzleService();
  List<Puzzle>? _puzzles;
  bool _isLoading = true;
  String? _errorMessage;
  PuzzleProfile? _puzzleProfile;
  final AmplifyAuthService _amplifyAuthService = AmplifyAuthService();

  @override
  void initState() {
    super.initState();
    _loadPuzzlesAndProfile();
  }

  Future<void> _loadPuzzlesAndProfile() async {
    // Load both puzzles and profile together
    await Future.wait([
      _loadPuzzles(),
      _loadPuzzleProfile(),
    ]);
  }

  Future<void> _loadPuzzles() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final String? idToken = await _amplifyAuthService.getIdToken();
      if (idToken == null) {
        throw Exception("Vui lòng đăng nhập lại");
      }

      final Puzzles puzzles =
          await _puzzleService.getPuzzleFromCacheOrApi(idToken);

      setState(() {
        _puzzles = puzzles.puzzles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPuzzleProfile() async {
    try {
      final String? idToken = await _amplifyAuthService.getIdToken();
      if (idToken == null) {
        return;
      }

      final profile =
          await _puzzleService.getPuzzleRatingFromCacheOrAPI(idToken);

      print("Puzzle Profile: ${profile.rating}");
      setState(() {
        _puzzleProfile = profile;
      });
    } catch (e) {
      print("Lỗi khi tải puzzle profile: $e");
    }
  }

  void _openPuzzle(Puzzle puzzle) async {
    try {
      final String? idToken = await _amplifyAuthService.getIdToken();
      if (idToken == null) {
        throw Exception("Vui lòng đăng nhập lại");
      }

      // Kiểm tra puzzle có đầy đủ thông tin không
      if (puzzle.puzzleId.isEmpty ||
          puzzle.fen.isEmpty ||
          puzzle.moves.isEmpty) {
        throw Exception("Thông tin puzzle không đầy đủ");
      }

      // Chuyển đến màn hình puzzle
      if (!mounted) return;

      // Đảm bảo tất cả các tham số đều không null và truyền dưới dạng Map<String, dynamic>
      final Map<String, dynamic> arguments = <String, dynamic>{
        'puzzle': puzzle,
        'idToken': idToken
      };

      // Kiểm tra lại các giá trị trong arguments
      arguments.forEach((key, value) {
        if (value == null) {
          throw Exception("Giá trị '$key' không được để trống");
        }
      });

      // Đảm bảo arguments không null khi truyền vào pushNamed
      if (arguments.isNotEmpty) {
        // Sử dụng await để đợi kết quả trả về từ màn hình puzzle
        final result = await Navigator.pushNamed(context, '/puzzle_board',
            arguments: Map<String, dynamic>.from(arguments));

        // Nếu có kết quả trả về và kết quả là true (puzzle đã được giải)
        if (result == true) {
          // Làm mới danh sách puzzle và profile
          _loadPuzzles();
          _loadPuzzleProfile();
        }
      } else {
        throw Exception("Không thể tạo tham số cho màn hình puzzle");
      }
    } catch (e) {
      print("Lỗi khi chuyển đến màn hình puzzle: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi: ${e.toString()}")),
        );
      }
    }
  }

  void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Lỗi'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/bg_dark.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF2A2B2A),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Puzzle Rating: ',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _puzzleProfile?.rating.toString() ?? '0',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadPuzzles,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_puzzles == null || _puzzles!.isEmpty) {
      return const Center(
        child: Text(
          'Không có puzzle nào',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    // Instead of showing a list, show a button to solve a random puzzle
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Giải một bài toán cờ ngẫu nhiên',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _openRandomPuzzle,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              textStyle: const TextStyle(fontSize: 18),
            ),
            child: const Text('Bắt đầu'),
          ),
          const SizedBox(height: 50),
          if (_puzzleProfile != null)
            Text(
              'Bạn đã giải ${(_puzzleProfile!.rating - 300) ~/ 10} bài toán cờ',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
        ],
      ),
    );
  }

  void _openRandomPuzzle() async {
    if (_puzzles != null && _puzzles!.isNotEmpty) {
      try {
        final String? idToken = await _amplifyAuthService.getIdToken();
        if (idToken == null) {
          throw Exception("Vui lòng đăng nhập lại");
        }

        // Kiểm tra quyền chơi puzzle
        final canPlay = await _puzzleService.canPlayPuzzle(idToken);
        if (!canPlay) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Bạn đã hết lượt chơi puzzle hôm nay. Vui lòng nâng cấp lên Premium để chơi không giới hạn.'),
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }

        // Get a random puzzle from the list
        final random = DateTime.now().millisecondsSinceEpoch % _puzzles!.length;
        final puzzle = _puzzles![random];

        // Tăng số lần chơi puzzle
        await _puzzleService.incrementPuzzleCount(idToken);

        _openPuzzle(puzzle);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${e.toString()}')),
          );
        }
      }
    }
  }

  Widget _buildPuzzleItem(Puzzle puzzle) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF2A2B2A),
      child: ListTile(
        title: Text(
          'Puzzle #${puzzle.puzzleId}',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Rating: ${puzzle.rating} | Themes: ${puzzle.themes.join(", ")}',
          style: const TextStyle(color: Colors.grey),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
        onTap: () => _openPuzzle(puzzle),
      ),
    );
  }
}
