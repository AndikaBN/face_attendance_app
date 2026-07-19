import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:face_attendance_app/features/auth/data/repositories/auth_repository.dart';
import 'package:face_attendance_app/features/auth/presentation/cubit/auth_state.dart';

/// Cubit untuk mengelola state autentikasi.
class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repository;

  AuthCubit({AuthRepository? repository})
      : _repository = repository ?? AuthRepository(),
        super(const AuthInitial());

  /// Cek status login saat app start.
  Future<void> checkAuth() async {
    emit(const AuthLoading());
    try {
      final user = await _repository.getCurrentUser();
      if (user != null) {
        emit(AuthAuthenticated(user: user));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      debugPrint('[AuthCubit] checkAuth error: $e');
      emit(const AuthUnauthenticated());
    }
  }

  /// Login dengan email dan password.
  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(const AuthLoading());
    try {
      final user = await _repository.login(email: email, password: password);
      emit(AuthAuthenticated(user: user));
    } on FirebaseAuthException catch (e) {
      emit(AuthError(message: _mapFirebaseError(e.code)));
    } catch (e) {
      emit(AuthError(message: 'Login gagal: $e'));
    }
  }

  /// Register user baru.
  Future<void> register({
    required String email,
    required String password,
    required String name,
    String? nim,
    required String role,
  }) async {
    emit(const AuthLoading());
    try {
      final user = await _repository.register(
        email: email,
        password: password,
        name: name,
        nim: nim,
        role: role,
      );
      emit(AuthAuthenticated(user: user));
    } on FirebaseAuthException catch (e) {
      emit(AuthError(message: _mapFirebaseError(e.code)));
    } catch (e) {
      emit(AuthError(message: 'Register gagal: $e'));
    }
  }

  /// Logout.
  Future<void> logout() async {
    await _repository.logout();
    emit(const AuthUnauthenticated());
  }

  /// Map Firebase error codes ke pesan bahasa Indonesia.
  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Akun tidak ditemukan. Silakan register terlebih dahulu.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email atau password salah.';
      case 'email-already-in-use':
        return 'Email sudah terdaftar. Silakan login.';
      case 'weak-password':
        return 'Password terlalu lemah. Minimal 6 karakter.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti.';
      case 'network-request-failed':
        return 'Tidak ada koneksi internet.';
      default:
        return 'Terjadi kesalahan: $code';
    }
  }
}
