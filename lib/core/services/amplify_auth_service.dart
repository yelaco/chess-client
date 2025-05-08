import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter_slchess/main.dart';
import './user_service.dart';
import './puzzle_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';

// Enum để quản lý trạng thái đăng nhập
enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
  cancelled
}

class AmplifyAuthService {
  static final AmplifyAuthService _instance = AmplifyAuthService._internal();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final UserService _userService = UserService();
  final PuzzleService _puzzleService = PuzzleService();
  bool _isInitialized = false;

  // Stream controller để quản lý trạng thái đăng nhập
  final _authStateController = StreamController<AuthState>.broadcast();
  Stream<AuthState> get authStateStream => _authStateController.stream;

  // Biến để theo dõi số lần retry
  int _retryCount = 0;
  static const int maxRetries = 3;

  // Biến để theo dõi URL callback
  String? _pendingCallbackUrl;

  // Timer để refresh token
  Timer? _refreshTokenTimer;

  // Constants cho secure storage
  static const String ACCESS_TOKEN_KEY = "ACCESS_TOKEN";
  static const String ID_TOKEN_KEY = "ID_TOKEN";
  static const String REFRESH_TOKEN_KEY = "REFRESH_TOKEN";

  factory AmplifyAuthService() {
    return _instance;
  }

  AmplifyAuthService._internal();

