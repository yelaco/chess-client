import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/amplify_auth_service.dart';
import '../config/amplifyconfiguration.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AmplifySettingsScreen extends StatefulWidget {
  const AmplifySettingsScreen({super.key});

  @override
  State<AmplifySettingsScreen> createState() => _AmplifySettingsScreenState();
}

class _AmplifySettingsScreenState extends State<AmplifySettingsScreen> {
  final AmplifyAuthService _authService = AmplifyAuthService();
  bool _isLoading = false;
  String _cognitoUrl = dotenv.env['COGNITO_URL'] ?? '';
  String _cognitoClientId = dotenv.env['COGNITO_CLIENT_ID'] ?? '';
  String _amplifyConfig = '';

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final config = AmplifyConfig.amplifyConfig;
      setState(() {
        _amplifyConfig = config;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _amplifyConfig = 'Lỗi khi tải cấu hình: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    // Lưu cài đặt trong môi trường phát triển
    // Trong môi trường thực tế cần triển khai lưu cài đặt vào file cấu hình hoặc biến môi trường
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã lưu cài đặt!')),
    );
  }

  Future<void> _reinitializeAmplify() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.initializeAmplify();
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Khởi tạo lại Amplify thành công!')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt AWS Amplify'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cấu hình Cognito',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Cognito URL',
                        border: OutlineInputBorder(),
                      ),
                      controller: TextEditingController(text: _cognitoUrl),
                      onChanged: (value) {
                        _cognitoUrl = value;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Client ID',
                        border: OutlineInputBorder(),
                      ),
                      controller: TextEditingController(text: _cognitoClientId),
                      onChanged: (value) {
                        _cognitoClientId = value;
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saveSettings,
                            child: const Text('Lưu cài đặt'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _reinitializeAmplify,
                            child: const Text('Khởi tạo lại Amplify'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Cấu hình Amplify hiện tại',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.copy),
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(text: _amplifyConfig),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Đã sao chép cấu hình vào clipboard'),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          Text(
                            _amplifyConfig,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
