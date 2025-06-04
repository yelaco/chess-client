import 'package:flutter/material.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import '../services/amplify_auth_service.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../constants/app_styles.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final AmplifyAuthService amplifyAuthService = AmplifyAuthService();
  bool _isLoading = false;
  int _retryCount = 0;
  static const int maxRetries = 3;
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
    _initAuth();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initAuth() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      safePrint('Bắt đầu khởi tạo Auth');
      await amplifyAuthService.initializeAmplify();

      // Kiểm tra xem có token trong bộ nhớ không
      final accessToken = await amplifyAuthService.getAccessToken();
      final idToken = await amplifyAuthService.getIdToken();
      final refreshToken = await amplifyAuthService.getRefreshToken();

      if (accessToken != null &&
          idToken != null &&
          refreshToken != null &&
          accessToken.isNotEmpty &&
          idToken.isNotEmpty &&
          refreshToken.isNotEmpty) {
        safePrint('Tìm thấy token trong bộ nhớ');
        // Kiểm tra token hết hạn
        if (await amplifyAuthService.isTokenExpired(accessToken)) {
          safePrint("Token đã hết hạn, thử refresh token");

          try {
            // Thử refresh token bằng cách fetch session mới
            final session = await Amplify.Auth.fetchAuthSession();
            if (session is CognitoAuthSession) {
              final tokens = session.userPoolTokensResult.value;

              // Lưu token mới
              await amplifyAuthService.saveTokens(tokens.accessToken.raw,
                  tokens.idToken.raw, tokens.refreshToken);

              safePrint("Đã refresh token thành công");
              // Đảm bảo thông tin người dùng được lấy sau khi có token mới
              await amplifyAuthService.fetchAndSaveUserInfo();
              safePrint("Chuyển về home sau khi lấy thông tin người dùng");
              amplifyAuthService.navigateToHome();
              return;
            }
          } catch (e) {
            safePrint("Không thể refresh token: $e");
            // Nếu không thể refresh token, đăng xuất
            await amplifyAuthService.signOut();
            setState(() {
              _isLoading = false;
            });
            return;
          }
        } else {
          safePrint("Token còn hiệu lực");
          // Đảm bảo thông tin người dùng được lấy trước khi chuyển màn hình
          await amplifyAuthService.fetchAndSaveUserInfo();
          safePrint("Chuyển về home sau khi lấy thông tin người dùng");
          amplifyAuthService.navigateToHome();
          return;
        }
      }

      // Nếu không có token hoặc token không hợp lệ
      safePrint("Không tìm thấy token hợp lệ, yêu cầu đăng nhập");
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      safePrint('Lỗi khởi tạo Auth: $e');

      // Thử lại nếu chưa quá số lần cho phép
      if (_retryCount < maxRetries) {
        _retryCount++;
        safePrint('Thử lại lần $_retryCount');
        await Future.delayed(const Duration(seconds: 2));
        _initAuth();
        return;
      }

      // Nếu đã thử lại quá nhiều lần
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Không thể kết nối đến máy chủ. Vui lòng thử lại sau.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/bg_dark.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: AppStyles.defaultPadding,
                  decoration: AppStyles.cardDecoration,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      Container(
                        decoration: const BoxDecoration(
                          borderRadius: AppStyles.largeBorderRadius,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              offset: Offset(-1, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const ClipRRect(
                          borderRadius: AppStyles.largeBorderRadius,
                          child: Image(
                            image: AssetImage('assets/logo.png'),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppStyles.defaultSpacing),
                      const Text(
                        'SLChess',
                        style: AppStyles.heading2,
                      ),
                      const SizedBox(height: AppStyles.defaultSpacing),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: AppStyles.primaryButton,
                          onPressed: () {
                            amplifyAuthService.signIn(context);
                          },
                          child: const Text(
                            'Đăng nhập với Cognito',
                            style: AppStyles.bodyMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
