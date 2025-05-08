import 'package:flutter/material.dart';
import '../services/matchmaking_service.dart';
import '../services/user_service.dart';
import '../models/user.dart';
import '../models/chessboard_model.dart';
import '../models/match_model.dart';
import '../services/amplify_auth_service.dart';

class MatchMakingScreen extends StatefulWidget {
  final String gameMode;
  final UserModel? user;

  const MatchMakingScreen({
    super.key,
    required this.gameMode,
    this.user,
  });

  @override
  State<MatchMakingScreen> createState() => _MatchMakingScreenState();
}

class _MatchMakingScreenState extends State<MatchMakingScreen> {
  late String gameMode;
  bool isQueued = false;
  bool isLoading = true;
  String statusMessage = "Đang tìm đối thủ...";

  final MatchMakingSerice matchMakingService = MatchMakingSerice();
  final AmplifyAuthService _amplifyAuthService = AmplifyAuthService();
  final UserService userService = UserService();

  UserModel? _user;
  late ChessboardModel chessboardModel;
  UserModel? opponent;

  @override
  void initState() {
    super.initState();
    gameMode = widget.gameMode;
    _user = widget.user;
    _initializeMatchmaking();
  }

  Future<void> _initializeMatchmaking() async {
    try {
      final String? storedIdToken = await _amplifyAuthService.getIdToken();
      if (storedIdToken == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Vui lòng đăng nhập lại")),
          );
          Navigator.pop(context);
        }
        return;
      }

      // Chỉ tải user nếu chưa được truyền vào
      if (_user == null) {
        _user = await userService.getPlayer();

        if (_user == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text("Không thể tìm thấy thông tin người dùng")),
            );
            Navigator.pop(context);
          }
          return;
        }
      }

      if (!mounted) return;
      setState(() {
        isLoading = false;
      });

      // Tìm trận đấu
      MatchModel? match;
      try {
        setState(() {
          statusMessage = "Đang tìm đối thủ phù hợp...";
        });

        match = await matchMakingService.getQueue(
            storedIdToken, gameMode, _user!.rating);

        if (match == null) {
          if (mounted) {
            setState(() {
              statusMessage = "Không tìm thấy đối thủ phù hợp";
            });
            await Future.delayed(const Duration(seconds: 2));
            Navigator.pop(context);
          }
          return;
        }

        // Lấy thông tin đối thủ
        setState(() {
          statusMessage = "Đã tìm thấy đối thủ!";
        });

        try {
          opponent = match.player1.user.id == _user!.id
              ? await userService.getUserInfo(
                  match.player2.user.id, storedIdToken)
              : await userService.getUserInfo(
                  match.player1.user.id, storedIdToken);
        } catch (e) {
          print("Lỗi khi lấy thông tin đối thủ: $e");
          opponent = match.player1.user.id == _user!.id
              ? match.player2.user
              : match.player1.user;
        }

        if (!mounted) return;

        // Tạo model bàn cờ
        chessboardModel = ChessboardModel(
          match: match,
          isOnline: true,
          isWhite: matchMakingService.isUserWhite(match, _user!),
        );

        if (mounted) {
          setState(() {
            isQueued = true;
          });

          await Future.delayed(const Duration(seconds: 1));
          Navigator.popAndPushNamed(context, "/board",
              arguments: chessboardModel);
        }
      } catch (e, stackTrace) {
        print("Lỗi khi tìm trận đấu: $e\n$stackTrace");
        if (mounted) {
          setState(() {
            statusMessage = "Lỗi khi tìm trận đấu";
          });
          await Future.delayed(const Duration(seconds: 2));
          Navigator.pop(context);
        }
      }
    } catch (e, stackTrace) {
      print("Lỗi khi khởi tạo matchmaking: $e\n$stackTrace");
      if (mounted) {
        setState(() {
          statusMessage = "Lỗi khi khởi tạo";
        });
        await Future.delayed(const Duration(seconds: 2));
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: mainContainer(
        child: Center(
          child: IntrinsicWidth(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (isLoading)
                    const CircularProgressIndicator()
                  else ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (_user != null)
                          buildUserAvatar(_user!)
                        else
                          const CircularProgressIndicator(),
                        const SizedBox(width: 10),
                        if (isQueued && opponent != null) ...[
                          const SizedBox(width: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: Image.asset(
                                'assets/weapon.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          buildUserAvatar(opponent!),
                        ] else ...[
                          const CircularProgressIndicator(),
                          const SizedBox(width: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: const SizedBox(
                              width: 50,
                              height: 50,
                              child: Image(
                                image: AssetImage('assets/default_avt.jpg'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      statusMessage,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Hủy tìm kiếm"),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget buildUserAvatar(UserModel user) {
  return Container(
    width: 50,
    height: 50,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withOpacity(0.1),
      border: Border.all(color: Colors.white, width: 2),
    ),
    child: user.picture.isNotEmpty
        ? ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Image.network(
              "${user.picture}/large",
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                print('Error loading avatar: $error');
                return Image.asset(
                  'assets/default_avt.jpg',
                  fit: BoxFit.cover,
                );
              },
            ),
          )
        : ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Image.asset(
              'assets/default_avt.jpg',
              fit: BoxFit.cover,
            ),
          ),
  );
}

Widget mainContainer({Widget? child}) {
  return Container(
    decoration: const BoxDecoration(
      image: DecorationImage(
        image: AssetImage("assets/bg_dark.png"),
        fit: BoxFit.cover,
      ),
    ),
    child: child ?? const Center(),
  );
}
