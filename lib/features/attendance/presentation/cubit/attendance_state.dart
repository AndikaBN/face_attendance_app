import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:face_attendance_app/features/attendance/data/models/predict_response_model.dart';

/// Base state untuk Attendance feature.
abstract class AttendanceState {
  const AttendanceState();
}

/// State awal — kamera belum diinisialisasi.
class AttendanceInitial extends AttendanceState {
  const AttendanceInitial();
}

/// State saat kamera sudah siap dan streaming.
class CameraReady extends AttendanceState {
  /// Apakah ada wajah terdeteksi di frame saat ini.
  final bool faceDetected;

  /// Daftar wajah yang terdeteksi oleh ML Kit.
  final List<Face> faces;

  /// Dimensi gambar dari camera stream (untuk koordinat mapping).
  final double imageWidth;
  final double imageHeight;

  const CameraReady({
    required this.faceDetected,
    required this.faces,
    required this.imageWidth,
    required this.imageHeight,
  });

  CameraReady copyWith({
    bool? faceDetected,
    List<Face>? faces,
    double? imageWidth,
    double? imageHeight,
  }) {
    return CameraReady(
      faceDetected: faceDetected ?? this.faceDetected,
      faces: faces ?? this.faces,
      imageWidth: imageWidth ?? this.imageWidth,
      imageHeight: imageHeight ?? this.imageHeight,
    );
  }
}

/// State saat sedang mengirim foto ke API (loading).
class AttendancePredicting extends AttendanceState {
  const AttendancePredicting();
}

/// State saat hasil prediksi berhasil diterima.
class AttendanceSuccess extends AttendanceState {
  final PredictResponseModel result;

  const AttendanceSuccess({required this.result});
}

/// State error.
class AttendanceError extends AttendanceState {
  final String message;

  const AttendanceError({required this.message});
}