  Future<void> initializeAmplify() async {
    if (_isInitialized) {
      safePrint('Amplify đã được khởi tạo trước đó, bỏ qua');
      return;
    }

    try {
      // Kiểm tra xem Amplify đã được cấu hình chưa
      bool needConfiguration = !Amplify.isConfigured;

      // Thêm Auth plugin - luôn thử thêm trước khi cấu hình
      final auth = AmplifyAuthCognito();
      bool pluginAdded = false;

      try {
        if (!Amplify.isConfigured) {
          await Amplify.addPlugin(auth);
          pluginAdded = true;
          safePrint('Đã thêm Auth plugin thành công');
        } else {
          // Đối với Amplify đã cấu hình, kiểm tra nếu Auth plugin đã được thêm
          try {
            // Thử gọi một API của Auth để kiểm tra nếu plugin đã được thêm
            await Amplify.Auth.fetchAuthSession();
            pluginAdded = true;
            safePrint('Auth plugin đã tồn tại');
          } catch (e) {
            if (e.toString().contains('Auth plugin has not been added')) {
              safePrint(
                  'Lỗi: Auth plugin chưa được thêm vào Amplify đã cấu hình');
              // Không thể thêm plugin vào Amplify đã cấu hình
              // Cần reset Amplify hoặc khởi động lại ứng dụng
              throw Exception(
                  'Không thể thêm Auth plugin vào Amplify đã cấu hình. Cần khởi động lại ứng dụng.');
            } else {
              // Lỗi khác khi kiểm tra Auth plugin
              rethrow;
            }
          }
        }
      } catch (e) {
        if (e.toString().contains('has already been added')) {
          safePrint('Auth plugin đã được thêm trước đó');
          pluginAdded = true;
        } else if (!e.toString().contains('Không thể thêm Auth plugin')) {
          // Nếu không phải lỗi "không thể thêm plugin", ném lại lỗi
          rethrow;
        }
      }

      // Nếu plugin đã được thêm thành công và cần cấu hình
      if (pluginAdded && needConfiguration) {
        // Lấy thông tin cấu hình từ .env
        final cognitoUrl = dotenv.env['COGNITO_URL'];
        final cognitoClientId = dotenv.env['COGNITO_CLIENT_ID'];

        if (cognitoUrl == null || cognitoClientId == null) {
          throw Exception('Thiếu thông tin cấu hình Cognito trong file .env');
        }

        // Trích xuất region từ URL Cognito
        String region = 'ap-southeast-2'; // Mặc định
        final regionRegex = RegExp(r'auth\.([a-z0-9-]+)\.amazoncognito');
        final regionMatch = regionRegex.firstMatch(cognitoUrl);
        if (regionMatch != null && regionMatch.groupCount >= 1) {
          region = regionMatch.group(1) ?? region;
        }

        // Tạo User Pool ID từ URL và region
        final domainParts = cognitoUrl.split('.');
        String userPoolId = "";
        if (domainParts.isNotEmpty) {
          userPoolId = "${region}_${domainParts[0]}";
        } else {
          throw Exception('Không thể xác định User Pool ID từ Cognito URL');
        }

        // Thiết lập đường dẫn chuyển hướng phù hợp với nền tảng
        String signInRedirectURI;
        String signOutRedirectURI;

        if (kIsWeb) {
          // Web
          signInRedirectURI = '${Uri.base.origin}/callback';
          signOutRedirectURI = '${Uri.base.origin}/signout';
        } else {
          // Mobile
          signInRedirectURI = 'slchess://callback/';
          signOutRedirectURI = 'slchess://signout/';
        }

        // Cấu hình JSON cho Amplify
        final jsonConfig = {
          "UserAgent": "aws-amplify-cli/2.0",
          "Version": "1.0",
          "auth": {
            "plugins": {
              "awsCognitoAuthPlugin": {
                "UserAgent": "aws-amplify/cli",
                "Version": "0.1.0",
                "IdentityManager": {"Default": {}},
                "CognitoUserPool": {
                  "Default": {
                    "PoolId": userPoolId,
                    "AppClientId": cognitoClientId,
                    "Region": region
                  }
                },
                "Auth": {
                  "Default": {
                    "authenticationFlowType": "USER_SRP_AUTH",
                    "OAuth": {
                      "WebDomain": cognitoUrl,
                      "AppClientId": cognitoClientId,
                      "SignInRedirectURI": signInRedirectURI,
                      "SignOutRedirectURI": signOutRedirectURI,
                      "Scopes": [
                        "email",
                        "openid",
                        "phone",
                        "aws.cognito.signin.user.admin"
                      ]
                    }
                  }
                }
              }
            }
          }
        };

        // In thông tin cấu hình scopes
        final scopes = (jsonConfig["auth"] as Map)["plugins"] as Map;
        final cognitoPlugin = scopes["awsCognitoAuthPlugin"] as Map;
        final authConfig = cognitoPlugin["Auth"] as Map;
        final defaultAuth = authConfig["Default"] as Map;
        final oauth = defaultAuth["OAuth"] as Map;
        final configuredScopes = oauth["Scopes"] as List;
        safePrint('Đã cấu hình Amplify với các scopes: $configuredScopes');

        try {
          // Cố gắng cấu hình Amplify
          await Amplify.configure(jsonEncode(jsonConfig));
          safePrint('Đã cấu hình Amplify thành công');

          // Kiểm tra xem Auth plugin có hoạt động không
          try {
            await Amplify.Auth.fetchAuthSession();
            safePrint('Auth plugin hoạt động tốt');
          } catch (e) {
            safePrint('Lỗi khi kiểm tra Auth plugin: $e');
            throw Exception('Auth plugin không hoạt động sau khi cấu hình: $e');
          }
        } catch (e) {
          if (e.toString().contains('already been configured')) {
            safePrint(
                'Amplify đã được cấu hình trước đó, đánh dấu là đã khởi tạo');
          } else {
            rethrow;
          }
        }
      } else if (!pluginAdded) {
        throw Exception('Không thể thêm Auth plugin vào Amplify');
      } else if (Amplify.isConfigured) {
        safePrint('Amplify đã được cấu hình, không cần cấu hình lại');
      }

      _isInitialized = true;
      safePrint('Amplify đã được khởi tạo thành công 🎉');
    } on AmplifyException catch (e) {
      safePrint('Lỗi AmplifyException khi khởi tạo Amplify: ${e.message}');
      // Kiểm tra xem có phải lỗi "đã được cấu hình" không
      if (e.message.contains('already been configured')) {
        _isInitialized = true;
        safePrint('Đánh dấu Amplify đã khởi tạo do đã được cấu hình trước đó');
        return; // Không ném exception nếu đã được cấu hình
      }
      throw Exception(
          'Lỗi AmplifyException khi khởi tạo Amplify: ${e.message}');
    } catch (e) {
      safePrint('Lỗi không xác định khi khởi tạo Amplify: $e');
      // Kiểm tra xem có phải lỗi "đã được cấu hình" không
      if (e.toString().contains('already been configured')) {
        _isInitialized = true;
        safePrint('Đánh dấu Amplify đã khởi tạo do đã được cấu hình trước đó');
        return; // Không ném exception nếu đã được cấu hình
      }
      throw Exception('Lỗi không xác định khi khởi tạo Amplify: $e');
    }
  }

