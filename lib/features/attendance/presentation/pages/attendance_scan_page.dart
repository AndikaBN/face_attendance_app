import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:face_attendance_app/features/attendance/presentation/cubit/attendance_cubit.dart';
import 'package:face_attendance_app/features/attendance/presentation/cubit/attendance_state.dart';
import 'package:face_attendance_app/features/attendance/presentation/widgets/face_box_painter.dart';
import 'package:face_attendance_app/features/attendance/data/models/predict_response_model.dart';

import 'package:face_attendance_app/features/auth/data/models/user_model.dart';

/// Halaman utama scan absensi dengan kamera dan deteksi wajah.
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

    // Jangan proses jika kamera belum ready
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      // Hanya stop stream, JANGAN dispose controller
      // Dispose menyebabkan crash di widget tree
      _cubit.stopStream();
    } else if (state == AppLifecycleState.resumed) {
      // Restart stream saat app kembali aktif
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
        backgroundColor: const Color(0xFF0A0E21),
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
          CircularProgressIndicator(color: Color(0xFF64FFDA)),
          SizedBox(height: 16),
          Text(
            'Memuat kamera...',
            style: TextStyle(color: Colors.white70, fontSize: 16),
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
            const Icon(Icons.camera_alt_outlined, size: 72, color: Colors.white38),
            const SizedBox(height: 24),
            const Text(
              'Izin Kamera Diperlukan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Aplikasi memerlukan akses kamera untuk mendeteksi wajah dan melakukan absensi.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 15),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => openAppSettings(),
              icon: const Icon(Icons.settings),
              label: const Text('Buka Pengaturan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF64FFDA),
                foregroundColor: const Color(0xFF0A0E21),
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
              backgroundColor: Colors.redAccent,
            ),
          );
          // Reset ke kamera setelah error
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
        child: CircularProgressIndicator(color: Color(0xFF64FFDA)),
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

    // Tentukan rotasi berdasarkan sensor orientation
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
          left: 20,
          right: 20,
          bottom: 16,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xCC0A0E21),
              Colors.transparent,
            ],
          ),
        ),
        child: const Row(
          children: [
            Icon(Icons.face_retouching_natural, color: Color(0xFF64FFDA), size: 28),
            SizedBox(width: 12),
            Text(
              'Absensi Wajah',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
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
              Color(0xEE0A0E21),
              Color(0xAA0A0E21),
              Colors.transparent,
            ],
            stops: [0.0, 0.7, 1.0],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status indicator
            _buildStatusIndicator(faceDetected),

            const SizedBox(height: 20),

            // Tombol Absen
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: canTap ? () => _cubit.captureAndPredict() : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      canTap ? const Color(0xFF64FFDA) : const Color(0xFF1A1F38),
                  foregroundColor: const Color(0xFF0A0E21),
                  disabledBackgroundColor: const Color(0xFF1A1F38),
                  disabledForegroundColor: Colors.white24,
                  elevation: canTap ? 8 : 0,
                  shadowColor: const Color(0x4064FFDA),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: canTap
                          ? const Color(0xFF64FFDA)
                          : const Color(0xFF2A2F48),
                      width: 1.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.how_to_reg_rounded,
                      size: 24,
                      color: canTap ? const Color(0xFF0A0E21) : Colors.white24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Absen Sekarang',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: canTap ? const Color(0xFF0A0E21) : Colors.white24,
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
            ? const Color(0x2064FFDA)
            : const Color(0x20FF6B6B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: faceDetected
              ? const Color(0x4064FFDA)
              : const Color(0x40FF6B6B),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            faceDetected ? Icons.face : Icons.face_retouching_off,
            color: faceDetected
                ? const Color(0xFF64FFDA)
                : const Color(0xFFFF6B6B),
            size: 22,
          ),
          const SizedBox(width: 10),
          Text(
            faceDetected
                ? 'Wajah terdeteksi, silakan absen'
                : 'Arahkan wajah ke kamera',
            style: TextStyle(
              color: faceDetected
                  ? const Color(0xFF64FFDA)
                  : const Color(0xFFFF6B6B),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: const Color(0xCC0A0E21),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(
                color: Color(0xFF64FFDA),
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Mengenali wajah...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Mengirim ke server untuk verifikasi',
              style: TextStyle(color: Colors.white38, fontSize: 14),
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
      // Jika user dismiss dengan swipe, juga reset
      _cubit.resetToCamera();
    });
  }
}

// ================================================================
// BOTTOM SHEET HASIL PREDIKSI
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
        color: const Color(0xFF141829),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: recognized
              ? const Color(0x4064FFDA)
              : const Color(0x40FF6B6B),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: recognized
                ? const Color(0x3064FFDA)
                : const Color(0x30FF6B6B),
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
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
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
                color: recognized
                    ? const Color(0x2064FFDA)
                    : const Color(0x20FF6B6B),
              ),
              child: Icon(
                recognized ? Icons.check_circle_rounded : Icons.cancel_rounded,
                size: 48,
                color: recognized
                    ? const Color(0xFF64FFDA)
                    : const Color(0xFFFF6B6B),
              ),
            ),
            const SizedBox(height: 20),

            // Status text
            Text(
              recognized ? 'Wajah Dikenali!' : 'Wajah Tidak Dikenali',
              style: TextStyle(
                color: recognized
                    ? const Color(0xFF64FFDA)
                    : const Color(0xFFFF6B6B),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              result.message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Detail info
            if (recognized) ...[
              _buildInfoRow(Icons.person, 'Nama', result.studentName ?? '-'),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.badge, 'NPM', result.nim ?? '-'),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.analytics,
                'Confidence',
                result.confidencePercent,
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.compare_arrows,
                'Similarity',
                result.similarityPercent,
              ),
              const SizedBox(height: 28),
            ],

            // Tombol OK
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: onDismiss,
                style: ElevatedButton.styleFrom(
                  backgroundColor: recognized
                      ? const Color(0xFF64FFDA)
                      : const Color(0xFF2A2F48),
                  foregroundColor: recognized
                      ? const Color(0xFF0A0E21)
                      : Colors.white70,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  recognized ? 'Absensi Berhasil ✓' : 'Coba Lagi',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F38),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF64FFDA), size: 22),
          const SizedBox(width: 14),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
