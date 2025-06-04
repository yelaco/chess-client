import 'package:flutter/material.dart';
import '../widgets/widgets.dart';
import '../constants/constants.dart';
import '../models/player.dart';
import '../models/match_model.dart';
import '../models/chessboard_model.dart';
import '../models/user.dart';
import '../widgets/error_dialog.dart';

class OfflineGameScreen extends StatefulWidget {
  const OfflineGameScreen({super.key});

  @override
  State<OfflineGameScreen> createState() => _OfflineGameScreenState();
}

class _OfflineGameScreenState extends State<OfflineGameScreen> {
  String selectedTimeControl = "";
  bool rotateBoard = false;
  String whitePlayerName = "Ẩn danh";
  String blackPlayerName = "Ẩn danh";
  bool showTimeControlGrid = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        // backgroundColor: Colors.black87,
        appBar: AppBar(
          backgroundColor: const Color(0xFF0E1416),
          title: const Text(
            "2 người 1 máy",
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          centerTitle: true,
        ),
        body: BackgroundContainer(
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Chơi với bạn offline
                const Text(
                  "Chơi với bạn offline",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 20),

                // Chọn quân trắng & quân đen
                _buildPlayerInput("Quân trắng", (value) {
                  whitePlayerName = value; // Lưu tên bên trắng
                }),
                _buildPlayerInput("Quân đen", (value) {
                  blackPlayerName = value; // Lưu tên bên đen
                }),
                const SizedBox(height: 20),

                // Điều khiển thời gian
                GestureDetector(
                  onTap: () {
                    setState(() {
                      showTimeControlGrid = !showTimeControlGrid;
                    });
                  },
                  child: const Text(
                    "Điều khiển thời gian",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 10),

                if (showTimeControlGrid)
                  SingleChildScrollView(
                    child: Container(
                      constraints: const BoxConstraints(
                        maxHeight: 200, // Đặt chiều cao tối đa cho lưới
                      ),
                      child: _buildTimeControlGrid(),
                    ),
                  ),

                const SizedBox(height: 20),

                const Spacer(),

                // Nút "Chơi"
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      // Bắt đầu game với thời gian đã chọn
                      if (selectedTimeControl.isEmpty) {
                        // Hiển thị thông báo lỗi
                        // ScaffoldMessenger.of(context).showSnackBar(
                        //   const SnackBar(
                        //     content: Text('Vui lòng chọn thời gian chơi'),
                        //     backgroundColor: Colors.red,
                        //   ),
                        // );
                        ErrorDialog().showPopupError(
                            context, "Vui lòng chọn thời gian chơi");
                        return;
                      }

                      Navigator.pushNamed(context, '/board',
                          arguments: ChessboardModel(
                              match: MatchModel(
                                matchId: "offlineGame",
                                conversationId: "offlineGame",
                                player1: Player(
                                    user: UserModel(
                                        id: "whitePlayer",
                                        username: whitePlayerName),
                                    rating: 1200),
                                player2: Player(
                                    user: UserModel(
                                        id: "blackPlayer",
                                        username: blackPlayerName),
                                    rating: 1200),
                                gameMode: selectedTimeControl,
                                server: "offline",
                                createdAt: DateTime.now(),
                              ),
                              isOnline: false,
                              isWhite: true));
                    },
                    child: const Text(
                      "Chơi",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  // Lưới chọn thời gian
  Widget _buildTimeControlGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics:
          const AlwaysScrollableScrollPhysics(), // Đảm bảo GridView có thể cuộn
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: timeControls.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              selectedTimeControl = timeControls[index]["value"] as String;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: selectedTimeControl == timeControls[index]["value"]
                  ? Colors.green
                  : Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
              border: selectedTimeControl == timeControls[index]["value"]
                  ? Border.all(color: Colors.greenAccent, width: 2)
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              timeControls[index]["key"] as String,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        );
      },
    );
  }

  // Widget nhập tên người chơi
  Widget _buildPlayerInput(String label, Function(String) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 16)),
        ),
        Flexible(
          child: TextField(
            onChanged: onChanged,
            decoration: InputDecoration(
                // border: const OutlineInputBorder(),
                hintText: 'Tên $label',
                border: InputBorder.none),
            textAlign: TextAlign.right,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            maxLines: null,
          ),
        ),
      ],
    );
  }
}
