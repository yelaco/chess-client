import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_slchess/core/services/amplify_auth_service.dart';
import 'package:flutter_slchess/core/services/user_service.dart';
import 'package:flutter_slchess/core/services/image_service.dart';

class UploadImageScreen extends StatefulWidget {
  const UploadImageScreen({super.key});

  @override
  _UploadImageScreenState createState() => _UploadImageScreenState();
}

class _UploadImageScreenState extends State<UploadImageScreen> {
  File? _image;
  String? _uploadedImageUrl;
  final ImageService _imageService = ImageService();
  final AmplifyAuthService _authService = AmplifyAuthService();
  final UserService _userService = UserService();
  bool _isUploading = false;
  bool _isChangingPassword = false;

  // Controllers cho việc đổi mật khẩu
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Form keys
  final _passwordFormKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Chọn ảnh từ thư viện
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80, // Giảm chất lượng ảnh để giảm kích thước
    );

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  /// Upload ảnh lên server
  Future<void> _uploadImage() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ảnh trước')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Lấy idToken thay vì accessToken để xác thực với API
      final String? idToken = await _authService.getIdToken();
      if (idToken == null) {
        throw Exception('Vui lòng đăng nhập lại');
      }

      // Lấy presigned URL
      final String presignedUrl = await _imageService.getPresignedUrl(idToken);

      // Upload ảnh
      final bool success =
          await _imageService.uploadImage(_image!, presignedUrl);

      if (success) {
        // Lấy thông tin người dùng mới nhất từ server
        final String? accessToken = await _authService.getAccessToken();
        if (accessToken != null) {
          await _userService.saveSelfUserInfo(accessToken, idToken);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload và cập nhật avatar thành công')),
        );

        Navigator.of(context).pop();
      } else {
        throw Exception('Upload ảnh thất bại');
      }
    } catch (e) {
      String errorMessage = e.toString();
      print("Lỗi khi upload ảnh: $errorMessage");

      // Kiểm tra lỗi xác thực
      if (errorMessage.contains('token') &&
          (errorMessage.contains('invalid') ||
              errorMessage.contains('expired') ||
              errorMessage.contains('authentication challenge'))) {
        // Lỗi liên quan đến token
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Lỗi xác thực'),
            content: const Text(
              'Phiên làm việc của bạn đã hết hạn hoặc không hợp lệ. Vui lòng đăng nhập lại để tiếp tục.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Đóng'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _authService.signOut();
                  // Chuyển về màn hình đăng nhập
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                child: const Text('Đăng nhập lại'),
              ),
            ],
          ),
        );
      } else {
        // Lỗi khác
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $errorMessage')),
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  /// Cập nhật avatar trong thông tin người dùng
  Future<void> _updateUserAvatar(String avatarUrl) async {
    try {
      // Lấy thông tin người dùng hiện tại
      final currentUser = await _userService.getPlayer();
      if (currentUser == null) {
        throw Exception('Không tìm thấy thông tin người dùng');
      }

      // Cập nhật trường picture
      currentUser.picture = avatarUrl;

      // Lưu lại thông tin người dùng
      await _userService.savePlayer(currentUser);
    } catch (e) {
      throw Exception('Lỗi cập nhật thông tin người dùng: $e');
    }
  }

  /// Thay đổi mật khẩu
  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isChangingPassword = true;
    });

    try {
      final oldPassword = _oldPasswordController.text;
      final newPassword = _newPasswordController.text;

      final result =
          await _authService.changePassword(oldPassword, newPassword);

      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đổi mật khẩu thành công')),
        );

        // Xóa các trường nhập mật khẩu
        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }
    } catch (e) {
      String errorMessage = e.toString();

      // Kiểm tra xem có phải lỗi về quyền không
      if (errorMessage.contains('không có đủ quyền') ||
          errorMessage.contains('Access Token does not have required scopes')) {
        // Hiển thị thông báo
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cần quyền đổi mật khẩu'),
            content: const Text(
              'Phiên đăng nhập hiện tại không có đủ quyền để đổi mật khẩu. Bạn cần đăng nhập lại để tiếp tục.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  // Lưu thông tin mật khẩu tạm thời
                  final oldPwd = _oldPasswordController.text;
                  final newPwd = _newPasswordController.text;

                  // Gọi phương thức đổi mật khẩu với xác thực lại
                  await _authService.changePasswordWithReauthentication(
                      context, oldPwd, newPwd);
                },
                child: const Text('Đăng nhập lại'),
              ),
            ],
          ),
        );
      } else {
        // Lỗi khác
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $errorMessage')),
        );
      }
    } finally {
      setState(() {
        _isChangingPassword = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin tài khoản'),
        elevation: 0,
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Cập nhật Avatar'),
                Tab(text: 'Đổi mật khẩu'),
              ],
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorSize: TabBarIndicatorSize.label,
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildAvatarTab(),
                  _buildPasswordTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tab cập nhật avatar
  Widget _buildAvatarTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),

          // Hiển thị avatar
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 80,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _image != null ? FileImage(_image!) : null,
                  child: _image == null
                      ? const Icon(Icons.person, size: 80, color: Colors.grey)
                      : null,
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // Hướng dẫn
          const Text(
            'Nhấn vào avatar để chọn ảnh mới',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 40),

          // Nút upload ảnh
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isUploading ? null : _uploadImage,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isUploading
                  ? const CircularProgressIndicator()
                  : const Text(
                      'Cập nhật Avatar',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Tab đổi mật khẩu
  Widget _buildPasswordTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _passwordFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            const Text(
              'Thay đổi mật khẩu',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 25),

            // Mật khẩu hiện tại
            TextFormField(
              controller: _oldPasswordController,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu hiện tại',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập mật khẩu hiện tại';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // Mật khẩu mới
            TextFormField(
              controller: _newPasswordController,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu mới',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
                helperText:
                    'Mật khẩu phải có ít nhất 8 ký tự, bao gồm chữ hoa, chữ thường và số',
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập mật khẩu mới';
                }
                if (value.length < 8) {
                  return 'Mật khẩu phải có ít nhất 8 ký tự';
                }
                if (!RegExp(r'[A-Z]').hasMatch(value)) {
                  return 'Mật khẩu phải có ít nhất 1 chữ hoa';
                }
                if (!RegExp(r'[a-z]').hasMatch(value)) {
                  return 'Mật khẩu phải có ít nhất 1 chữ thường';
                }
                if (!RegExp(r'[0-9]').hasMatch(value)) {
                  return 'Mật khẩu phải có ít nhất 1 số';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // Xác nhận mật khẩu mới
            TextFormField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Xác nhận mật khẩu mới',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng xác nhận mật khẩu mới';
                }
                if (value != _newPasswordController.text) {
                  return 'Mật khẩu xác nhận không khớp';
                }
                return null;
              },
            ),

            const SizedBox(height: 40),

            // Nút đổi mật khẩu
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isChangingPassword ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isChangingPassword
                    ? const CircularProgressIndicator()
                    : const Text(
                        'Đổi mật khẩu',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
