import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:face_attendance_app/core/constants/app_colors.dart';
import 'package:face_attendance_app/features/auth/data/models/user_model.dart';
import 'package:face_attendance_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:face_attendance_app/features/attendance/data/models/attendance_log_model.dart';
import 'package:face_attendance_app/features/lecturer/presentation/cubit/lecturer_cubit.dart';
import 'package:face_attendance_app/features/lecturer/presentation/cubit/lecturer_state.dart';
import 'package:face_attendance_app/features/lecturer/utils/pdf_report_generator.dart';

/// Dashboard utama untuk dosen (Light Theme + Fitur Status Masuk/Izin/Alpa + Export PDF).
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

  void _exportPdf(BuildContext context) {
    final state = context.read<LecturerCubit>().state;
    if (state is LecturerLoaded) {
      PdfReportGenerator.printOrSavePdf(
        lecturer: user,
        date: state.selectedDate,
        logs: state.logs,
        totalStudents: state.totalStudents,
        presentCount: state.presentCount,
        izinCount: state.izinCount,
        alpaCount: state.alpaCount,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tunggu hingga data absensi selesai dimuat')),
      );
    }
  }

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

            // Stats cards (Hadir, Izin, Alpa, Persentase)
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
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 20, 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryFaded,
              border: Border.all(color: AppColors.primaryBorder, width: 2),
            ),
            child: Center(
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'D',
                style: const TextStyle(
                  color: AppColors.primary,
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
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                const Text(
                  'Panel Monitoring Dosen',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),

          // Export PDF button
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary, size: 24),
            onPressed: () => _exportPdf(context),
            tooltip: 'Cetak Laporan PDF',
          ),

          // Logout button
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 22),
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
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 10),
          child: Row(
            children: [
              // Prev day
              _buildDateNavButton(
                icon: Icons.chevron_left_rounded,
                onTap: () {
                  final prev = selectedDate.subtract(const Duration(days: 1));
                  context.read<LecturerCubit>().loadAttendanceByDate(prev);
                },
              ),
              const SizedBox(width: 8),

              // Date display
              Expanded(
                child: GestureDetector(
                  onTap: () => _showDatePicker(context, selectedDate),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                      boxShadow: const [
                        BoxShadow(color: AppColors.shadow, blurRadius: 6),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            color: AppColors.primary, size: 18),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            isToday ? 'Hari Ini' : dateFormatted,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Next day
              _buildDateNavButton(
                icon: Icons.chevron_right_rounded,
                onTap: () {
                  final next = selectedDate.add(const Duration(days: 1));
                  if (next.isBefore(
                      DateTime.now().add(const Duration(days: 1)))) {
                    context.read<LecturerCubit>().loadAttendanceByDate(next);
                  }
                },
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
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(color: AppColors.shadow, blurRadius: 4),
          ],
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 24),
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
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
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
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 14),
          child: Column(
            children: [
              Row(
                children: [
                  _buildStatItem(
                    label: 'Hadir (Masuk)',
                    value: '${state.presentCount}',
                    color: AppColors.success,
                    bgColor: AppColors.successFaded,
                    borderColor: AppColors.successBorder,
                  ),
                  const SizedBox(width: 8),
                  _buildStatItem(
                    label: 'Izin',
                    value: '${state.izinCount}',
                    color: AppColors.warning,
                    bgColor: AppColors.warningFaded,
                    borderColor: AppColors.warningBorder,
                  ),
                  const SizedBox(width: 8),
                  _buildStatItem(
                    label: 'Alpa',
                    value: '${state.alpaCount}',
                    color: AppColors.error,
                    bgColor: AppColors.errorFaded,
                    borderColor: AppColors.errorBorder,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Mahasiswa: ${state.totalStudents}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Kehadiran: ${state.attendancePercentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: state.attendancePercentage >= 75
                            ? AppColors.success
                            : AppColors.warning,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
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
    required Color bgColor,
    required Color borderColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
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
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
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
                const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                const SizedBox(height: 12),
                Text(
                  state.message,
                  style: const TextStyle(color: AppColors.textSecondary),
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
                Icon(Icons.people_outline_rounded,
                    size: 56, color: AppColors.textMuted),
                SizedBox(height: 12),
                Text(
                  'Belum ada absensi atau izin\npada tanggal ini',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
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
    Color badgeColor = AppColors.success;
    Color badgeBg = AppColors.successFaded;
    IconData badgeIcon = Icons.check_circle_rounded;

    if (log.isIzin) {
      badgeColor = AppColors.warning;
      badgeBg = AppColors.warningFaded;
      badgeIcon = Icons.edit_note_rounded;
    } else if (log.isAlpa) {
      badgeColor = AppColors.error;
      badgeBg = AppColors.errorFaded;
      badgeIcon = Icons.cancel_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Status Badge / Icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: badgeBg,
            ),
            child: Icon(badgeIcon, color: badgeColor, size: 22),
          ),
          const SizedBox(width: 14),

          // Nama & NIM
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.studentName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'NIM: ${log.nim}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                if (log.isIzin && log.alasanIzin != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Alasan: ${log.alasanIzin}',
                    style: const TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Waktu & Status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  log.statusLabel,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                log.timeFormatted,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
