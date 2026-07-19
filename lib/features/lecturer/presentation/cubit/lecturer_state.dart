import 'package:face_attendance_app/features/attendance/data/models/attendance_log_model.dart';

/// Base state untuk Lecturer.
abstract class LecturerState {
  const LecturerState();
}

/// State awal.
class LecturerInitial extends LecturerState {
  const LecturerInitial();
}

/// Sedang memuat data.
class LecturerLoading extends LecturerState {
  const LecturerLoading();
}

/// Data berhasil dimuat.
class LecturerLoaded extends LecturerState {
  final List<AttendanceLogModel> logs;
  final DateTime selectedDate;
  final int totalStudents;
  final int presentCount;

  const LecturerLoaded({
    required this.logs,
    required this.selectedDate,
    required this.totalStudents,
    required this.presentCount,
  });

  double get attendancePercentage =>
      totalStudents > 0 ? (presentCount / totalStudents) * 100 : 0;
}

/// Error.
class LecturerError extends LecturerState {
  final String message;

  const LecturerError({required this.message});
}
