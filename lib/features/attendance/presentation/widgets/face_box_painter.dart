import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// CustomPainter untuk menggambar bounding box di sekitar wajah yang terdeteksi.
///
/// Menangani:
/// - Scaling dari koordinat ML Kit ke ukuran preview widget
/// - Mirror horizontal untuk kamera depan
/// - Rotasi gambar (portrait mode)
class FaceBoxPainter extends CustomPainter {
  final List<Face> faces;
  final Size imageSize;
  final CameraLensDirection lensDirection;
  final InputImageRotation rotation;

  FaceBoxPainter({
    required this.faces,
    required this.imageSize,
    required this.lensDirection,
    required this.rotation,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    if (faces.isEmpty || imageSize.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = const Color(0xAA64FFDA); // Teal semi-transparan

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0x1A64FFDA); // Teal sangat transparan (fill)

    // Tentukan ukuran "gambar asli" yang ML Kit lihat.
    // Pada portrait mode, lebar dan tinggi gambar dari sensor bisa terbalik.
    final bool isRotated = rotation == InputImageRotation.rotation90deg ||
        rotation == InputImageRotation.rotation270deg;

    final double imgWidth = isRotated ? imageSize.height : imageSize.width;
    final double imgHeight = isRotated ? imageSize.width : imageSize.height;

    // Hitung scale factor berdasarkan mode fill (camera preview biasanya fill)
    final double scaleX = canvasSize.width / imgWidth;
    final double scaleY = canvasSize.height / imgHeight;

    for (final face in faces) {
      final rect = face.boundingBox;

      double left = rect.left * scaleX;
      double top = rect.top * scaleY;
      double right = rect.right * scaleX;
      double bottom = rect.bottom * scaleY;

      // Mirror horizontal untuk kamera depan
      if (lensDirection == CameraLensDirection.front) {
        final double tempLeft = left;
        left = canvasSize.width - right;
        right = canvasSize.width - tempLeft;
      }

      // Buat rect dan pastikan ukurannya wajar
      final scaledRect = Rect.fromLTRB(left, top, right, bottom);

      // Skip jika rect terlalu kecil atau di luar layar
      if (scaledRect.width < 20 || scaledRect.height < 20) continue;
      if (scaledRect.right < 0 || scaledRect.left > canvasSize.width) continue;
      if (scaledRect.bottom < 0 || scaledRect.top > canvasSize.height) continue;

      // Gambar rounded rectangle
      final rrect = RRect.fromRectAndRadius(scaledRect, const Radius.circular(12));
      canvas.drawRRect(rrect, fillPaint);
      canvas.drawRRect(rrect, paint);

      // Gambar corner accents (4 sudut)
      _drawCornerAccents(canvas, scaledRect, paint);
    }
  }

  /// Gambar garis aksen di 4 sudut bounding box untuk look yang premium.
  void _drawCornerAccents(Canvas canvas, Rect rect, Paint basePaint) {
    final accentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..color = const Color(0xFF64FFDA) // Teal solid
      ..strokeCap = StrokeCap.round;

    const cornerLength = 20.0;

    // Top-left
    canvas.drawLine(
      Offset(rect.left, rect.top + cornerLength),
      Offset(rect.left, rect.top),
      accentPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.top),
      Offset(rect.left + cornerLength, rect.top),
      accentPaint,
    );

    // Top-right
    canvas.drawLine(
      Offset(rect.right - cornerLength, rect.top),
      Offset(rect.right, rect.top),
      accentPaint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.top),
      Offset(rect.right, rect.top + cornerLength),
      accentPaint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(rect.left, rect.bottom - cornerLength),
      Offset(rect.left, rect.bottom),
      accentPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.bottom),
      Offset(rect.left + cornerLength, rect.bottom),
      accentPaint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(rect.right - cornerLength, rect.bottom),
      Offset(rect.right, rect.bottom),
      accentPaint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.bottom),
      Offset(rect.right, rect.bottom - cornerLength),
      accentPaint,
    );
  }

  @override
  bool shouldRepaint(FaceBoxPainter oldDelegate) {
    return oldDelegate.faces != faces ||
        oldDelegate.imageSize != imageSize;
  }
}
