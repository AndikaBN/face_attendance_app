import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:face_attendance_app/core/constants/app_colors.dart';
import 'package:face_attendance_app/features/attendance/presentation/cubit/attendance_cubit.dart';
import 'package:face_attendance_app/features/attendance/presentation/cubit/attendance_state.dart';
import 'package:face_attendance_app/features/attendance/presentation/widgets/face_box_painter.dart';
import 'package:face_attendance_app/features/attendance/data/models/predict_response_model.dart';
import 'package:face_attendance_app/features/auth/data/models/user_model.dart';

/// Halaman utama scan absensi dengan kamera dan deteksi wajah (Light Theme).
class AttendanceScanPage extends StatefulWidget {
  final UserModel user;

  const AttendanceScanPage({super.key, required this.user});

  @override
  State<AttendanceScanPage> createState() => _AttendanceScanPageState();
}

class _AttendanceScanPageState extends State<AttendanceScanPage>
    with WidgetsBindingObserver {
  late AttendanceCubit _cubit;
  bool _permissionGranted = false;
  bool _permissionChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cubit = AttendanceCubit(user: widget.user);
    _requestCameraPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cubit.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cubit.cameraController;

    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _cubit.stopStream();
    } else if (state == AppLifecycleState.resumed) {
      _cubit.resumeStream();
    }
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _permissionGranted = status.isGranted;
      _permissionChecked = true;
    });

    if (_permissionGranted) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada kamera ditemukan')),
        );
      }
      return;
    }
    _cubit.initCamera(cameras);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: _permissionChecked
            ? (_permissionGranted ? _buildCameraView() : _buildPermissionDenied())
            : _buildLoading(),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text(
            'Memuat kamera...',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_outlined, size: 72, color: AppColors.textMuted),
            const SizedBox(height: 24),
            const Text(
              'Izin Kamera Diperlukan',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Aplikasi memerlukan akses kamera untuk mendeteksi wajah dan melakukan absensi.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => openAppSettings(),
              icon: const Icon(Icons.settings),
              label: const Text('Buka Pengaturan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    return BlocConsumer<AttendanceCubit, AttendanceState>(
      listener: (context, state) {
        if (state is AttendanceSuccess) {
          _showResultBottomSheet(context, state.result);
        }
        if (state is AttendanceError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
          _cubit.resetToCamera();
        }
      },
      builder: (context, state) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Layer 1: Camera preview
            _buildCameraPreview(state),

            // Layer 2: Face bounding box overlay
            if (state is CameraReady) _buildFaceOverlay(state),

            // Layer 3: Top bar
            _buildTopBar(),

            // Layer 4: Bottom panel
            _buildBottomPanel(state),

            // Layer 5: Loading overlay
            if (state is AttendancePredicting) _buildLoadingOverlay(),
          ],
        );
      },
    );
  }

  Widget _buildCameraPreview(AttendanceState state) {
    final controller = _cubit.cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.previewSize?.height ?? 1,
          height: controller.value.previewSize?.width ?? 1,
          child: CameraPreview(controller),
        ),
      ),
    );
  }

  Widget _buildFaceOverlay(CameraReady state) {
    if (state.faces.isEmpty || state.imageWidth == 0) return const SizedBox();

    final controller = _cubit.cameraController;
    if (controller == null) return const SizedBox();

    final rotation = _sensorOrientationToRotation(
      controller.description.sensorOrientation,
    );

    return CustomPaint(
      painter: FaceBoxPainter(
        faces: state.faces,
        imageSize: Size(state.imageWidth, state.imageHeight),
        lensDirection: controller.description.lensDirection,
        rotation: rotation,
      ),
    );
  }

  InputImageRotation _sensorOrientationToRotation(int sensorOrientation) {
    switch (sensorOrientation) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 20,
          bottom: 16,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xAA000000),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.face_retouching_natural, color: AppColors.success, size: 26),
            const SizedBox(width: 10),
            const Text(
              'Scan Wajah Absensi',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPanel(AttendanceState state) {
    final bool faceDetected = state is CameraReady && state.faceDetected;
    final bool canTap = faceDetected && state is! AttendancePredicting;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 20,
          top: 28,
          left: 24,
          right: 24,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Color(0xDD000000),
              Color(0x88000000),
              Colors.transparent,
            ],
            stops: [0.0, 0.7, 1.0],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusIndicator(faceDetected),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: canTap ? () => _cubit.captureAndPredict() : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canTap ? AppColors.success : AppColors.surfaceLight,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white24,
                  disabledForegroundColor: Colors.white38,
                  elevation: canTap ? 6 : 0,
                  shadowColor: AppColors.successFaded,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.how_to_reg_rounded,
                      size: 24,
                      color: canTap ? Colors.white : Colors.white38,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Absen Sekarang',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: canTap ? Colors.white : Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(bool faceDetected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: faceDetected
            ? AppColors.successFaded
            : AppColors.errorFaded,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: faceDetected
              ? AppColors.successBorder
              : AppColors.errorBorder,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            faceDetected ? Icons.face : Icons.face_retouching_off,
            color: faceDetected ? AppColors.success : AppColors.error,
            size: 22,
          ),
          const SizedBox(width: 10),
          Text(
            faceDetected
                ? 'Wajah terdeteksi, silakan absen'
                : 'Arahkan wajah ke kamera',
            style: TextStyle(
              color: faceDetected ? AppColors.success : AppColors.error,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: const Color(0xCC000000),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                color: AppColors.success,
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Mengenali wajah...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Mengirim ke server ML untuk verifikasi',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  void _showResultBottomSheet(BuildContext context, PredictResponseModel result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (ctx) => _ResultBottomSheet(
        result: result,
        onDismiss: () {
          Navigator.of(ctx).pop();
          _cubit.resetToCamera();
        },
      ),
    ).then((_) {
      _cubit.resetToCamera();
    });
  }
}

