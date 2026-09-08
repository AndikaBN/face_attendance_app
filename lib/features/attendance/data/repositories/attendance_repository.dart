import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:face_attendance_app/core/network/api_client.dart';
import 'package:face_attendance_app/core/services/firebase_service.dart';
import 'package:face_attendance_app/features/attendance/data/models/predict_response_model.dart';
import 'package:face_attendance_app/features/attendance/data/models/attendance_log_model.dart';

class AttendanceException implements Exception {
  final String message;

  const AttendanceException(this.message);
}

/// Repository untuk operasi absensi:
/// - Upload gambar wajah untuk prediksi (Flask API)
/// - Simpan log absensi (Masuk / Izin) ke Firestore
/// - Query riwayat absensi & status hari ini
class AttendanceRepository {
  final ApiClient _apiClient;

  AttendanceRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  CollectionReference get _logsCollection =>
      FirebaseService.firestore.collection('attendance_logs');

  /// Upload gambar wajah ke Flask API untuk recognition.
  Future<PredictResponseModel> uploadForPrediction(
    File imageFile, {
    required double latitude,
    required double longitude,
    required double accuracyMeters,
  }) async {
    try {
      final responseData = await _apiClient.predictFace(
        imageFile,
        latitude: latitude,
        longitude: longitude,
        accuracyMeters: accuracyMeters,
      );
      return PredictResponseModel.fromJson(responseData);
    } on DioException catch (e) {
      final responseMessage = e.response?.data is Map
          ? (e.response?.data['message']?.toString() ?? '')
          : '';

      if (responseMessage.toLowerCase().contains('luar area kampus') ||
          responseMessage.toLowerCase().contains('luar jangkauan')) {
        throw const AttendanceException(
          'Absensi gagal diproses: Anda di luar jangkauan kampus.',
        );
      }

      throw const AttendanceException(
        'Absensi gagal diproses. Silakan coba lagi.',
      );
    } catch (_) {
      throw const AttendanceException(
        'Absensi gagal diproses. Silakan coba lagi.',
      );
    }
  }

  /// Simpan log absensi MASUK ke Firestore.
  Future<void> saveAttendanceLog({
    required String userUid,
    required PredictResponseModel result,
    required double latitude,
    required double longitude,
    required double accuracyMeters,
    required double distanceMeters,
  }) async {
    final now = DateTime.now();
    final dateKey = DateFormat('yyyy-MM-dd').format(now);

    await _logsCollection.add({
      'user_uid': userUid,
      'student_name': result.studentName ?? '',
      'nim': result.nim ?? '',
      'confidence': result.confidence ?? 0.0,
      'similarity': result.similarity ?? 0.0,
      'recognized': result.recognized,
      'message': result.message,
      'timestamp': Timestamp.fromDate(now),
      'date_key': dateKey,
      'image_url': null,
      'status': 'masuk',
      'alasan_izin': null,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy_meters': accuracyMeters,
      'distance_from_campus_meters': distanceMeters,
      'location_verified': true,
    });

    debugPrint('[AttendanceRepository] ✅ Log absensi masuk disimpan ke Firestore');
  }

  /// Simpan log IZIN ke Firestore.
  Future<void> saveIzinLog({
    required String userUid,
    required String studentName,
    required String nim,
    required String alasanIzin,
  }) async {
    final now = DateTime.now();
    final dateKey = DateFormat('yyyy-MM-dd').format(now);

    await _logsCollection.add({
      'user_uid': userUid,
      'student_name': studentName,
      'nim': nim,
      'confidence': 1.0,
      'similarity': 1.0,
      'recognized': true,
      'message': 'Izin diajukan',
      'timestamp': Timestamp.fromDate(now),
      'date_key': dateKey,
      'image_url': null,
      'status': 'izin',
      'alasan_izin': alasanIzin,
    });

    debugPrint('[AttendanceRepository] ✅ Log izin disimpan ke Firestore');
  }

  /// Cek log absensi hari ini untuk mahasiswa.
  Future<AttendanceLogModel?> getTodayStatus(String userUid) async {
    final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final query = await _logsCollection
        .where('user_uid', isEqualTo: userUid)
        .where('date_key', isEqualTo: dateKey)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return AttendanceLogModel.fromFirestore(query.docs.first);
  }

  /// Cek apakah mahasiswa sudah absen hari ini (Masuk / Izin).
  Future<bool> hasAttendedToday(String userUid) async {
    final status = await getTodayStatus(userUid);
    return status != null;
  }

  /// Ambil riwayat absensi mahasiswa sendiri (terbaru dulu).
  /// Menggunakan sorting memori (Dart) untuk menghindari syarat Composite Index Firestore.
  Future<List<AttendanceLogModel>> getMyAttendanceHistory(
    String userUid, {
    int limit = 30,
  }) async {
    final query = await _logsCollection
        .where('user_uid', isEqualTo: userUid)
        .get();

    final logs = query.docs
        .map((doc) => AttendanceLogModel.fromFirestore(doc))
        .toList();

    // Urutkan terbaru dulu di memori Dart
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return logs.take(limit).toList();
  }

  /// Ambil semua absensi pada tanggal tertentu (untuk dosen).
  Future<List<AttendanceLogModel>> getAttendanceByDate(DateTime date) async {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);

    final query = await _logsCollection
        .where('date_key', isEqualTo: dateKey)
        .get();

    final logs = query.docs
        .map((doc) => AttendanceLogModel.fromFirestore(doc))
        .toList();

    // Urutkan terlama dulu di memori Dart
    logs.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return logs;
  }
}
