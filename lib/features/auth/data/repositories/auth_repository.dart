import 'package:flutter/foundation.dart';
import 'package:face_attendance_app/core/services/firebase_service.dart';
import 'package:face_attendance_app/features/auth/data/models/user_model.dart';

/// Repository untuk operasi autentikasi dan manajemen user.
class AuthRepository {
  /// Register user baru dengan email dan password.
  /// Simpan profile ke Firestore collection 'users'.
  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
    String? nim,
    required String role,
  }) async {
    try {
      // 1. Buat akun di Firebase Auth
      final credential = await FirebaseService.auth
          .createUserWithEmailAndPassword(email: email, password: password);

      final uid = credential.user!.uid;

      // 2. Simpan profile ke Firestore
      final userModel = UserModel(
        uid: uid,
        email: email,
        name: name,
        nim: nim,
        role: role,
        createdAt: DateTime.now(),
      );

      await FirebaseService.firestore
          .collection('users')
          .doc(uid)
          .set(userModel.toFirestore());

      debugPrint('[AuthRepository] ✅ Register berhasil: $name ($role)');
      return userModel;
    } catch (e) {
      debugPrint('[AuthRepository] ❌ Register gagal: $e');
      rethrow;
    }
  }

  /// Login dengan email dan password.
  /// Returns UserModel dari Firestore.
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Login ke Firebase Auth
      final credential = await FirebaseService.auth
          .signInWithEmailAndPassword(email: email, password: password);

      final uid = credential.user!.uid;

      // 2. Ambil profile dari Firestore
      final userModel = await getUserProfile(uid);
      debugPrint('[AuthRepository] ✅ Login berhasil: ${userModel.name}');
      return userModel;
    } catch (e) {
      debugPrint('[AuthRepository] ❌ Login gagal: $e');
      rethrow;
    }
  }

  /// Logout user.
  Future<void> logout() async {
    await FirebaseService.auth.signOut();
    debugPrint('[AuthRepository] ✅ Logout');
  }

  /// Ambil user profile dari Firestore berdasarkan UID.
  Future<UserModel> getUserProfile(String uid) async {
    final doc =
        await FirebaseService.firestore.collection('users').doc(uid).get();

    if (!doc.exists) {
      throw Exception('Profile user tidak ditemukan di database');
    }

    return UserModel.fromFirestore(doc);
  }

  /// Cek apakah user saat ini sudah login dan ambil profilenya.
  /// Returns null jika belum login.
  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = FirebaseService.currentUser;
    if (firebaseUser == null) return null;

    try {
      return await getUserProfile(firebaseUser.uid);
    } catch (e) {
      debugPrint('[AuthRepository] Error ambil current user: $e');
      return null;
    }
  }
}
