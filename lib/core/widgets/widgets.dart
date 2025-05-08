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
