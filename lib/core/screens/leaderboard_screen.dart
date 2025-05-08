import 'package:flutter/material.dart';
import '../models/leaderboard_model.dart';
import '../services/leaderboard_service.dart';
import '../services/amplify_auth_service.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../services/user_ratings_service.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../constants/app_styles.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final AmplifyAuthService _authService = AmplifyAuthService();
  final UserService _userService = UserService();
  final UserRatingsService _userRatingsService = UserRatingsService();

  // Dữ liệu cho bảng xếp hạng API
  List<UserRating> _apiRatings = [];
  bool _isLoading = true;
  String? _error;

  // Lưu trữ thông tin người dùng đã tải
  final Map<String, UserModel> _userCache = {};
  String? _idToken;

  @override
  void initState() {
    super.initState();
    _loadApiRatings();
  }

  // Load dữ liệu từ API userRatings
  Future<void> _loadApiRatings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final idToken = await _authService.getIdToken();

      if (idToken == null) {
        setState(() {
          _error = 'Chưa đăng nhập';
          _isLoading = false;
        });
        return;
      }

      _idToken = idToken;

      final result =
          await _userRatingsService.getUserRatings(idToken, limit: 20);

      setState(() {
        _apiRatings = result.items;
        _isLoading = false;
      });

      // Tải thông tin người dùng cho mỗi ID
      _loadUserDetails();
    } catch (e) {
      safePrint('Lỗi khi lấy dữ liệu xếp hạng API: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Tải thông tin người dùng cho mỗi xếp hạng
  Future<void> _loadUserDetails() async {
    if (_idToken == null) return;

    for (var rating in _apiRatings) {
      try {
        // Kiểm tra xem đã tải thông tin người dùng này chưa
        if (!_userCache.containsKey(rating.userId)) {
          final user = await _userService.getUserInfo(rating.userId, _idToken!);
          setState(() {
            _userCache[rating.userId] = user;
          });
        }
      } catch (e) {
        safePrint('Không thể lấy thông tin người dùng ${rating.userId}: $e');
      }
    }
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
      child: _buildRatingsContent(),
    );
  }

  Widget _buildRatingsContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppStyles.primaryColor,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Lỗi: $_error',
              style: AppStyles.bodyMedium.copyWith(color: Colors.white),
            ),
            const SizedBox(height: AppStyles.defaultSpacing),
            ElevatedButton(
              style: AppStyles.primaryButton,
              onPressed: _loadApiRatings,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_apiRatings.isEmpty) {
      return Center(
        child: Text(
          'Không có dữ liệu xếp hạng',
          style: AppStyles.bodyMedium.copyWith(color: Colors.white),
        ),
      );
    }

    return Column(
      children: [
        _buildApiRatingsHeader(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadApiRatings,
            color: AppStyles.primaryColor,
            backgroundColor: AppStyles.secondaryColor,
            child: ListView.builder(
              itemCount: _apiRatings.length,
              itemBuilder: (context, index) {
                final rating = _apiRatings[index];
                return _buildApiRatingRow(rating, index);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildApiRatingsHeader() {
    return Container(
      padding: AppStyles.defaultPadding,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        border: const Border(
          bottom: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              'XH',
              style: AppStyles.bodyMedium.copyWith(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppStyles.defaultSpacing),
          Expanded(
            child: Text(
              'Người chơi',
              style: AppStyles.bodyMedium.copyWith(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            'Điểm',
            style: AppStyles.bodyMedium.copyWith(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiRatingRow(UserRating rating, int index) {
    final user = _userCache[rating.userId];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: index % 2 == 0
            ? Colors.black.withOpacity(0.3)
            : Colors.black.withOpacity(0.5),
        borderRadius: AppStyles.defaultBorderRadius,
      ),
      child: Padding(
        padding: AppStyles.smallPadding,
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: _buildRankWidget(index + 1),
            ),
            const SizedBox(width: AppStyles.defaultSpacing),
            Expanded(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: user != null && user.picture.isNotEmpty
                        ? NetworkImage("${user.picture}/large")
                        : null,
                    backgroundColor: AppStyles.defaultAvt,
                    child: user == null || user.picture.isEmpty
                        ? Text(
                            user?.username.substring(0, 1).toUpperCase() ??
                                rating.userId.substring(0, 2).toUpperCase(),
                            style: AppStyles.bodySmall.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: AppStyles.smallSpacing),
                  Expanded(
                    child: Text(
                      user?.username ??
                          'ID: ${rating.userId.substring(0, 10)}...',
                      style: AppStyles.bodyMedium.copyWith(
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: AppStyles.smallPadding,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: AppStyles.defaultBorderRadius,
              ),
              child: Text(
                '${rating.rating}',
                style: AppStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankWidget(int rank) {
    if (rank <= 3) {
      return Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: _getRankColor(rank),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _getRankColor(rank).withOpacity(0.5),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Text(
            '$rank',
            style: AppStyles.bodyMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return Text(
      '$rank',
      style: AppStyles.bodyMedium.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
      textAlign: TextAlign.center,
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return AppStyles.warningColor;
      case 2:
        return AppStyles.infoColor;
      case 3:
        return AppStyles.errorColor;
      default:
        return AppStyles.secondaryColor;
    }
  }
}
