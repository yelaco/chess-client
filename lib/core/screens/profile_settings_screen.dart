import 'package:flutter/material.dart';
import '../services/amplify_auth_service.dart';
import '../services/user_service.dart';
import '../services/match_service.dart';
import '../services/moveset_service.dart';
import '../services/matchresult_service.dart';
import '../models/user.dart';
import '../models/historymatch_model.dart';
import '../models/matchresults_model.dart';
import '../constants/app_styles.dart';
import 'review_chessboard.dart';
import 'package:http/http.dart' as http;
import 'package:amplify_flutter/amplify_flutter.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final AmplifyAuthService _authService = AmplifyAuthService();
  final UserService _userService = UserService();
  final MatchResultService _matchResultService = MatchResultService();

  UserModel? _user;
  MatchResultsModel? _matchResults;
  bool _isLoading = true;
  bool _isSaving = false;
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
      final user = await _userService.getPlayer();

      if (user == null) {
        final String? idToken = await _authService.getIdToken();
        final String? accessToken = await _authService.getAccessToken();

        if (idToken != null && accessToken != null) {
          await _userService.saveSelfUserInfo(accessToken, idToken);
          final refreshedUser = await _userService.getPlayer();

          if (!mounted) return;
          setState(() {
            _user = refreshedUser;
            _isLoading = false;

            if (refreshedUser != null) {
              _usernameController.text = refreshedUser.username;
              _locateController.text = refreshedUser.locate;
            }
          });
        } else {
          throw Exception("Không thể lấy token đăng nhập");
        }
      } else {
        if (!mounted) return;
        setState(() {
          _user = user;
          _isLoading = false;
          _usernameController.text = user.username;
          _locateController.text = user.locate;
        });
      }

      // Load match history
      if (_user != null) {
        final String? idToken = await _authService.getIdToken();
        if (idToken != null) {
          final results =
              await _matchResultService.getMatchResults(_user!.id, idToken);
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

  Future<void> _saveUserData() async {
    if (_user == null) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final String? idToken = await _authService.getIdToken();

      if (idToken == null) {
        throw Exception("Không thể lấy token xác thực");
      }

      final updatedUser = UserModel(
        id: _user!.id,
        username: _usernameController.text,
        locate: _locateController.text,
        picture: _user!.picture,
        rating: _user!.rating,
        membership: _user!.membership,
        createAt: _user!.createAt,
      );

      await _userService.savePlayer(updatedUser);

      if (!mounted) return;
      setState(() {
        _user = updatedUser;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu thông tin tài khoản')),
      );
    } catch (e) {
      safePrint("Lỗi khi lưu thông tin người dùng: $e");
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $_error')),
      );
    }
  }

  Future<void> _changePassword() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2428),
        title: const Text(
          'Đổi mật khẩu',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Tính năng đổi mật khẩu sẽ được thêm sau.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Future<void> _changeAvatar() async {
    await Navigator.pushNamed(context, '/uploadImage');
    await _loadUserData();
  }

  void _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2428),
        title: const Text(
          'Đăng xuất',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _authService.signOut();
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi khi đăng xuất: $e')),
                  );
                }
              }
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin cá nhân'),
        backgroundColor: const Color(0xFF0E1416),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Đăng xuất',
          ),
        ],
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
                              GestureDetector(
                                onTap: _changeAvatar,
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(0.1),
                                        border: Border.all(
                                            color: Colors.white, width: 2),
                                      ),
                                      child: _user!.picture.isNotEmpty
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(60),
                                              child: Image.network(
                                                "${_user!.picture}/large",
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  return const Center(
                                                    child: Icon(
                                                      Icons.person,
                                                      size: 60,
                                                      color: Colors.white,
                                                    ),
                                                  );
                                                },
                                              ),
                                            )
                                          : const Center(
                                              child: Icon(
                                                Icons.person,
                                                size: 60,
                                                color: Colors.white,
                                              ),
                                            ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: Colors.white, width: 2),
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _saveUserData,
                          child: const Text('Lưu thông tin'),
                        ),

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

                        // Bảo mật
                        _buildSectionHeader('Bảo mật'),
                        _buildSettingItem(
                          icon: Icons.lock,
                          title: 'Đổi mật khẩu',
                          onTap: _changePassword,
                        ),
                        _buildSettingItem(
                          icon: Icons.security,
                          title: 'Xác thực hai lớp',
                          onTap: () {
                            // Mở màn hình xác thực 2 lớp
                          },
                        ),

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
            child: CircleAvatar(
              radius: 16,
              backgroundImage: _user != null && _user!.picture.isNotEmpty
                  ? NetworkImage("${_user!.picture}/large")
                  : null,
              backgroundColor: AppStyles.defaultAvt,
              child: _user == null || _user!.picture.isEmpty
                  ? Text(
                      _user?.username.substring(0, 1).toUpperCase() ??
                          match.opponentId.substring(0, 2).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
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
