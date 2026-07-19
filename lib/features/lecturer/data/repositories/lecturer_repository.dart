import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:face_attendance_app/core/services/firebase_service.dart';
import 'package:face_attendance_app/features/attendance/data/models/attendance_log_model.dart';

/// Repository untuk operasi dosen: query absensi mahasiswa.
class LecturerRepository {
  CollectionReference get _logsCollection =>
      FirebaseService.firestore.collection('attendance_logs');

  CollectionReference get _usersCollection =>
      FirebaseService.firestore.collection('users');

  /// Ambil semua absensi pada tanggal tertentu.
  Future<List<AttendanceLogModel>> getAttendanceByDate(DateTime date) async {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    debugPrint('[LecturerRepository] Query absensi untuk tanggal: $dateKey');

    final query = await _logsCollection
        .where('date_key', isEqualTo: dateKey)
        .where('recognized', isEqualTo: true)
        .orderBy('timestamp', descending: false)
        .get();

    return query.docs
        .map((doc) => AttendanceLogModel.fromFirestore(doc))
        .toList();
  }

  /// Hitung total mahasiswa terdaftar.
  Future<int> getTotalStudents() async {
    final query = await _usersCollection
        .where('role', isEqualTo: 'mahasiswa')
        .get();

    return query.docs.length;
  }
}
