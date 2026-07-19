import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseSeeder {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String defaultPassword = "123456";

  static final List<Map<String, String>> students = [
    {"name": "indy auliya", "nim": "25441120", "email": "indy.auliya@student.ac.id"},
    {"name": "tiara nurjahra", "nim": "25441086", "email": "tiara.nurjahra@student.ac.id"},
    {"name": "nailah aswana", "nim": "25441127", "email": "nailah.aswana@student.ac.id"},
    {"name": "anis aulia", "nim": "25441113", "email": "anis.aulia@student.ac.id"},
    {"name": "sheza ibnu shabil", "nim": "25441112", "email": "sheza.ibnu@student.ac.id"},
    {"name": "trindah aini ruska", "nim": "25441087", "email": "trindah.aini@student.ac.id"},
    {"name": "agina despiani br sitepu", "nim": "25441117", "email": "agina.despiani@student.ac.id"},
    {"name": "elsa amelia putri", "nim": "25441121", "email": "elsa.amelia@student.ac.id"},
    {"name": "nabila nazwa tasya", "nim": "25441099", "email": "nabila.nazwa@student.ac.id"},
    {"name": "syifa salsabila", "nim": "25441084", "email": "syifa.salsabila@student.ac.id"},
    {"name": "ceriya bintang syahruni ptri", "nim": "25441105", "email": "ceriya.bintang@student.ac.id"},
    {"name": "eliza indrayani", "nim": "25441104", "email": "eliza.indrayani@student.ac.id"},
    {"name": "khairani", "nim": "25441119", "email": "khairani@student.ac.id"},
    {"name": "fachri fahlevi", "nim": "25441108", "email": "fachri.fahlevi@student.ac.id"},
    {"name": "alverza ramadhan", "nim": "25441106", "email": "alverza.ramadhan@student.ac.id"},
    {"name": "diva adhelia afandy", "nim": "25441116", "email": "diva.adhelia@student.ac.id"},
    {"name": "nasyaila kanaya helmi", "nim": "25441094", "email": "nasyaila.kanaya@student.ac.id"},
    {"name": "rio ananta benediktus", "nim": "25441114", "email": "rio.ananta@student.ac.id"},
    {"name": "zhahran bayu wicaksono", "nim": "25441088", "email": "zhahran.bayu@student.ac.id"},
    {"name": "dimas syahputra", "nim": "25441111", "email": "dimas.syahputra@student.ac.id"},
  ];

  static final List<Map<String, String>> lecturers = [
    {"name": "Dosen Demo", "email": "dosen@demo.ac.id"},
  ];

  /// Jalankan proses seeding secara lokal melalui UI
  static Future<void> seed(Function(String) onProgress, Function(String) onError, VoidCallback onComplete) async {
    try {
      // 1. Seed Mahasiswa
      for (var s in students) {
        try {
          onProgress("Mendaftarkan Mahasiswa: ${s['name']}...");
          
          // Buat akun Auth
          final credential = await _auth.createUserWithEmailAndPassword(
            email: s['email']!,
            password: defaultPassword,
          );

          // Simpan profile ke Firestore
          await _firestore.collection('users').doc(credential.user!.uid).set({
            'email': s['email'],
            'name': s['name'],
            'nim': s['nim'],
            'role': 'mahasiswa',
            'created_at': FieldValue.serverTimestamp(),
          }).timeout(const Duration(seconds: 8));

        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            onProgress("Skip (Sudah ada): ${s['name']}");
          } else {
            onError("Gagal ${s['name']}: ${e.message}");
          }
        } catch (e) {
          onError("Gagal ${s['name']}: $e");
        }
      }

      // 2. Seed Dosen
      for (var l in lecturers) {
        try {
          onProgress("Mendaftarkan Dosen: ${l['name']}...");
          
          final credential = await _auth.createUserWithEmailAndPassword(
            email: l['email']!,
            password: defaultPassword,
          );

          await _firestore.collection('users').doc(credential.user!.uid).set({
            'email': l['email'],
            'name': l['name'],
            'nim': null,
            'role': 'dosen',
            'created_at': FieldValue.serverTimestamp(),
          }).timeout(const Duration(seconds: 8));

        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            onProgress("Skip (Sudah ada): ${l['name']}");
          } else {
            onError("Gagal ${l['name']}: ${e.message}");
          }
        } catch (e) {
          onError("Gagal ${l['name']}: $e");
        }
      }

      // Setelah selesai, logout agar kembali bersih
      await _auth.signOut();
      onComplete();
    } catch (e) {
      onError("Proses Seeding error: $e");
    }
  }
}
