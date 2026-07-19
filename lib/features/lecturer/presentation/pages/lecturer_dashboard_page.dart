import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:face_attendance_app/core/constants/app_colors.dart';
import 'package:face_attendance_app/features/auth/data/models/user_model.dart';
import 'package:face_attendance_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:face_attendance_app/features/attendance/data/models/attendance_log_model.dart';
import 'package:face_attendance_app/features/lecturer/presentation/cubit/lecturer_cubit.dart';
import 'package:face_attendance_app/features/lecturer/presentation/cubit/lecturer_state.dart';

/// Dashboard utama untuk dosen.
/// Menampilkan daftar absensi mahasiswa dengan filter tanggal.
class LecturerDashboardPage extends StatelessWidget {
  final UserModel user;

  const LecturerDashboardPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LecturerCubit()..loadTodayAttendance(),
      child: _LecturerDashboardView(user: user),
    );
  }
}

class _LecturerDashboardView extends StatelessWidget {
  final UserModel user;

  const _LecturerDashboardView({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(context),

            // Date selector
            _buildDateSelector(context),

            // Stats card
            _buildStatsCard(),

            // Divider
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Divider(color: AppColors.border, height: 1),
            ),

            // Attendance list
            Expanded(child: _buildAttendanceList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0x20BB86FC),
              border: Border.all(color: const Color(0x40BB86FC), width: 2),
            ),
            child: Center(
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'D',
                style: const TextStyle(
                  color: Color(0xFFBB86FC),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, ${user.name}!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                const Text(
                  'Panel Dosen',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.error, size: 22),
            onPressed: () => context.read<AuthCubit>().logout(),
            tooltip: 'Logout',
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    return BlocBuilder<LecturerCubit, LecturerState>(
      builder: (context, state) {
        final selectedDate =
            state is LecturerLoaded ? state.selectedDate : DateTime.now();
        final dateFormatted = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(selectedDate);
        final isToday = DateFormat('yyyy-MM-dd').format(selectedDate) ==
            DateFormat('yyyy-MM-dd').format(DateTime.now());

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
          child: Row(
            children: [
              // Prev day
              _buildDateNavButton(
                icon: Icons.chevron_left,
                onTap: () {
                  final prev = selectedDate.subtract(const Duration(days: 1));
                  context.read<LecturerCubit>().loadAttendanceByDate(prev);
                },
              ),

              // Date display
              Expanded(
                child: GestureDetector(
                  onTap: () => _showDatePicker(context, selectedDate),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_today,
                            color: AppColors.primary, size: 18),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            isToday ? 'Hari Ini' : dateFormatted,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Next day
              _buildDateNavButton(
                icon: Icons.chevron_right,
                onTap: () {
                  final next = selectedDate.add(const Duration(days: 1));
                  if (next.isBefore(
                      DateTime.now().add(const Duration(days: 1)))) {
                    context.read<LecturerCubit>().loadAttendanceByDate(next);
                  }
                },
              ),

              const SizedBox(width: 8),

              // Today button
              if (!isToday)
                GestureDetector(
                  onTap: () {
                    context.read<LecturerCubit>().loadTodayAttendance();
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryFaded,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primaryBorder),
                    ),
                    child: const Text(
                      'Hari Ini',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateNavButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 22),
      ),
    );
  }

  Future<void> _showDatePicker(
      BuildContext context, DateTime currentDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: AppColors.background,
              surface: AppColors.surface,
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppColors.background,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && context.mounted) {
      context.read<LecturerCubit>().loadAttendanceByDate(picked);
    }
  }

  Widget _buildStatsCard() {
    return BlocBuilder<LecturerCubit, LecturerState>(
      builder: (context, state) {
        if (state is! LecturerLoaded) return const SizedBox();

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Row(
            children: [
              _buildStatItem(
                label: 'Hadir',
                value: '${state.presentCount}',
                color: AppColors.success,
              ),
              const SizedBox(width: 12),
              _buildStatItem(
                label: 'Total Mahasiswa',
                value: '${state.totalStudents}',
                color: AppColors.primary,
              ),
              const SizedBox(width: 12),
              _buildStatItem(
                label: 'Persentase',
                value: '${state.attendancePercentage.toStringAsFixed(0)}%',
                color: state.attendancePercentage >= 75
                    ? AppColors.success
                    : AppColors.warning,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceList() {
    return BlocBuilder<LecturerCubit, LecturerState>(
      builder: (context, state) {
        if (state is LecturerLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (state is LecturerError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.error, size: 48),
                const SizedBox(height: 12),
                Text(
                  state.message,
                  style: const TextStyle(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () =>
                      context.read<LecturerCubit>().loadTodayAttendance(),
                  child: const Text('Coba Lagi',
                      style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
          );
        }

        if (state is LecturerLoaded && state.logs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline,
                    size: 56, color: AppColors.textMuted),
                SizedBox(height: 12),
                Text(
                  'Belum ada absensi\npada tanggal ini',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 15),
                ),
              ],
            ),
          );
        }

        if (state is LecturerLoaded) {
          return RefreshIndicator(
            onRefresh: () => context
                .read<LecturerCubit>()
                .loadAttendanceByDate(state.selectedDate),
            color: AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              itemCount: state.logs.length,
              itemBuilder: (ctx, i) =>
                  _buildStudentLogCard(state.logs[i], i + 1),
            ),
          );
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildStudentLogCard(AttendanceLogModel log, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Nomor urut
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: AppColors.primaryFaded,
            ),
            child: Center(
              child: Text(
                '$index',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Nama & NIM
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.studentName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'NIM: ${log.nim}',
                  style:
                      const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),

          // Waktu
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                log.timeFormatted,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${log.similarityPercent} sim',
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