  // Phương thức public để truy cập từ bên ngoài
  Future<void> fetchAndSaveUserInfo() async {
    return _fetchAndSaveUserInfo();
  }

  // Lấy thông tin người dùng sau khi đăng nhập
  Future<void> _fetchAndSaveUserInfo() async {
    try {
      // Kiểm tra session trước
      final session =
          await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;

      if (!session.isSignedIn) {
        safePrint("Người dùng chưa đăng nhập, chuyển về trang đăng nhập");
        if (navigatorKey.currentContext != null) {
          Navigator.pushNamedAndRemoveUntil(
            navigatorKey.currentContext!,
            '/login',
            (route) => false,
          );
        }
        return;
      }

      // Lấy token từ Cognito
      final tokens = session.userPoolTokensResult.value;

      // Lấy token gốc từ đối tượng JWT
      String? accessTokenStr = tokens.accessToken.raw;
      String? idTokenStr = tokens.idToken.raw;
      String? refreshTokenStr = tokens.refreshToken;

      // Kiểm tra token hết hạn
      if (await isTokenExpired(accessTokenStr)) {
        safePrint("Token đã hết hạn, chuyển về trang đăng nhập");
        if (navigatorKey.currentContext != null) {
          Navigator.pushNamedAndRemoveUntil(
            navigatorKey.currentContext!,
            '/login',
            (route) => false,
          );
        }
        return;
      }

      // Lưu token vào secure storage
      await _storage.write(key: ACCESS_TOKEN_KEY, value: accessTokenStr);
      await _storage.write(key: ID_TOKEN_KEY, value: idTokenStr);
      await _storage.write(key: REFRESH_TOKEN_KEY, value: refreshTokenStr);

      safePrint("Đã lưu các token thành công");

      // Debug: in ra một phần của token để kiểm tra
      safePrint(
          "Access Token (partial): ${accessTokenStr.substring(0, 20)}...");
      safePrint("ID Token (partial): ${idTokenStr.substring(0, 20)}...");

      // Lưu thông tin người dùng bằng access token
      await _userService.saveSelfUserInfo(accessTokenStr, idTokenStr);

      // Sau khi lưu thông tin người dùng thành công, mới xóa cache puzzle
      await _puzzleService.clearAllPuzzleCaches();
    } catch (e) {
      safePrint("Lỗi khi lấy thông tin người dùng: $e");
      // Nếu có lỗi, chuyển về trang đăng nhập
      if (navigatorKey.currentContext != null) {
        Navigator.pushNamedAndRemoveUntil(
          navigatorKey.currentContext!,
          '/login',
          (route) => false,
        );
      }
    }
  }

  // Kiểm tra xem token đã hết hạn chưa
  Future<bool> isTokenExpired(String token) async {
    try {
      // Phân tích token JWT
      final parts = token.split('.');
      if (parts.length != 3) {
        safePrint('Token không đúng định dạng JWT');
        return true; // Coi như token đã hết hạn nếu sai định dạng
      }

      // Giải mã phần payload (phần thứ 2)
      String normalizedPayload = base64Url.normalize(parts[1]);
      final payloadJson = utf8.decode(base64Url.decode(normalizedPayload));
      final payload = jsonDecode(payloadJson);

      // Kiểm tra thời gian hết hạn
      if (payload.containsKey('exp')) {
        final exp = payload['exp'];
        final expiryDateTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        final currentTime = DateTime.now();

        // Thêm buffer time 5 phút để tránh trường hợp token hết hạn ngay sau khi kiểm tra
        const bufferTime = Duration(minutes: 5);
        final expiryWithBuffer = expiryDateTime.subtract(bufferTime);

        safePrint('Token hết hạn vào: $expiryDateTime');
        safePrint('Thời gian hiện tại: $currentTime');
        safePrint('Thời gian hết hạn với buffer: $expiryWithBuffer');

        return currentTime.isAfter(expiryWithBuffer);
      } else {
        safePrint('Token không có thông tin hết hạn');
        return true; // Coi như token đã hết hạn nếu không có thông tin
      }
    } catch (e) {
      safePrint('Lỗi khi kiểm tra hạn token: $e');
      return true; // Coi như token đã hết hạn nếu có lỗi
    }
  }

