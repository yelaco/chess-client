import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/amplify_auth_service.dart';
import '../services/user_service.dart';
import '../services/moveset_service.dart';
import '../services/matchresult_service.dart';
import '../models/user.dart';
import '../models/historymatch_model.dart';
import '../models/matchresults_model.dart';
import '../constants/app_styles.dart';
import 'review_chessboard.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../widgets/widgets.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel? user;
  const ProfileScreen({super.key, this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AmplifyAuthService _authService = AmplifyAuthService();
  final UserService _userService = UserService();
  final MatchResultService _matchResultService = MatchResultService();

  UserModel? _user;
  MatchResultsModel? _matchResults;
  bool _isLoading = true;
  final bool _isSaving = false;
  String? _error;

  final _usernameController = TextEditingController();
  final _locateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _locateController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (!mounted) return;
      setState(() {
        _user = widget.user;
        _isLoading = false;
        _usernameController.text = widget.user!.username;
        _locateController.text = widget.user!.locate;
      });

      // Load match history
      if (_user != null) {
        print(_user!.id);
        final String? idToken = await _authService.getIdToken();
        if (idToken != null) {
          final results = await _matchResultService.getMatchResults(idToken,
              userId: _user!.id);
          if (!mounted) return;

          setState(() {
            _matchResults = results;
          });
        }
      }
    } catch (e) {
      safePrint("Lỗi khi tải thông tin người dùng: $e");
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thông tin cá nhân',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0E1416),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg_dark.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : _error != null && _user == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Lỗi: $_error',
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _loadUserData,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: AppStyles.defaultPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Phần avatar và thông tin cơ bản
                        Center(
                          child: Column(
                            children: [
                              Avatar(
                                _user!.picture,
                                size: 100,
                              ),
                              const SizedBox(height: 12),
                              if (_isSaving)
                                const Padding(
                                  padding: EdgeInsets.only(top: 20),
                                  child: CircularProgressIndicator(),
                                ),
                            ],
                          ),
                        ),
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              if (_user != null) {
                                final String userId = _user!.id;
                                Clipboard.setData(ClipboardData(text: userId));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Đã sao chép ID: $userId'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.content_copy,
                                  size: 10,
                                  color: Colors.grey,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Sao chép ID người dùng',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Thông tin cơ bản
                        _buildSectionHeader('Thông tin cơ bản'),
                        _buildTextField(
                          label: 'Tên hiển thị',
                          controller: _usernameController,
                          icon: Icons.person,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          label: 'Vị trí',
                          controller: _locateController,
                          icon: Icons.location_on,
                        ),
                        // const SizedBox(height: 16),
                        // ElevatedButton(
                        //   onPressed: _saveUserData,
                        //   child: const Text('Lưu thông tin'),
                        // ),

                        const SizedBox(height: 32),

                        // Thông tin chi tiết
                        _buildSectionHeader('Thông tin chi tiết'),
                        _buildInfoItem('Tên người dùng', _user!.username),
                        _buildInfoItem(
                            'Vị trí',
                            _user!.locate.isEmpty
                                ? 'Chưa cập nhật'
                                : _user!.locate),
                        _buildInfoItem(
                            'Rating', _user!.rating.toStringAsFixed(0)),
                        _buildInfoItem(
                            'Ngày tạo tài khoản', _formatDate(_user!.createAt)),

                        const SizedBox(height: 32),

                        // Lịch sử trận đấu
                        _buildMatchHistory(),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade300,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool obscureText = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: Colors.white70,
          ),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white54,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchHistory() {
    if (_matchResults == null || _matchResults!.items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'Chưa có lịch sử trận đấu',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Lịch sử trận đấu gần đây'),
        ..._matchResults!.items.take(5).map((match) => _buildMatchItem(match)),
      ],
    );
  }

  Widget _buildMatchItem(MatchResultItem match) {
    final resultText = match.result == 1
        ? 'Thắng'
        : match.result == 0.5
            ? 'Hòa'
            : 'Thua';
    final resultColor = match.result == 1
        ? Colors.green
        : match.result == 0.5
            ? Colors.orange
            : Colors.red;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Avatar(
                'https://slchess-dev-avatars.s3.ap-southeast-2.amazonaws.com/${match.opponentId}'),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rating: ${match.opponentRating.toInt()}',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                Text(
                  _formatDate(DateTime.parse(match.timestamp)),
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: resultColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  resultText,
                  style: TextStyle(
                    color: resultColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () async {
              final idToken = await _authService.getIdToken();
              if (idToken != null) {
                final HistoryMatchModel historyMatch = await MoveSetService()
                    .getHistoryMatch(match.matchId, idToken);

                if (historyMatch.items.isNotEmpty) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ReviewChessboard(
                        historyMatch: historyMatch,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Không thể tải dữ liệu ván cờ'),
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.analytics, color: Colors.blue),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
