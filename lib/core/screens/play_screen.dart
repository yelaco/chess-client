import 'package:flutter/material.dart';
import '../constants/constants.dart'; // Đảm bảo import constants
import '../constants/app_styles.dart';
import '../services/user_service.dart';
import '../models/user.dart';
import 'package:flutter_slchess/core/services/amplify_auth_service.dart';

class PlayPage extends StatefulWidget {
  const PlayPage({super.key});

  @override
  State<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage>
    with SingleTickerProviderStateMixin {
  String? selectedTimeControl; // Biến để lưu trữ giá trị đã chọn
  final UserService _userService = UserService();
  final AmplifyAuthService _amplifyAuthService = AmplifyAuthService();
  UserModel? _user;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
    _loadUserData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _userService.getPlayer();

      if (user == null) {
        final String? accessToken = await _amplifyAuthService.getAccessToken();
        final String? idToken = await _amplifyAuthService.getIdToken();

        if (accessToken != null && idToken != null) {
          await _userService.saveSelfUserInfo(accessToken, idToken);
          final refreshedUser = await _userService.getPlayer();
          if (!mounted) return;
          setState(() {
            _user = refreshedUser;
            _isLoading = false;
          });
        }
      } else {
        if (!mounted) return;
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Lỗi khi tải thông tin người dùng: $e");
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: _isLoading
              ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: AppStyles.defaultPadding,
                    decoration: AppStyles.cardDecoration,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Chọn Chế Độ Chơi',
                          style: AppStyles.heading2,
                        ),
                        const SizedBox(height: AppStyles.defaultSpacing),
                        Container(
                          padding: AppStyles.mediumPadding,
                          decoration: AppStyles.inputDecoration,
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              hint: const Text(
                                'Chọn thời gian chơi',
                                style: AppStyles.caption,
                              ),
                              value: selectedTimeControl,
                              dropdownColor:
                                  AppStyles.primaryColor.withOpacity(0.9),
                              style: AppStyles.bodyMedium,
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedTimeControl = newValue;
                                });
                              },
                              items: timeControls.map<DropdownMenuItem<String>>(
                                  (Map<String, String> control) {
                                return DropdownMenuItem<String>(
                                  value: control['value'],
                                  child: Text(control['key']!),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppStyles.defaultSpacing),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _user == null
                                ? null
                                : () {
                                    if (selectedTimeControl == null ||
                                        selectedTimeControl!.isEmpty) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Vui lòng chọn thời gian chơi'),
                                          backgroundColor: AppStyles.errorColor,
                                        ),
                                      );
                                      return;
                                    }
                                    Navigator.pushNamed(
                                      context,
                                      '/matchmaking',
                                      arguments: {
                                        'gameMode': selectedTimeControl,
                                        'user': _user
                                      },
                                    );
                                  },
                            style: AppStyles.primaryButton,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Chơi Online'),
                          ),
                        ),
                        const SizedBox(height: AppStyles.mediumSpacing),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(context, '/offline_game');
                            },
                            style: AppStyles.secondaryButton,
                            icon: const Icon(Icons.computer),
                            label: const Text('Chơi Offline'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