  // Thực hiện đăng nhập với giao diện Amplify
  Future<void> signIn(BuildContext context) async {
    try {
      // Reset retry count
      _retryCount = 0;

      // Cập nhật trạng thái loading
      _authStateController.add(AuthState.loading);

      safePrint('Bắt đầu đăng nhập với WebUI');

      // Gọi API để đăng nhập
      final response = await Amplify.Auth.signInWithWebUI(
        provider: AuthProvider.cognito,
        options: const SignInWithWebUIOptions(),
      );

      safePrint('Kết quả signInWithWebUI: ${response.isSignedIn}');

      if (!response.isSignedIn) {
        throw Exception('Đăng nhập không thành công');
      }

      safePrint('Đăng nhập thành công, đang lấy session mới');

      // Lấy session mới sau khi đăng nhập
      final session = await Amplify.Auth.fetchAuthSession();
      safePrint('Loại session: ${session.runtimeType}');

      if (session is CognitoAuthSession) {
        final tokens = session.userPoolTokensResult.value;

        safePrint('Kiểm tra token');
        if (tokens.accessToken.raw.isEmpty ||
            tokens.idToken.raw.isEmpty ||
            tokens.refreshToken.isEmpty) {
          safePrint('Token không hợp lệ');
          throw Exception('Token không hợp lệ sau khi đăng nhập');
        }

        safePrint(
            'Access Token: ${tokens.accessToken.raw.substring(0, 20)}...');
        safePrint('ID Token: ${tokens.idToken.raw.substring(0, 20)}...');

        safePrint('Bắt đầu lưu token');
        // Lưu token mới
        await saveTokens(
            tokens.accessToken.raw, tokens.idToken.raw, tokens.refreshToken);

        safePrint('Đã lưu token mới thành công');

        safePrint('Bắt đầu lấy thông tin người dùng');
        // Lấy và lưu thông tin người dùng
        await _fetchAndSaveUserInfo();

        safePrint('Bắt đầu refresh token timer');
        // Bắt đầu refresh token timer
        _startRefreshTokenTimer();

        _authStateController.add(AuthState.authenticated);

        safePrint('Chuyển hướng về màn hình chính');
        // Chuyển hướng về màn hình chính
        if (navigatorKey.currentContext != null) {
          Navigator.pushNamedAndRemoveUntil(
            navigatorKey.currentContext!,
            '/home',
            (route) => false,
          );
        }
      } else {
        safePrint('Session không phải CognitoAuthSession');
        throw Exception('Không thể lấy session sau khi đăng nhập');
      }
    } catch (e) {
      safePrint('Lỗi khi đăng nhập: $e');
      _authStateController.add(AuthState.error);

      // Nếu có lỗi, đăng xuất để làm sạch trạng thái
      await signOut();

      // Chuyển hướng về màn hình đăng nhập
      if (navigatorKey.currentContext != null) {
        Navigator.pushNamedAndRemoveUntil(
          navigatorKey.currentContext!,
          '/login',
          (route) => false,
        );
      }
    }
  }

