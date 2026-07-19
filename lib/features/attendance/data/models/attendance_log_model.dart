import 'package:cloud_firestore/cloud_firestore.dart';

/// Model log absensi yang disimpan di Firestore collection 'attendance_logs'.
class AttendanceLogModel {
  final String id;
  final String userUid;
  final String studentName;
  final String nim;
  final double confidence;
  final double similarity;
  final bool recognized;
  final String message;
  final DateTime timestamp;
  final String dateKey; // "2026-07-17" format untuk filter harian

  AttendanceLogModel({
    required this.id,
    required this.userUid,
    required this.studentName,
    required this.nim,
    required this.confidence,
    required this.similarity,
    required this.recognized,
    required this.message,
    required this.timestamp,
    required this.dateKey,
  });

  /// Parse dari Firestore document.
  factory AttendanceLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AttendanceLogModel(
      id: doc.id,
      userUid: data['user_uid']?.toString() ?? '',
      studentName: data['student_name']?.toString() ?? '',
      nim: data['nim']?.toString() ?? '',
      confidence: (data['confidence'] as num?)?.toDouble() ?? 0.0,
      similarity: (data['similarity'] as num?)?.toDouble() ?? 0.0,
      recognized: data['recognized'] as bool? ?? false,
      message: data['message']?.toString() ?? '',
      timestamp:
          (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dateKey: data['date_key']?.toString() ?? '',
    );
  }

  /// Confidence sebagai persentase.
  String get confidencePercent => '${(confidence * 100).toStringAsFixed(1)}%';

  /// Similarity sebagai persentase.
  String get similarityPercent => '${(similarity * 100).toStringAsFixed(1)}%';

  /// Waktu dalam format HH:mm.
  String get timeFormatted =>
      '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
}
