import 'dart:io';
import 'package:dio/dio.dart';
import 'package:face_attendance_app/core/constants/api_config.dart';

/// HTTP client berbasis Dio untuk komunikasi dengan Flask ML API.
class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: ApiConfig.connectTimeout),
        receiveTimeout: const Duration(seconds: ApiConfig.receiveTimeout),
        headers: {
          // Header untuk melewati halaman warning ngrok
          'ngrok-skip-browser-warning': '1',
        },
      ),
    );
  }

  /// Kirim gambar wajah ke endpoint /predict untuk recognition.
  ///
  /// [imageFile] — file gambar yang akan dikirim (JPG/PNG).
  /// Returns response Map dari Flask API.
  Future<Map<String, dynamic>> predictFace(
    File imageFile, {
    required double latitude,
    required double longitude,
    required double accuracyMeters,
  }) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(
        imageFile.path,
        filename: 'capture_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ),
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'accuracy_meters': accuracyMeters.toString(),
    });

    final response = await _dio.post(
      ApiConfig.predictEndpoint,
      data: formData,
    );

    return response.data as Map<String, dynamic>;
  }

  /// Health check ke Flask API.
  Future<Map<String, dynamic>> healthCheck() async {
    final response = await _dio.get(ApiConfig.healthEndpoint);
    return response.data as Map<String, dynamic>;
  }

  /// Ambil daftar mahasiswa terdaftar.
  Future<Map<String, dynamic>> getStudents() async {
    final response = await _dio.get(ApiConfig.studentsEndpoint);
    return response.data as Map<String, dynamic>;
  }
}