  // Xử lý callback URL từ deep link
  Future<void> handleCallbackUrl(String url) async {
    try {
      _pendingCallbackUrl = url;
      _authStateController.add(AuthState.loading);

      // Parse URL để lấy authorization code
      final uri = Uri.parse(url);
      final code = uri.queryParameters['code'];

      if (code == null) {
        throw Exception('Không tìm thấy authorization code trong URL');
      }

      safePrint('Nhận được authorization code: $code');

      // Exchange code lấy token
      final cognitoUrl = dotenv.env['COGNITO_URL'];
      final cognitoClientId = dotenv.env['COGNITO_CLIENT_ID'];

      if (cognitoUrl == null || cognitoClientId == null) {
        throw Exception('Thiếu thông tin cấu hình Cognito');
      }

      // Gọi API để exchange code
      final response = await Amplify.Auth.signInWithWebUI(
        provider: AuthProvider.cognito,
        options: const SignInWithWebUIOptions(),
      );

      if (!response.isSignedIn) {
        throw Exception('Đăng nhập không thành công');
      }

      print("Đăng nhập thành công");

      // Lấy session mới sau khi đăng nhập
      final session = await Amplify.Auth.fetchAuthSession();
      if (session is CognitoAuthSession) {
        final tokens = session.userPoolTokensResult.value;

        if (tokens.accessToken.raw.isEmpty ||
            tokens.idToken.raw.isEmpty ||
            tokens.refreshToken.isEmpty) {
          throw Exception('Token không hợp lệ sau khi đăng nhập');
        }

        safePrint(
            'Access Token: ${tokens.accessToken.raw.substring(0, 20)}...');
        safePrint('ID Token: ${tokens.idToken.raw.substring(0, 20)}...');

        // Lưu token mới
        await saveTokens(
            tokens.accessToken.raw, tokens.idToken.raw, tokens.refreshToken);

        safePrint('Đã lưu token mới thành công');

        // Lấy và lưu thông tin người dùng
        await _fetchAndSaveUserInfo();

        // Bắt đầu refresh token timer
        _startRefreshTokenTimer();

        _authStateController.add(AuthState.authenticated);
        _pendingCallbackUrl = null;

        // Chuyển hướng về màn hình chính
        if (navigatorKey.currentContext != null) {
          Navigator.pushNamedAndRemoveUntil(
            navigatorKey.currentContext!,
            '/home',
            (route) => false,
          );
        }
      } else {
        throw Exception('Không thể lấy session sau khi đăng nhập');
      }
    } catch (e) {
      safePrint('Lỗi khi xử lý callback URL: $e');
      _authStateController.add(AuthState.error);

      // Nếu có lỗi, đăng xuất để làm sạch trạng thái
      await signOut();

      // Chuyển hướng về màn hình đăng nhập
      if (navigatorKey.currentContext != null) {
        Navigator.pushNamedAndRemoveUntil(
          navigatorKey.currentContext!,
          '/login',
          (route) => false,
        );
      }
    }
  }

  // Xử lý deep link
  Future<void> handleDeepLink(Uri uri) async {
    try {
      safePrint('Bắt đầu xử lý deep link: $uri');
      if (uri.scheme == 'slchess') {
        safePrint('Scheme hợp lệ: slchess');
        if (uri.host == 'callback') {
          safePrint('Host là callback, bắt đầu xử lý callback URL');
          // Xử lý callback URL
          await handleCallbackUrl(uri.toString());
        } else if (uri.host == 'signout') {
          safePrint('Host là signout, bắt đầu đăng xuất');
          // Xử lý signout URL
          await signOut();
        } else if (uri.host == 'cancel') {
          safePrint('Host là cancel, hủy đăng nhập');
          // Xử lý khi người dùng hủy đăng nhập
          _authStateController.add(AuthState.cancelled);
          if (navigatorKey.currentContext != null) {
            Navigator.pushNamedAndRemoveUntil(
              navigatorKey.currentContext!,
              '/login',
              (route) => false,
            );
          }
        } else {
          safePrint('Host không hợp lệ: ${uri.host}');
        }
      } else {
        safePrint('Scheme không hợp lệ: ${uri.scheme}');
      }
    } catch (e) {
      safePrint('Lỗi khi xử lý deep link: $e');
      _authStateController.add(AuthState.error);
    }
  }

  // Bắt đầu timer để refresh token
  void _startRefreshTokenTimer() {
    // Hủy timer cũ nếu có
    _refreshTokenTimer?.cancel();

    // Thiết lập timer mới để refresh token trước khi hết hạn 5 phút
    _refreshTokenTimer =
        Timer.periodic(const Duration(minutes: 55), (timer) async {
      try {
        await _refreshToken();
      } catch (e) {
        safePrint('Lỗi khi refresh token: $e');
        // Nếu không thể refresh token, đăng xuất người dùng
        await signOut();
      }
    });
  }

