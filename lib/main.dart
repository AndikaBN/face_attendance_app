import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:face_attendance_app/core/constants/app_colors.dart';
import 'package:face_attendance_app/core/services/firebase_service.dart';
import 'package:face_attendance_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:face_attendance_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:face_attendance_app/features/auth/presentation/pages/login_page.dart';
import 'package:face_attendance_app/features/student/presentation/pages/student_dashboard_page.dart';
import 'package:face_attendance_app/features/lecturer/presentation/pages/lecturer_dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Status bar transparan
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.background,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Initialize Firebase
  await FirebaseService.initialize();

  // Initialize Indonesian locale for date formatting
  await initializeDateFormatting('id_ID', null);

  runApp(const FaceAttendanceApp());
}

class FaceAttendanceApp extends StatelessWidget {
  const FaceAttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit()..checkAuth(),
      child: MaterialApp(
        title: 'Face Attendance',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.background,
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            secondary: AppColors.primary,
            surface: AppColors.surface,
            onPrimary: AppColors.background,
            onSurface: Colors.white,
          ),
          fontFamily: 'Roboto',
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.background,
            elevation: 0,
            centerTitle: true,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        home: const _AuthGate(),
      ),
    );
  }
}

/// Auth gate — routes user berdasarkan status login dan role.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        // Loading
        if (state is AuthInitial || state is AuthLoading) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 20),
                  Text(
                    'Memuat...',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 15),
                  ),
                ],
              ),
            ),
          );
        }

        // Not logged in
        if (state is AuthUnauthenticated || state is AuthError) {
          return const LoginPage();
        }

        // Logged in — route by role
        if (state is AuthAuthenticated) {
          if (state.isMahasiswa) {
            return StudentDashboardPage(user: state.user);
          } else if (state.isDosen) {
            return LecturerDashboardPage(user: state.user);
          }
        }

        return const LoginPage();
      },
    );
  }
}