// ================================================================
// BOTTOM SHEET HASIL PREDIKSI (Light Theme)
// ================================================================

class _ResultBottomSheet extends StatelessWidget {
  final PredictResponseModel result;
  final VoidCallback onDismiss;

  const _ResultBottomSheet({
    required this.result,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final bool recognized = result.recognized;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: recognized ? AppColors.successBorder : AppColors.errorBorder,
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Status icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: recognized ? AppColors.successFaded : AppColors.errorFaded,
              ),
              child: Icon(
                recognized ? Icons.check_circle_rounded : Icons.cancel_rounded,
                size: 48,
                color: recognized ? AppColors.success : AppColors.error,
              ),
            ),
            const SizedBox(height: 20),

            // Status text
            Text(
              recognized ? 'Wajah Dikenali!' : 'Wajah Tidak Dikenali',
              style: TextStyle(
                color: recognized ? AppColors.success : AppColors.error,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              result.message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Detail info
            if (recognized) ...[
              _buildInfoRow(Icons.person, 'Nama', result.studentName ?? '-'),
              const SizedBox(height: 10),
              _buildInfoRow(Icons.badge, 'NIM', result.nim ?? '-'),
              const SizedBox(height: 10),
              _buildInfoRow(
                Icons.analytics,
                'Confidence',
                result.confidencePercent,
              ),
              const SizedBox(height: 10),
              _buildInfoRow(
                Icons.compare_arrows,
                'Similarity',
                result.similarityPercent,
              ),
              const SizedBox(height: 24),
            ],

            // Tombol OK
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: onDismiss,
                style: ElevatedButton.styleFrom(
                  backgroundColor: recognized ? AppColors.success : AppColors.surfaceLight,
                  foregroundColor: recognized ? Colors.white : AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  recognized ? 'Absensi Berhasil ✓' : 'Coba Lagi',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
