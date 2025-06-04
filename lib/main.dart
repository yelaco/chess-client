import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_slchess/core/models/chessboard_model.dart';
import 'package:flutter_slchess/core/services/amplify_auth_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_slchess/core/models/puzzle_model.dart';
import 'package:flutter_slchess/core/models/moveset_model.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'core/screens/login_screen.dart';
import 'core/screens/homescreen.dart';
import 'core/screens/chessboard.dart';
import 'core/screens/offline_game.dart';
import 'core/screens/matchmaking.dart';
import 'core/screens/upload_image_screen.dart';
import 'core/screens/puzzle_chessboard.dart';
import 'core/screens/leaderboard_screen.dart';
import 'core/models/user.dart';
import 'core/models/matchresults_model.dart';
import 'core/services/matchresult_service.dart';
import 'core/screens/profile_settings_screen.dart';
import 'core/screens/active_matches_screen.dart';

final navigatorKey = GlobalKey<NavigatorState>();
final routeObserver = RouteObserver<PageRoute>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  // Khởi tạo Hive và đăng ký adapter
  await Hive.initFlutter();
  Hive.registerAdapter(PuzzleAdapter());
  Hive.registerAdapter(PuzzleProfileAdapter());
  Hive.registerAdapter(UserModelAdapter());
  Hive.registerAdapter(MembershipAdapter());
  Hive.registerAdapter(MoveSetAdapter());
  Hive.registerAdapter(MoveItemAdapter());
  Hive.registerAdapter(MatchResultsModelAdapter());
  Hive.registerAdapter(MatchResultItemAdapter());

  // Khởi tạo các service
  await MatchResultService.init();
  final authService = AmplifyAuthService();

  // Khởi tạo Amplify với xử lý lỗi toàn diện
  bool amplifyInitialized = false;
  int attempts = 0;
  const maxAttempts = 2;

  while (!amplifyInitialized && attempts < maxAttempts) {
    attempts++;
    try {
      print('Đang khởi tạo Amplify (lần thử $attempts)...');
      await authService.initializeAmplify();
      amplifyInitialized = true;
      print('✅ Amplify đã được khởi tạo thành công trong main()');

      // Kiểm tra xem Auth plugin có hoạt động không
      try {
        await Amplify.Auth.fetchAuthSession();
        print('✅ Auth plugin hoạt động tốt');
      } catch (e) {
        if (e.toString().contains('Auth plugin has not been added')) {
          print('❌ Auth plugin chưa được thêm vào Amplify');
          amplifyInitialized = false; // Đánh dấu là chưa khởi tạo thành công
        } else {
          print('⚠️ Lỗi khi kiểm tra Auth session: $e');
          // Có thể chưa đăng nhập, nhưng plugin vẫn hoạt động
        }
      }
    } catch (e) {
      // Nếu lỗi là "đã được cấu hình" thì vẫn coi như thành công
      if (e.toString().contains('already been configured')) {
        print('✅ Amplify đã được cấu hình trước đó, tiếp tục');
        amplifyInitialized = true;

        // Kiểm tra xem Auth plugin có hoạt động không
        try {
          await Amplify.Auth.fetchAuthSession();
          print('✅ Auth plugin hoạt động tốt');
        } catch (e2) {
          if (e2.toString().contains('Auth plugin has not been added')) {
            print('❌ Auth plugin chưa được thêm vào Amplify đã cấu hình');
            amplifyInitialized = false; // Khởi tạo không thành công
          } else {
            print('⚠️ Lỗi khi kiểm tra Auth session: $e2');
            // Có thể chưa đăng nhập, nhưng plugin vẫn hoạt động
          }
        }
      } else {
        print('❌ Lỗi khởi tạo Amplify: $e');
      }
    }

    // Nếu không thành công và còn lần thử, đợi một chút
    if (!amplifyInitialized && attempts < maxAttempts) {
      print('⏳ Đợi trước khi thử lại...');
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      navigatorObservers: [routeObserver],
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/board':
            final args = settings.arguments as ChessboardModel;
            return MaterialPageRoute(
              builder: (context) => Chessboard(
                matchModel: args.match,
                isOnline: args.isOnline,
                isWhite: args.isWhite,
              ),
            );
          case '/login':
            return MaterialPageRoute(builder: (context) => const LoginScreen());
          case '/offline_game':
            return MaterialPageRoute(
                builder: (context) => const OfflineGameScreen());
          case '/home':
            return MaterialPageRoute(builder: (context) => const HomeScreen());
          case '/upload_image':
            return MaterialPageRoute(
                builder: (context) => const UploadImageScreen());
          case '/user_ratings':
            return MaterialPageRoute(
                builder: (context) => const LeaderboardScreen());
          case '/matchmaking':
            final args = settings.arguments;
            if (args is Map) {
              return MaterialPageRoute(
                builder: (context) => MatchMakingScreen(
                  gameMode: args['gameMode'],
                  user: args['user'],
                ),
              );
            } else if (args is String) {
              // Backwards compatibility for old code
              return MaterialPageRoute(
                builder: (context) => MatchMakingScreen(gameMode: args),
              );
            } else {
              return MaterialPageRoute(
                builder: (context) => const Scaffold(
                  body: Center(
                    child: Text('Lỗi: Invalid matchmaking arguments'),
                  ),
                ),
              );
            }
          case '/profile':
            return MaterialPageRoute(
                builder: (context) => const ProfileSettingsScreen());
          case '/account_settings':
            return MaterialPageRoute(
                builder: (context) => const ProfileSettingsScreen());
          case '/active_matches':
            return MaterialPageRoute(
                builder: (context) => const ActiveMatchesScreen());
          case '/puzzle_board':
            // Kiểm tra null trước khi ép kiểu
            final args = settings.arguments;
            if (args is Map<String, dynamic>) {
              return MaterialPageRoute(
                builder: (context) => PuzzleChessboard(
                  puzzle: args['puzzle'],
                  idToken: args['idToken'],
                ),
              );
            } else {
              return MaterialPageRoute(
                builder: (context) => const Scaffold(
                  body: Center(
                    child: Text('Lỗi: Không thể tải puzzle'),
                  ),
                ),
              );
            }
          default:
            return MaterialPageRoute(builder: (context) => const HomeScreen());
        }
      },
      // Thêm xử lý deep link
      onGenerateInitialRoutes: (String initialRouteName) {
        return [
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
            settings: RouteSettings(name: initialRouteName),
          ),
        ];
      },
      // Thêm xử lý deep link
      onUnknownRoute: (RouteSettings settings) {
        // Xử lý deep link
        if (settings.name?.startsWith('slchess://') ?? false) {
          final uri = Uri.parse(settings.name!);
          final authService = AmplifyAuthService();
          authService.handleDeepLink(uri);
        }
        return MaterialPageRoute(
          builder: (context) => const HomeScreen(),
          settings: settings,
        );
      },
    );
  }
}
