import 'package:flutter/material.dart';
import '../services/activematch_service.dart';
import '../models/activematch_model.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../services/user_service.dart';
import '../services/amplify_auth_service.dart';

class ActiveMatchesScreen extends StatefulWidget {
  const ActiveMatchesScreen({super.key});

  @override
  State<ActiveMatchesScreen> createState() => _ActiveMatchesScreenState();
}

class _ActiveMatchesScreenState extends State<ActiveMatchesScreen> {
  final SpectateService _spectateService = SpectateService();
  final AmplifyAuthService _amplifyAuthService = AmplifyAuthService();
  List<ActiveMatch> _matches = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadActiveMatches();
  }

  Future<void> _loadActiveMatches() async {
    try {
      final idToken = await _amplifyAuthService.getIdToken();

      if (idToken == null) {
        setState(() {
          _error = 'Không thể xác thực người dùng';
          _isLoading = false;
        });
        return;
      }

      final response = await _spectateService.getActiveMatches(idToken);
      setState(() {
        _matches = response.items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Lỗi khi tải danh sách trận đấu: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Trận đấu đang diễn ra',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0E1416),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg_dark.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadActiveMatches,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_matches.isEmpty) {
      return const Center(
        child: Text(
          'Không có trận đấu nào đang diễn ra',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _matches.length,
      itemBuilder: (context, index) {
        final match = _matches[index];
        return Card(
          color: Colors.black.withOpacity(0.7),
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              '${match.player1.username}(${match.player1.rating.toInt()}) vs ${match.player2.username}(${match.player2.rating.toInt()})',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Chế độ: ${match.gameMode}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            trailing: ElevatedButton(
              onPressed: () {
                // TODO: Xử lý khi người dùng muốn xem trận đấu
              },
              child: const Text('Xem'),
            ),
          ),
        );
      },
    );
  }
}
