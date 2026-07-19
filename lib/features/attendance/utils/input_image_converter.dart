import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Utility untuk mengkonversi CameraImage ke InputImage (ML Kit).
///
/// Menangani:
/// - Format NV21 (Android)
/// - Format BGRA8888 (iOS)
/// - Rotasi berdasarkan sensor orientation
class InputImageConverter {
  InputImageConverter._();

  /// Konversi [CameraImage] dari camera stream ke [InputImage] untuk ML Kit.
  ///
  /// Returns null jika konversi gagal.
  static InputImage? fromCameraImage(
    CameraImage cameraImage,
    CameraDescription cameraDescription,
  ) {
    // Tentukan rotasi berdasarkan sensor orientation
    final rotation = _getInputImageRotation(cameraDescription);
    if (rotation == null) return null;

    // Tentukan format gambar
    final format = _getInputImageFormat(cameraImage);
    if (format == null) return null;

    // Gabungkan semua planes menjadi satu buffer bytes
    final bytes = _concatenatePlanes(cameraImage.planes);

    final inputImageMetadata = InputImageMetadata(
      size: Size(
        cameraImage.width.toDouble(),
        cameraImage.height.toDouble(),
      ),
      rotation: rotation,
      format: format,
      bytesPerRow: cameraImage.planes.first.bytesPerRow,
    );

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: inputImageMetadata,
    );
  }

  /// Gabungkan bytes dari semua planes menjadi satu Uint8List.
  static Uint8List _concatenatePlanes(List<Plane> planes) {
    final allBytes = WriteBuffer();
    for (final plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  /// Map sensor orientation ke InputImageRotation.
  static InputImageRotation? _getInputImageRotation(
    CameraDescription camera,
  ) {
    final sensorOrientation = camera.sensorOrientation;

    switch (sensorOrientation) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        debugPrint(
          '[InputImageConverter] Unknown sensor orientation: $sensorOrientation',
        );
        return null;
    }
  }

  /// Map platform image format ke InputImageFormat.
  static InputImageFormat? _getInputImageFormat(CameraImage image) {
    switch (image.format.group) {
      case ImageFormatGroup.nv21:
        return InputImageFormat.nv21;
      case ImageFormatGroup.bgra8888:
        return InputImageFormat.bgra8888;
      default:
        debugPrint(
          '[InputImageConverter] Unsupported image format: ${image.format.group}',
        );
        return null;
    }
  }
}
