import 'package:flutter/material.dart';

class ErrorDialog {
  void showPopupError(BuildContext context, String errorMessage) {
    late OverlayEntry overlayEntry;
    ValueNotifier<double> opacity = ValueNotifier(0.0);

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 50,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: ValueListenableBuilder<double>(
              valueListenable: opacity,
              builder: (context, value, child) {
                return AnimatedOpacity(
                  duration: const Duration(milliseconds: 300), // Fade-in nhanh
                  opacity: value,
                  child: child,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                    )
                  ],
                ),
                child: Text(
                  errorMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // Thêm vào overlay
    Overlay.of(context).insert(overlayEntry);

    // Hiệu ứng fade-in
    opacity.value = 1.0;

    // Giữ trong 1 giây, sau đó fade-out và remove
    Future.delayed(const Duration(milliseconds: 500), () async {
      opacity.value = 0.0;
      await Future.delayed(const Duration(milliseconds: 300)); // Đợi fade-out
      overlayEntry.remove();
    });
  }
}
