import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:face_attendance_app/core/constants/app_colors.dart';
import 'package:face_attendance_app/features/auth/data/models/user_model.dart';
import 'package:face_attendance_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:face_attendance_app/features/attendance/data/models/attendance_log_model.dart';
import 'package:face_attendance_app/features/attendance/data/repositories/attendance_repository.dart';
import 'package:face_attendance_app/features/attendance/presentation/pages/attendance_scan_page.dart';
import 'package:face_attendance_app/features/attendance/presentation/pages/attendance_history_page.dart';

/// Dashboard utama untuk mahasiswa setelah login (Light Theme + Fitur Masuk/Izin).
class StudentDashboardPage extends StatefulWidget {
  final UserModel user;

  const StudentDashboardPage({super.key, required this.user});

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  final AttendanceRepository _repo = AttendanceRepository();
  AttendanceLogModel? _todayStatus;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkTodayAttendance();
  }

  Future<void> _checkTodayAttendance() async {
    setState(() => _isChecking = true);
    try {
      final status = await _repo.getTodayStatus(widget.user.uid);
      setState(() {
        _todayStatus = status;
        _isChecking = false;
      });
    } catch (e) {
      setState(() => _isChecking = false);
    }
  }

  void _showIzinDialog() {
    final alasanController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.edit_document, color: AppColors.warning),
                  SizedBox(width: 10),
                  Text(
                    'Form Pengajuan Izin',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Silakan masukkan alasan izin Anda hari ini:',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: alasanController,
                      maxLines: 3,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Alasan izin wajib diisi';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'Contoh: Sakit demam / Urusan keluarga...',
                        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        filled: true,
                        fillColor: AppColors.surfaceLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.warning, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => isSubmitting = true);
                          try {
                            await _repo.saveIzinLog(
                              userUid: widget.user.uid,
                              studentName: widget.user.name,
                              nim: widget.user.nim ?? '-',
                              alasanIzin: alasanController.text.trim(),
                            );
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✅ Pengajuan izin berhasil dicatat'),
                                  backgroundColor: AppColors.warning,
                                ),
                              );
                              _checkTodayAttendance();
                            }
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Gagal mengajukan izin: $e'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: Colors.white,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Kirim Izin'),
                ),
              ],
            );
          },
        );
      },
    );
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
                const SizedBox(height: 24),

                // Kartu status hari ini
                _buildTodayStatusCard(),
                const SizedBox(height: 24),

                // Section Title
                const Text(
                  'Menu Absensi',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),

                // Tombol aksi - Masuk (Scan Wajah)
                _buildActionButton(
                  icon: Icons.face_retouching_natural,
                  label: 'Absensi Masuk',
                  subtitle: 'Scan wajah untuk absensi hadir hari ini',
                  color: AppColors.success,
                  bgColor: AppColors.successFaded,
                  borderColor: AppColors.successBorder,
                  enabled: _todayStatus == null, // Nonaktif jika sudah absen/izin
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AttendanceScanPage(
                          user: widget.user,
                        ),
                      ),
                    );
                    _checkTodayAttendance();
                  },
                ),
                const SizedBox(height: 12),

                // Tombol aksi - Ajukan Izin
                _buildActionButton(
                  icon: Icons.edit_note_rounded,
                  label: 'Ajukan Izin',
                  subtitle: 'Kirim surat/alasan tidak hadir hari ini',
                  color: AppColors.warning,
                  bgColor: AppColors.warningFaded,
                  borderColor: AppColors.warningBorder,
                  enabled: _todayStatus == null,
                  onTap: _showIzinDialog,
                ),
                const SizedBox(height: 12),

                // Tombol aksi - Riwayat
                _buildActionButton(
                  icon: Icons.history_rounded,
                  label: 'Riwayat Absensi',
                  subtitle: 'Lihat catatan kehadiran & izin Anda',
                  color: AppColors.primary,
                  bgColor: AppColors.primaryFaded,
                  borderColor: AppColors.primaryBorder,
                  enabled: true,
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
                const SizedBox(height: 36),

                // Logout
                Center(
                  child: TextButton.icon(
                    onPressed: () => context.read<AuthCubit>().logout(),
                    icon: const Icon(Icons.logout, color: AppColors.error, size: 20),
                    label: const Text(
                      'Keluar dari Akun',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
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
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, ${widget.user.name}!',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
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
      ),
    );
  }

  Widget _buildTodayStatusCard() {
    if (_isChecking) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
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

    final bool hasAttended = _todayStatus != null;
    final bool isMasuk = _todayStatus?.isMasuk ?? false;
    final bool isIzin = _todayStatus?.isIzin ?? false;

    Color cardBg = AppColors.errorFaded;
    Color borderColor = AppColors.errorBorder;
    Color iconColor = AppColors.error;
    IconData iconData = Icons.schedule_rounded;
    String statusTitle = 'Belum Absen Hari Ini';
    String statusSubtitle = 'Silakan pilih Absensi Masuk atau Ajukan Izin';

    if (hasAttended) {
      if (isMasuk) {
        cardBg = AppColors.successFaded;
        borderColor = AppColors.successBorder;
        iconColor = AppColors.success;
        iconData = Icons.check_circle_rounded;
        statusTitle = 'Sudah Absen Masuk ✓';
        statusSubtitle = 'Kehadiran tercatat pukul ${_todayStatus!.timeFormatted}';
      } else if (isIzin) {
        cardBg = AppColors.warningFaded;
        borderColor = AppColors.warningBorder;
        iconColor = AppColors.warning;
        iconData = Icons.edit_note_rounded;
        statusTitle = 'Izin Terdaftar 📋';
        statusSubtitle = 'Alasan: ${_todayStatus!.alasanIzin ?? "Izin"}';
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(color: AppColors.shadow, blurRadius: 6),
              ],
            ),
            child: Icon(iconData, color: iconColor, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusTitle,
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusSubtitle,
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
    required Color bgColor,
    required Color borderColor,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Opacity(
          opacity: enabled ? 1.0 : 0.5,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: enabled ? AppColors.border : AppColors.borderLight),
              boxShadow: enabled
                  ? const [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: bgColor,
                    border: Border.all(color: borderColor),
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
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: enabled ? AppColors.textSecondary : AppColors.textMuted,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