  // Refresh token
  Future<void> _refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: REFRESH_TOKEN_KEY);
      if (refreshToken == null) {
        throw Exception('Không tìm thấy refresh token');
      }

      // Gọi API refresh token
      final result = await Amplify.Auth.fetchAuthSession();
      if (result is CognitoAuthSession) {
        final tokens = result.userPoolTokensResult.value;

        // Lưu token mới
        await _storage.write(
            key: ACCESS_TOKEN_KEY, value: tokens.accessToken.raw);
        await _storage.write(key: ID_TOKEN_KEY, value: tokens.idToken.raw);
        await _storage.write(
            key: REFRESH_TOKEN_KEY, value: tokens.refreshToken);

        safePrint('Đã refresh token thành công');
      }
    } catch (e) {
      safePrint('Lỗi khi refresh token: $e');
      rethrow;
    }
  }

  // Cập nhật phương thức signOut để hủy refresh token timer
  Future<void> signOut() async {
    try {
      // Hủy refresh token timer
      _refreshTokenTimer?.cancel();
      _refreshTokenTimer = null;

      // Xóa token và thông tin người dùng
      await _storage.delete(key: ACCESS_TOKEN_KEY);
      await _storage.delete(key: ID_TOKEN_KEY);
      await _storage.delete(key: REFRESH_TOKEN_KEY);
      await _userService.clearUserData();

      // Đăng xuất mà không chuyển hướng
      await Amplify.Auth.signOut(
        options: const SignOutOptions(
          globalSignOut: false,
        ),
      );

      // Cập nhật trạng thái
      _authStateController.add(AuthState.unauthenticated);

      // Chuyển thẳng về màn hình đăng nhập
      if (navigatorKey.currentContext != null) {
        Navigator.pushNamedAndRemoveUntil(
          navigatorKey.currentContext!,
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      safePrint('Lỗi đăng xuất: $e');
      // Nếu có lỗi, vẫn cố gắng chuyển về màn hình đăng nhập
      if (navigatorKey.currentContext != null) {
        Navigator.pushNamedAndRemoveUntil(
          navigatorKey.currentContext!,
          '/login',
          (route) => false,
        );
      }
    }
  }

  Future<bool> isSignedIn() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      return session.isSignedIn;
    } catch (e) {
      return false;
    }
  }

  void navigateToHome() {
    Navigator.pushReplacementNamed(
      navigatorKey.currentContext!,
      '/home',
    );
  }

  Future<String?> getAccessToken() async {
    return _storage.read(key: ACCESS_TOKEN_KEY);
  }

  Future<String?> getIdToken() async {
    return _storage.read(key: ID_TOKEN_KEY);
  }

  Future<String?> getRefreshToken() async {
    return _storage.read(key: REFRESH_TOKEN_KEY);
  }

  // Phương thức thay đổi mật khẩu
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      await Amplify.Auth.updatePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      return true;
    } on AmplifyException catch (e) {
      safePrint('Lỗi khi đổi mật khẩu: ${e.message}');

      // Xử lý lỗi thiếu quyền
      if (e.message.contains('Access Token does not have required scopes')) {
        // Thông báo lỗi rõ ràng hơn
        throw Exception(
            'Không có đủ quyền để đổi mật khẩu. Vui lòng đăng nhập lại với đầy đủ quyền.');
      }

      throw Exception('Lỗi khi đổi mật khẩu: ${e.message}');
    } catch (e) {
      safePrint('Lỗi không xác định khi đổi mật khẩu: $e');
      throw Exception('Lỗi không xác định khi đổi mật khẩu: $e');
    }
  }

  // Phương thức đổi mật khẩu thông qua đăng nhập lại
  Future<bool> changePasswordWithReauthentication(
      BuildContext context, String oldPassword, String newPassword) async {
    try {
      // Đăng xuất trước để làm mới token
      await signOut();

      // Hiển thị thông báo
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập lại để đổi mật khẩu')),
      );

      // Chuyển về màn hình đăng nhập
      Navigator.pushReplacementNamed(
        navigatorKey.currentContext!,
        '/login',
      );

      return false; // Chưa thực hiện đổi mật khẩu
    } catch (e) {
      safePrint('Lỗi khi chuẩn bị đổi mật khẩu: $e');
      throw Exception('Lỗi khi chuẩn bị đổi mật khẩu: $e');
    }
  }

  // Phương thức public để lưu token
  Future<void> saveTokens(
      String accessToken, String idToken, String refreshToken) async {
    await _storage.write(key: ACCESS_TOKEN_KEY, value: accessToken);
    await _storage.write(key: ID_TOKEN_KEY, value: idToken);
    await _storage.write(key: REFRESH_TOKEN_KEY, value: refreshToken);
  }

  // Dispose resources
  void dispose() {
    _refreshTokenTimer?.cancel();
    _authStateController.close();
  }
}
