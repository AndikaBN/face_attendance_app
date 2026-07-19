import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

      final logs = results[0] as List;
      final totalStudents = results[1] as int;

      // Hitung unique students yang hadir (berdasarkan NIM)
      final uniqueNims = logs.map((log) => (log as dynamic).nim).toSet();

      emit(LecturerLoaded(
        logs: List.from(logs),
        selectedDate: date,
        totalStudents: totalStudents,
        presentCount: uniqueNims.length,
      ));
    } catch (e) {
      debugPrint('[LecturerCubit] Error: $e');
      emit(LecturerError(message: 'Gagal memuat data absensi: $e'));
    }
  }
}
