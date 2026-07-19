import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Singleton service untuk Firebase initialization dan instance access.
class FirebaseService {
  FirebaseService._();

  static bool _initialized = false;

  /// Initialize Firebase. Panggil sekali di main().
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      await Firebase.initializeApp();
      _initialized = true;
      debugPrint('[FirebaseService] ✅ Firebase berhasil diinisialisasi');
    } catch (e) {
      debugPrint('[FirebaseService] ❌ Gagal init Firebase: $e');
      rethrow;
    }
  }

  /// Firestore instance.
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;

  /// Firebase Auth instance.
  static FirebaseAuth get auth => FirebaseAuth.instance;

  /// Current user (null jika belum login).
  static User? get currentUser => auth.currentUser;

  /// Apakah user sudah login.
  static bool get isLoggedIn => currentUser != null;
}
