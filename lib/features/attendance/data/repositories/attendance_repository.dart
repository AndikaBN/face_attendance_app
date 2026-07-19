import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:face_attendance_app/core/network/api_client.dart';
import 'package:face_attendance_app/core/services/firebase_service.dart';
import 'package:face_attendance_app/features/attendance/data/models/predict_response_model.dart';
import 'package:face_attendance_app/features/attendance/data/models/attendance_log_model.dart';

/// Repository untuk operasi absensi:
/// - Upload gambar wajah untuk prediksi (Flask API)
/// - Simpan log absensi ke Firestore
/// - Query riwayat absensi
class AttendanceRepository {
  final ApiClient _apiClient;

  AttendanceRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  CollectionReference get _logsCollection =>
      FirebaseService.firestore.collection('attendance_logs');

  /// Upload gambar wajah ke Flask API untuk recognition.
  Future<PredictResponseModel> uploadForPrediction(File imageFile) async {
    try {
      final responseData = await _apiClient.predictFace(imageFile);
      return PredictResponseModel.fromJson(responseData);
    } catch (e) {
      throw Exception('Gagal mengirim gambar ke server: $e');
    }
  }

  /// Simpan log absensi ke Firestore.
  Future<void> saveAttendanceLog({
    required String userUid,
    required PredictResponseModel result,
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
    });

    debugPrint('[AttendanceRepository] ✅ Log absensi disimpan ke Firestore');
  }

  /// Cek apakah mahasiswa sudah absen hari ini.
  Future<bool> hasAttendedToday(String userUid) async {
    final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final query = await _logsCollection
        .where('user_uid', isEqualTo: userUid)
        .where('date_key', isEqualTo: dateKey)
        .where('recognized', isEqualTo: true)
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }

  /// Ambil riwayat absensi mahasiswa sendiri (terbaru dulu).
  Future<List<AttendanceLogModel>> getMyAttendanceHistory(
    String userUid, {
    int limit = 30,
  }) async {
    final query = await _logsCollection
        .where('user_uid', isEqualTo: userUid)
        .where('recognized', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return query.docs.map((doc) => AttendanceLogModel.fromFirestore(doc)).toList();
  }

  /// Ambil semua absensi pada tanggal tertentu (untuk dosen).
  Future<List<AttendanceLogModel>> getAttendanceByDate(DateTime date) async {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);

    final query = await _logsCollection
        .where('date_key', isEqualTo: dateKey)
        .where('recognized', isEqualTo: true)
        .orderBy('timestamp', descending: false)
        .get();

    return query.docs.map((doc) => AttendanceLogModel.fromFirestore(doc)).toList();
  }
}
