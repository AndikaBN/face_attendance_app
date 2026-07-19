import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:face_attendance_app/core/constants/app_colors.dart';
import 'package:face_attendance_app/features/auth/data/models/user_model.dart';
import 'package:face_attendance_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:face_attendance_app/features/attendance/data/repositories/attendance_repository.dart';
import 'package:face_attendance_app/features/attendance/presentation/pages/attendance_scan_page.dart';
import 'package:face_attendance_app/features/attendance/presentation/pages/attendance_history_page.dart';

/// Dashboard utama untuk mahasiswa setelah login.
class StudentDashboardPage extends StatefulWidget {
  final UserModel user;

  const StudentDashboardPage({super.key, required this.user});

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  final AttendanceRepository _repo = AttendanceRepository();
  bool _hasAttendedToday = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkTodayAttendance();
  }

  Future<void> _checkTodayAttendance() async {
    setState(() => _isChecking = true);
    try {
      final attended = await _repo.hasAttendedToday(widget.user.uid);
      setState(() {
        _hasAttendedToday = attended;
        _isChecking = false;
      });
    } catch (e) {
      setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _checkTodayAttendance,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(),
                const SizedBox(height: 28),

                // Kartu status hari ini
                _buildTodayStatusCard(),
                const SizedBox(height: 20),

                // Tombol aksi
                _buildActionButton(
                  icon: Icons.face_retouching_natural,
                  label: 'Mulai Absensi',
                  subtitle: 'Scan wajah untuk absensi hari ini',
                  color: AppColors.primary,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AttendanceScanPage(
                          user: widget.user,
                        ),
                      ),
                    );
                    _checkTodayAttendance(); // Refresh status
                  },
                ),
                const SizedBox(height: 14),

                _buildActionButton(
                  icon: Icons.history,
                  label: 'Riwayat Absensi',
                  subtitle: 'Lihat riwayat kehadiran Anda',
                  color: AppColors.primaryDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AttendanceHistoryPage(
                          userUid: widget.user.uid,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),

                // Logout
                Center(
                  child: TextButton.icon(
                    onPressed: () => context.read<AuthCubit>().logout(),
                    icon: const Icon(Icons.logout, color: AppColors.error, size: 20),
                    label: const Text(
                      'Keluar',
                      style: TextStyle(color: AppColors.error, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryFaded,
            border: Border.all(color: AppColors.primaryBorder, width: 2),
          ),
          child: Center(
            child: Text(
              widget.user.name.isNotEmpty
                  ? widget.user.name[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 22,
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
                'Halo, ${widget.user.name}!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'NIM: ${widget.user.nim ?? "-"}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTodayStatusCard() {
    if (_isChecking) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _hasAttendedToday
            ? AppColors.successFaded
            : AppColors.warningFaded,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _hasAttendedToday
              ? const Color(0x4066BB6A)
              : const Color(0x40FFB74D),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _hasAttendedToday
                ? Icons.check_circle_rounded
                : Icons.schedule_rounded,
            color: _hasAttendedToday ? AppColors.success : AppColors.warning,
            size: 40,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _hasAttendedToday
                      ? 'Sudah Absen Hari Ini ✓'
                      : 'Belum Absen Hari Ini',
                  style: TextStyle(
                    color: _hasAttendedToday
                        ? AppColors.success
                        : AppColors.warning,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _hasAttendedToday
                      ? 'Kehadiran Anda sudah tercatat'
                      : 'Silakan lakukan absensi wajah',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: color.withValues(alpha: 0.15),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
