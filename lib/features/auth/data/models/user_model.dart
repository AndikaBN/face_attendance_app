import 'package:cloud_firestore/cloud_firestore.dart';

/// Model user yang disimpan di Firestore collection 'users'.
class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? nim;
  final String role; // "mahasiswa" | "dosen"
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.nim,
    required this.role,
    required this.createdAt,
  });

  bool get isMahasiswa => role == 'mahasiswa';
  bool get isDosen => role == 'dosen';

  /// Parse dari Firestore document.
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      nim: data['nim']?.toString(),
      role: data['role']?.toString() ?? 'mahasiswa',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Konversi ke Map untuk simpan ke Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'nim': nim,
      'role': role,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  @override
  String toString() => 'UserModel(uid: $uid, name: $name, role: $role)';
}
