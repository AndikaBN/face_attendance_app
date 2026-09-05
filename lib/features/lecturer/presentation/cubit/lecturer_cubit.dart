import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:face_attendance_app/features/attendance/data/models/attendance_log_model.dart';
import 'package:face_attendance_app/features/lecturer/data/repositories/lecturer_repository.dart';
import 'package:face_attendance_app/features/lecturer/presentation/cubit/lecturer_state.dart';

/// Cubit untuk mengelola state dashboard dosen.
class LecturerCubit extends Cubit<LecturerState> {
  final LecturerRepository _repository;

  LecturerCubit({LecturerRepository? repository})
      : _repository = repository ?? LecturerRepository(),
        super(const LecturerInitial());

  /// Muat absensi hari ini.
  Future<void> loadTodayAttendance() async {
    await loadAttendanceByDate(DateTime.now());
  }

  /// Muat absensi berdasarkan tanggal tertentu.
  Future<void> loadAttendanceByDate(DateTime date) async {
    emit(const LecturerLoading());
    try {
      final results = await Future.wait([
        _repository.getAttendanceByDate(date),
        _repository.getTotalStudents(),
      ]);

      final logs = (results[0] as List).cast<AttendanceLogModel>();
      final totalStudents = results[1] as int;

      // Hitung per status berdasarkan NIM unik
      final masukNims = <String>{};
      final izinNims = <String>{};

      for (final log in logs) {
        if (log.isIzin) {
          izinNims.add(log.nim);
        } else {
          masukNims.add(log.nim);
        }
      }

      final presentCount = masukNims.length;
      final izinCount = izinNims.length;
      final alpaCount = (totalStudents - presentCount - izinCount).clamp(0, totalStudents);

      emit(LecturerLoaded(
        logs: logs,
        selectedDate: date,
        totalStudents: totalStudents,
        presentCount: presentCount,
        izinCount: izinCount,
        alpaCount: alpaCount,
      ));
    } catch (e) {
      debugPrint('[LecturerCubit] Error: $e');
      emit(LecturerError(message: 'Gagal memuat data absensi: $e'));
    }
  }
}
