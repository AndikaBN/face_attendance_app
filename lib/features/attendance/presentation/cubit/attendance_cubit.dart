import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:face_attendance_app/features/attendance/data/repositories/attendance_repository.dart';
import 'package:face_attendance_app/features/attendance/presentation/cubit/attendance_state.dart';
import 'package:face_attendance_app/features/attendance/utils/input_image_converter.dart';
import 'package:face_attendance_app/core/services/geofence_service.dart';

import 'package:face_attendance_app/features/auth/data/models/user_model.dart';
import 'package:face_attendance_app/features/attendance/data/models/predict_response_model.dart';

/// Cubit yang mengelola state kamera, deteksi wajah, dan proses absensi.
class AttendanceCubit extends Cubit<AttendanceState> {
  final AttendanceRepository _repository;
  final UserModel user;
  final GeofenceService _geofenceService;

  CameraController? _cameraController;
  CameraController? get cameraController => _cameraController;

  late final FaceDetector _faceDetector;
  bool _isDetecting = false;
  bool _isCameraInitialized = false;
  bool _isStreaming = false;
  bool _hasReset = false; // Guard untuk mencegah double reset

  AttendanceCubit({
    required this.user,
    AttendanceRepository? repository,
    GeofenceService? geofenceService,
  })
      : _repository = repository ?? AttendanceRepository(),
        _geofenceService = geofenceService ?? GeofenceService(),
        super(const AttendanceInitial()) {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: false,
        enableLandmarks: false,
        enableClassification: false,
        enableTracking: true,
        performanceMode: FaceDetectorMode.fast,
        minFaceSize: 0.15,
      ),
    );
  }

  /// Inisialisasi kamera dan mulai image stream untuk deteksi wajah.
  Future<void> initCamera(List<CameraDescription> cameras) async {
    if (_isCameraInitialized) return;

    // Cari kamera depan
    final frontCamera = cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: defaultTargetPlatform == TargetPlatform.android
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    try {
      await _cameraController!.initialize();
      _isCameraInitialized = true;

      // Emit state awal dengan camera ready, tanpa wajah
      emit(const CameraReady(
        faceDetected: false,
        faces: [],
        imageWidth: 0,
        imageHeight: 0,
      ));

      // Mulai image stream untuk deteksi wajah lokal
      _startImageStream();
    } catch (e) {
      emit(AttendanceError(message: 'Gagal inisialisasi kamera: $e'));
    }
  }

  /// Start camera image stream dan jalankan face detection di setiap frame.
  void _startImageStream() {
    if (_isStreaming) {
      debugPrint('[AttendanceCubit] Stream sudah aktif, skip startImageStream');
      return;
    }

    try {
      _cameraController?.startImageStream((CameraImage cameraImage) {
        if (_isDetecting) return;
        _isDetecting = true;

        _processFrame(cameraImage).then((_) {
          _isDetecting = false;
        }).catchError((_) {
          _isDetecting = false;
        });
      });
      _isStreaming = true;
    } catch (e) {
      debugPrint('[AttendanceCubit] Error starting stream: $e');
    }
  }

  /// Stop image stream dengan safety guard.
  Future<void> _stopImageStream() async {
    if (!_isStreaming) return;

    try {
      await _cameraController?.stopImageStream();
    } catch (e) {
      debugPrint('[AttendanceCubit] Error stopping stream: $e');
    }
    _isStreaming = false;
  }

  /// Proses satu frame dari camera stream untuk deteksi wajah.
  Future<void> _processFrame(CameraImage cameraImage) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    final inputImage = InputImageConverter.fromCameraImage(
      cameraImage,
      _cameraController!.description,
    );

    if (inputImage == null) return;

    try {
      final faces = await _faceDetector.processImage(inputImage);

      // Hanya emit state jika cubit masih di CameraReady
      // (jangan overwrite saat sedang predicting atau menampilkan hasil)
      if (state is CameraReady) {
        emit(CameraReady(
          faceDetected: faces.isNotEmpty,
          faces: faces,
          imageWidth: cameraImage.width.toDouble(),
          imageHeight: cameraImage.height.toDouble(),
        ));
      }
    } catch (e) {
      debugPrint('[AttendanceCubit] Face detection error: $e');
    }
  }

  /// Capture foto dari kamera dan kirim ke Flask API untuk prediksi.
  ///
  /// Flow:
  /// 1. Stop image stream
  /// 2. Capture gambar
  /// 3. Upload ke API
  /// 4. Emit hasil
  /// 5. JANGAN restart stream otomatis — biarkan UI menampilkan hasil
  Future<void> captureAndPredict() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      emit(const AttendanceError(message: 'Kamera belum siap'));
      return;
    }

    // Setiap percobaan baru harus dapat kembali ke kamera jika proses gagal.
    _hasReset = false;

    try {
      emit(const AttendancePredicting());

      // Verifikasi lokasi sebelum mengambil atau mengunggah foto.
      final location = await _geofenceService.getVerifiedPosition();

      // Stop stream supaya bisa capture
      await _stopImageStream();

      // Capture gambar
      final XFile photo = await _cameraController!.takePicture();
      final File imageFile = File(photo.path);

      // Upload ke Flask API
      var result = await _repository.uploadForPrediction(
        imageFile,
        latitude: location.position.latitude,
        longitude: location.position.longitude,
        accuracyMeters: location.position.accuracy,
      );

      // Verifikasi identitas: NIM dari hasil deteksi wajah harus sama dengan NIM user yang login
      if (result.recognized) {
        final expectedNim = user.nim?.trim().toLowerCase();
        final detectedNim = result.nim?.trim().toLowerCase();
        
        if (expectedNim != null && detectedNim != null && expectedNim != detectedNim) {
          result = PredictResponseModel(
            success: true,
            recognized: false,
            studentName: result.studentName,
            nim: result.nim,
            similarity: result.similarity,
            confidence: result.confidence,
            message: 'Absensi gagal! Wajah yang terdeteksi bukan milik Anda (NIM tidak cocok).',
          );
        }
      }

      // Simpan log absensi ke Firestore jika benar-benar dikenali dan terverifikasi
      if (result.recognized) {
        await _repository.saveAttendanceLog(
          userUid: user.uid,
          result: result,
          latitude: location.position.latitude,
          longitude: location.position.longitude,
          accuracyMeters: location.position.accuracy,
          distanceMeters: location.distanceMeters,
        );
      }

      emit(AttendanceSuccess(result: result));

      // Hapus file temporary
      try {
        await imageFile.delete();
      } catch (_) {}
    } catch (e) {
      if (e is GeofenceException) {
        emit(AttendanceError(message: e.message));
      } else if (e is AttendanceException) {
        emit(AttendanceError(message: e.message));
      } else {
        emit(const AttendanceError(
          message: 'Absensi gagal diproses. Silakan coba lagi.',
        ));
      }
    }
  }

  /// Reset ke mode kamera setelah melihat hasil prediksi.
  /// Dilindungi oleh _hasReset agar tidak dipanggil ganda.
  Future<void> resetToCamera() async {
    // Guard: cegah double reset (dari onDismiss + .then())
    if (_hasReset) {
      debugPrint('[AttendanceCubit] resetToCamera sudah dipanggil, skip');
      return;
    }
    _hasReset = true;

    emit(const CameraReady(
      faceDetected: false,
      faces: [],
      imageWidth: 0,
      imageHeight: 0,
    ));

    // Restart image stream
    _startImageStream();
  }

  /// Public: stop stream saat app masuk background/inactive.
  /// JANGAN dispose controller — hanya stop stream.
  Future<void> stopStream() async {
    await _stopImageStream();
  }

  /// Public: resume stream saat app kembali aktif.
  Future<void> resumeStream() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    _startImageStream();

    // Pastikan state kembali ke CameraReady
    if (state is! CameraReady) {
      emit(const CameraReady(
        faceDetected: false,
        faces: [],
        imageWidth: 0,
        imageHeight: 0,
      ));
    }
  }

  @override
  Future<void> close() async {
    await _stopImageStream();
    await _cameraController?.dispose();
    _faceDetector.close();
    return super.close();
  }
}
