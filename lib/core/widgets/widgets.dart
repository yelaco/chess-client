import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter/material.dart';

Widget BackgroundContainer(Widget child) {
  return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/bg_dark.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: child);
}

Widget LoadingIndicator() {
  return const Center(
    child: CircularProgressIndicator(color: Colors.white),
  );
}

// Widget Avatar(String userInfo) {
//   return CircleAvatar(
//     child: Image.network(
//       userInfo.isNotEmpty
//           ? '$userInfo/large'
//           : 'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png',
//       headers: const {'Accept': 'image/*'},
//       errorBuilder: (context, error, stackTrace) {
//         return Image.network(
//             'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png');
//       },
//     ),
//   );
// }

Widget Avatar(String userInfo, {double size = 48}) {
  final String imageUrl = userInfo.isNotEmpty
      ? '$userInfo/large'
      : 'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png';

  return ClipOval(
    child: Image.network(
      imageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      headers: const {'Accept': 'image/*'},
      errorBuilder: (context, error, stackTrace) {
        return Image.network(
          'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
        );
      },
    ),
  );
}
