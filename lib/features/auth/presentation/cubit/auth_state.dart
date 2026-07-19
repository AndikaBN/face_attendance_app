import 'package:face_attendance_app/features/auth/data/models/user_model.dart';

/// Base state untuk Auth.
abstract class AuthState {
  const AuthState();
}

/// State awal — belum dicek status login.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Sedang memproses (login/register/check).
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// User sudah terautentikasi.
class AuthAuthenticated extends AuthState {
  final UserModel user;

  const AuthAuthenticated({required this.user});

  String get role => user.role;
  bool get isMahasiswa => user.isMahasiswa;
  bool get isDosen => user.isDosen;
}

/// User belum login / sudah logout.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Error autentikasi.
class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});
}
