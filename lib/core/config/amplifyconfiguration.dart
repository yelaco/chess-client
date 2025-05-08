import 'package:flutter_dotenv/flutter_dotenv.dart';

class AmplifyConfig {
  static String get amplifyConfig {
    final cognitoUrl = dotenv.env['COGNITO_URL'];
    final cognitoClientId = dotenv.env['COGNITO_CLIENT_ID'];
    final userPoolId = _extractUserPoolId(cognitoUrl);

    if (cognitoUrl == null || cognitoClientId == null || userPoolId == null) {
      throw Exception(
          'Thiếu thông tin cấu hình Cognito. Vui lòng kiểm tra file .env');
    }

    final region = _extractRegion(cognitoUrl);

    return '''
    {
      "UserAgent": "aws-amplify-cli/2.0",
      "Version": "1.0",
      "auth": {
        "plugins": {
          "awsCognitoAuthPlugin": {
            "UserAgent": "aws-amplify/cli",
            "Version": "0.1.0",
            "IdentityManager": {
              "Default": {}
            },
            "CognitoUserPool": {
              "Default": {
                "PoolId": "$userPoolId",
                "AppClientId": "$cognitoClientId",
                "Region": "$region"
              }
            },
            "Auth": {
              "Default": {
                "authenticationFlowType": "USER_SRP_AUTH",
                "OAuth": {
                  "WebDomain": "$cognitoUrl",
                  "AppClientId": "$cognitoClientId",
                  "SignInRedirectURI": "slchess://callback/",
                  "Scopes": ["email", "openid", "phone", "aws.cognito.signin.user.admin"]
                }
              }
            }
          }
        }
      }
    }
    ''';
  }

  // Lấy UserPoolId từ domain Cognito
  static String? _extractUserPoolId(String? cognitoUrl) {
    if (cognitoUrl == null) return null;

    // Phân tích URL để lấy phần đầu tiên (thường là tên user pool)
    final parts = cognitoUrl.split('.');
    if (parts.isEmpty) return null;

    final region = _extractRegion(cognitoUrl);
    if (region == null) return null;

    // Format: region_ID (ví dụ: ap-southeast-2_abcd1234)
    final userPoolName = parts[0];
    return "${region}_$userPoolName";
  }

  // Lấy region từ domain Cognito
  static String? _extractRegion(String? cognitoUrl) {
    if (cognitoUrl == null) return null;

    // Cố gắng trích xuất region từ URL
    // Ví dụ: slchess-dev.auth.ap-southeast-2.amazoncognito.com
    final regex = RegExp(r'auth\.([a-z0-9-]+)\.amazoncognito');
    final match = regex.firstMatch(cognitoUrl);

    return match?.group(1);
  }
}
