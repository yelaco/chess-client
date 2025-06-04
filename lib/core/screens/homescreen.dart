import 'package:flutter/material.dart';

import 'play_screen.dart';
import 'puzzle_screen.dart';
import 'leaderboard_screen.dart';
import 'analysis_screen.dart';
import 'profile_settings_screen.dart';
import 'friends_screen.dart';
// import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SLChess',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: const Color(0xFF0E1416),
        elevation: 0,
        automaticallyImplyLeading: false, // Ẩn nút quay lại
        actions: [
          IconButton(
            icon: const Icon(Icons.sports_esports, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/active_matches');
            },
            tooltip: 'Xem trận đấu đang diễn ra',
            iconSize: 28,
          ),
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
            tooltip: 'Thông tin cá nhân',
            iconSize: 28,
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
        child: IndexedStack(
          index: _currentIndex,
          children: const [
            PlayPage(),
            PuzzleScreen(),
            AnalysisScreen(),
            LeaderboardScreen(),
            FriendsScreen(),
            // SettingsPage(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0E1416),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTap,
          backgroundColor: const Color(0xFF0E1416),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.play_arrow),
              label: "Chơi",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.extension),
              label: "Câu đố",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics),
              label: "Phân tích",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.leaderboard),
              label: "Xếp hạng",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: "Bạn bè",
            ),
          ],
        ),
      ),
    );
  }
}
