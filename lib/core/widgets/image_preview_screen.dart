import 'dart:io';
import 'package:flutter/material.dart';

/// Màn hình xem ảnh toàn màn hình. Chạm vào ảnh hoặc nút đóng để thoát.
class ImagePreviewScreen extends StatelessWidget {
  const ImagePreviewScreen({super.key, required this.file});

  final File file;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Center(
              child: file.existsSync()
                  ? InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4,
                      child: Image.file(file, fit: BoxFit.contain),
                    )
                  : const Center(
                      child: Icon(Icons.image_not_supported, size: 64, color: Colors.white54),
                    ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
