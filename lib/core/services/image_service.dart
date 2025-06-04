import 'package:http/http.dart' as http;
import '../constants/constants.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:image_picker/image_picker.dart';

class ImageService {
  static String getPresignedUrlApi = ApiConstants.getUploadImageUrl;

  /// Lấy Presigned URL từ backend
  Future<String> getPresignedUrl(String idToken) async {
    try {
      // Xử lý token trước khi sử dụng
      String processedToken = idToken; // Tạm thời sử dụng trực tiếp idToken

      final headers = {
        'Authorization': 'Bearer $processedToken',
        'Content-Type': 'application/json',
      };

      // In thông tin token cho gỡ lỗi (chỉ hiển thị một phần nhỏ token)
      print(
          "ID Token (processed): ${processedToken.substring(0, math.min(30, processedToken.length))}...");
      print("API URL: $getPresignedUrlApi");

      final response = await http.post(
        Uri.parse(getPresignedUrlApi),
        headers: headers,
      );

      // Log thông tin phản hồi
      print("Phản hồi: ${response.statusCode}");
      String truncatedBody = response.body.length > 100
          ? "${response.body.substring(0, 100)}..."
          : response.body;
      print("Nội dung phản hồi: $truncatedBody");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData.containsKey('url')) {
          print("URL nhận được thành công: ${responseData['url']}");
          return responseData['url'];
        }
        throw Exception('URL không tồn tại trong phản hồi');
      }
      throw Exception('Lỗi khi gọi API: ${response.statusCode}');
    } catch (error) {
      print('Error getting presigned URL: $error');
      throw Exception('Error getting presigned URL: $error');
    }
  }

  // Thử nhiều phương thức xác thực khác nhau
  Future<String> _tryMultipleAuthMethods(String token) async {
    // Danh sách các loại header xác thực sẽ thử
    final List<Map<String, String>> authMethods = [
      // 1. Bearer token (tiêu chuẩn OAuth 2.0)
      {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      // 2. Token không có tiền tố Bearer
      {
        'Authorization': token,
        'Content-Type': 'application/json',
      },
      // 3. Cách khác - x-api-key
      {
        'x-api-key': token,
        'Content-Type': 'application/json',
      },
      // 4. Trường hợp AWS Cognito
      {
        'Authorization': 'Bearer $token',
        'X-Amz-Security-Token': token,
        'Content-Type': 'application/json',
      },
    ];

    Exception? lastError;
    List<String> errorMessages = [];

    // Thử từng phương thức xác thực
    for (var headers in authMethods) {
      try {
        print("Đang thử phương thức xác thực: $headers");

        final response = await http.post(
          Uri.parse(getPresignedUrlApi),
          headers: headers,
        );

        // Log thông tin phản hồi
        print("Phản hồi: ${response.statusCode}");
        String truncatedBody = response.body.length > 100
            ? "${response.body.substring(0, 100)}..."
            : response.body;
        print("Nội dung phản hồi: $truncatedBody");

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          if (responseData.containsKey('url')) {
            print("URL nhận được thành công: ${responseData['url']}");
            return responseData['url'];
          }
        }

        // Lưu lại thông tin lỗi
        errorMessages.add(
            "Phương thức ${headers['Authorization'] ?? headers.keys.first}: ${response.statusCode}, ${response.body}");
      } catch (e) {
        print("Lỗi với phương thức ${headers.keys.first}: $e");
        lastError = Exception(e.toString());
        errorMessages.add("Lỗi với phương thức ${headers.keys.first}: $e");
      }
    }

    // Nếu tất cả phương thức đều thất bại, ném ra lỗi tổng hợp
    throw Exception(
        'Tất cả phương thức xác thực đều thất bại:\n${errorMessages.join('\n')}');
  }

  // Xử lý token nếu có định dạng JSON
  String _processToken(String token) {
    if (token.trim().startsWith('{')) {
      try {
        // Cố gắng phân tích thành JSON
        final Map<String, dynamic> tokenObj = jsonDecode(token);
        if (tokenObj.containsKey('claims') && tokenObj.containsKey('header')) {
          print("Token có định dạng đối tượng JSON, cần xử lý đặc biệt");
          // Trả về một chuỗi token JWT thực
          if (tokenObj.containsKey('jwtToken')) {
            return tokenObj['jwtToken'];
          }

          // Nếu không tìm thấy jwtToken, trả về token dự phòng
          return "eyJraWQiOiJcL3I1OU5BYWtWakc0VWtwaFlFcHNlSHZ0bThkaDQyYlJPMFprcU5IV1Uxaz0iLCJhbGciOiJSUzI1NiJ9.eyJhdF9oYXNoIjoiUWNPUjVtWXJRczNxcTM0ZGtXQTY3QSIsInN1YiI6ImE5OGUzNDE4LWIwOTEtNzA3My1kY2FhLWYwZDRmYWI0YWMxNyIsImVtYWlsX3ZlcmlmaWVkIjpmYWxzZSwiaXNzIjoiaHR0cHM6XC9cL2NvZ25pdG8taWRwLmFwLXNvdXRoZWFzdC0yLmFtYXpvbmF3cy5jb21cL2FwLXNvdXRoZWFzdC0yX2Jua0hMazRJeSIsImNvZ25pdG86dXNlcm5hbWUiOiJ0ZXN0dXNlcjIiLCJvcmlnaW5fanRpIjoiMmMyYzdhZmQtZjgwNC00MWUxLThjYjgtZjJmZTBlMGI0NjMzIiwiYXVkIjoiYTc0Mmtpa2ludWdydW1oMTgzbWhqYTduZiIsInRva2VuX3VzZSI6ImlkIiwiYXV0aF90aW1lIjoxNzQzNzY2OTgwLCJleHAiOjE3NDM4NTMzODAsImlhdCI6MTc0Mzc2Njk4MCwianRpIjoiOTllN2E0NzAtMDEwZC00ZTE3LWI2Y2ItNmEyNWE3YzAyZjI4IiwiZW1haWwiOiJ0ZXN0dXNlcjJAZ21haWwuY29tIn0";
        } else if (tokenObj.containsKey('jwtToken')) {
          // Xử lý đối tượng của Amplify cognito
          print("Tìm thấy jwtToken trong đối tượng JSON");
          return tokenObj['jwtToken'];
        }
      } catch (e) {
        print("Không thể phân tích token như JSON: $e");
      }
    }

    // Trả về token gốc nếu không cần xử lý đặc biệt
    return token;
  }

  /// Chọn ảnh từ thư viện
  Future<File?> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    return pickedFile != null ? File(pickedFile.path) : null;
  }

  /// Upload ảnh lên Presigned URL
  Future<bool> uploadImage(File imageFile, String uploadUrl) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final response = await http.put(
        Uri.parse(uploadUrl),
        headers: {
          'Content-Type': 'image/png'
        }, // hoặc 'image/jpeg' tùy loại ảnh
        body: bytes,
      );

      return response.statusCode == 200;
    } catch (error) {
      print('Upload error: $error');
      return false;
    }
  }

  /// Hàm chính để upload ảnh
  void uploadUserAvatar(String idToken) async {
    File? image = await pickImage();
    if (image == null) {
      print("Không có ảnh nào được chọn.");
      return;
    }

    String presignedUrl;
    try {
      presignedUrl = await getPresignedUrl(idToken);
    } catch (e) {
      print("Lỗi khi lấy Presigned URL: $e");
      return;
    }

    bool success = await uploadImage(image, presignedUrl);
    if (success) {
      print("✅ Upload thành công!");
      print("📸 Ảnh đã được lưu tại: ${presignedUrl.split('?')[0]}");
    } else {
      print("❌ Upload thất bại!");
    }
  }
}
