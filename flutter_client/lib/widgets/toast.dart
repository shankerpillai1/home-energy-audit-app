import 'package:flutter/material.dart';

class Toast {
  static void show(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 10, 
        right: 20, 
        child: Material(
          color: const Color.fromARGB(0, 53, 53, 53),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
               color: Color.fromRGBO(18, 18, 18, 0.694),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }
}
