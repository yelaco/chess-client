import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'chat_screen.dart';
import '../services/friendship_service.dart';
import '../services/amplify_auth_service.dart';
import '../services/user_service.dart';
import '../models/friendship_model.dart';
import '../models/user.dart';
import '../widgets/widgets.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FriendshipService _friendshipService = FriendshipService();
  final AmplifyAuthService _authService = AmplifyAuthService();
  final UserService _userService = UserService();
  String _searchQuery = '';
  bool _isLoading = true;
  String? _error;
  FriendshipModel? _friendshipList;
  FriendshipRequestModel? _friendRequests;
  final Map<String, UserModel> _friendUsers = {};
  final Map<String, UserModel> _requestUsers = {};

  @override
  void initState() {
    super.initState();
    _loadFriends();
    _loadFriendRequests();
  }

  Future<void> _loadFriends() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final idToken = await _authService.getIdToken();
      if (idToken == null) {
        throw Exception('Không thể lấy token xác thực');
      }

      final friends = await _friendshipService.getFriendshipList(idToken);

      // Load thông tin chi tiết của từng người bạn
      for (var friend in friends.items) {
        try {
          final userInfo =
              await _userService.getUserInfo(friend.friendId, idToken);
          _friendUsers[friend.friendId] = userInfo;
        } catch (e) {
          print('Lỗi khi lấy thông tin người dùng ${friend.friendId}: $e');
        }
      }

      setState(() {
        _friendshipList = friends;
        _isLoading = false;
      });
    } catch (e) {
      print(e);
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFriendRequests() async {
    try {
      final idToken = await _authService.getIdToken();
      if (idToken == null) {
        throw Exception('Không thể lấy token xác thực');
      }

      final requests = await _friendshipService.getFriendshipRequest(idToken);

      // Load thông tin chi tiết của người gửi lời mời
      for (var request in requests.items) {
        try {
          final userInfo =
              await _userService.getUserInfo(request.senderId, idToken);
          _requestUsers[request.senderId] = userInfo;
        } catch (e) {
          print('Lỗi khi lấy thông tin người dùng ${request.senderId}: $e');
        }
      }

      setState(() {
        _friendRequests = requests;
      });
    } catch (e) {
      print('Lỗi khi tải lời mời kết bạn: $e');
    }
  }

  Future<void> _handleFriendRequest(String friendId, bool accept) async {
    try {
      final idToken = await _authService.getIdToken();
      if (idToken == null) {
        throw Exception('Không thể lấy token xác thực');
      }

      bool success;
      if (accept) {
        success =
            await _friendshipService.acceptFriendRequest(idToken, friendId);
      } else {
        success =
            await _friendshipService.rejectFriendRequest(idToken, friendId);
      }

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(accept
                ? 'Đã chấp nhận lời mời kết bạn'
                : 'Đã từ chối lời mời kết bạn'),
          ),
        );
        _loadFriendRequests(); // Tải lại danh sách lời mời
        _loadFriends(); // Tải lại danh sách bạn bè
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddFriendDialog() {
    final TextEditingController friendIdController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_add,
                    color: Colors.blue,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Thêm bạn',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Nhập ID người dùng để gửi lời mời kết bạn',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: friendIdController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Nhập ID người dùng',
                    hintStyle: TextStyle(color: Colors.grey.withOpacity(0.7)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.person, color: Colors.grey),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (isLoading)
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'Hủy',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (friendIdController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Vui lòng nhập ID người dùng'),
                              ),
                            );
                            return;
                          }

                          setState(() {
                            isLoading = true;
                          });

                          try {
                            final idToken = await _authService.getIdToken();
                            if (idToken == null) {
                              throw Exception('Không thể lấy token xác thực');
                            }

                            final result = await _friendshipService.addFriend(
                              idToken,
                              friendIdController.text.trim(),
                            );

                            if (mounted) {
                              Navigator.pop(context);
                              if (result == 200) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Đã gửi lời mời kết bạn'),
                                  ),
                                );
                              } else if (result == 409) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Không thể tự kết bạn'),
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              setState(() {
                                isLoading = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Gửi lời mời',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildFriendRequests() {
    if (_friendRequests == null || _friendRequests!.items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Lời mời kết bạn',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _friendRequests!.items.length,
          itemBuilder: (context, index) {
            final request = _friendRequests!.items[index];
            final userInfo = _requestUsers[request.senderId];

            if (userInfo == null) return const SizedBox.shrink();

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Avatar(userInfo.picture),
                title: Text(
                  userInfo.username,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'Rating: ${userInfo.rating.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () =>
                          _handleFriendRequest(request.senderId, true),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () =>
                          _handleFriendRequest(request.senderId, false),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const Divider(color: Colors.white24),
      ],
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
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 16.0, top: 16.0, bottom: 16.0, right: 8.0),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm bạn bè...',
                      hintStyle:
                          TextStyle(color: Colors.white.withOpacity(0.5)),
                      prefixIcon: const Icon(Icons.search, color: Colors.white),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: IconButton(
                  icon: const Icon(Icons.person_add, color: Colors.white),
                  iconSize: 24,
                  onPressed: _showAddFriendDialog,
                  tooltip: 'Thêm bạn',
                ),
              ),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Lỗi: $_error',
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadFriends,
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFriendRequests(),
                            if (_friendshipList == null ||
                                _friendshipList!.items.isEmpty)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text(
                                    'Chưa có bạn bè nào',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _friendshipList!.items.length,
                                itemBuilder: (context, index) {
                                  final friend = _friendshipList!.items[index];
                                  final userInfo =
                                      _friendUsers[friend.friendId];
                                  final userName =
                                      userInfo?.username ?? 'Đang tải...';

                                  if (_searchQuery.isNotEmpty &&
                                      !userName.toLowerCase().contains(
                                          _searchQuery.toLowerCase())) {
                                    return const SizedBox.shrink();
                                  }

                                  return Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ListTile(
                                      leading: Avatar(userInfo!.picture),
                                      title: Text(
                                        userName,
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                      subtitle: Text(
                                        'Rating: ${userInfo.rating.toStringAsFixed(0) ?? '...'}',
                                        style:
                                            const TextStyle(color: Colors.grey),
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.message,
                                            color: Colors.white),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ChatScreen(
                                                  friend: userInfo,
                                                  conversationId:
                                                      friend.conversationId),
                                            ),
                                          );
                                        },
                                      ),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ProfileScreen(user: userInfo),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
