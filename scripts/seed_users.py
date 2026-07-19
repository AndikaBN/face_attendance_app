"""
Seed script: Membuat akun Firebase Auth + Firestore profile
untuk 20 mahasiswa dan 1 dosen.

Cara pakai:
1. Buka Firebase Console → Project Settings → Service Accounts
2. Klik "Generate New Private Key" → download JSON
3. Taruh file JSON di folder ini, rename ke "serviceAccountKey.json"
4. Install firebase-admin: pip install firebase-admin
5. Jalankan: python seed_users.py

Password default semua akun: 123456
"""

import firebase_admin
from firebase_admin import credentials, auth, firestore
import sys
import os

# ============================================================
# KONFIGURASI
# ============================================================

SERVICE_ACCOUNT_KEY = os.path.join(os.path.dirname(__file__), "serviceAccountKey.json")
DEFAULT_PASSWORD = "123456"

# Data 20 mahasiswa dari dataset (nama sesuai label_id ML model)
STUDENTS = [
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
]

# 1 Dosen
LECTURERS = [
    {"name": "Dosen Demo", "email": "dosen@demo.ac.id"},
]

# ============================================================
# MAIN
# ============================================================

def main():
    # Cek service account key
    if not os.path.exists(SERVICE_ACCOUNT_KEY):
        print("❌ File serviceAccountKey.json tidak ditemukan!")
        print()
        print("Cara mendapatkan:")
        print("1. Buka Firebase Console → Project Settings → Service Accounts")
        print("2. Klik 'Generate New Private Key'")
        print("3. Download file JSON")
        print(f"4. Taruh di: {os.path.dirname(os.path.abspath(__file__))}/serviceAccountKey.json")
        sys.exit(1)

    # Init Firebase Admin
    cred = credentials.Certificate(SERVICE_ACCOUNT_KEY)
    firebase_admin.initialize_app(cred)
    db = firestore.client()

    print("=" * 60)
    print("  SEED USERS — Face Attendance App")
    print("=" * 60)
    print(f"  Password default: {DEFAULT_PASSWORD}")
    print(f"  Mahasiswa: {len(STUDENTS)}")
    print(f"  Dosen: {len(LECTURERS)}")
    print("=" * 60)
    print()

    success_count = 0
    skip_count = 0
    error_count = 0

    # Seed mahasiswa
    print("📚 Membuat akun mahasiswa...")
    print("-" * 50)
    for i, student in enumerate(STUDENTS, 1):
        try:
            # Cek apakah email sudah terdaftar
            try:
                existing = auth.get_user_by_email(student["email"])
                print(f"  ⏭️  {i:2d}. {student['name']} ({student['nim']}) — sudah ada, skip")
                skip_count += 1
                continue
            except auth.UserNotFoundError:
                pass

            # Buat akun Auth
            user = auth.create_user(
                email=student["email"],
                password=DEFAULT_PASSWORD,
                display_name=student["name"],
            )

            # Simpan profile ke Firestore
            db.collection("users").document(user.uid).set({
                "email": student["email"],
                "name": student["name"],
                "nim": student["nim"],
                "role": "mahasiswa",
                "created_at": firestore.SERVER_TIMESTAMP,
            })

            print(f"  ✅ {i:2d}. {student['name']} ({student['nim']}) — {student['email']}")
            success_count += 1

        except Exception as e:
            print(f"  ❌ {i:2d}. {student['name']} — ERROR: {e}")
            error_count += 1

    print()

    # Seed dosen
    print("👨‍🏫 Membuat akun dosen...")
    print("-" * 50)
    for lecturer in LECTURERS:
        try:
            try:
                existing = auth.get_user_by_email(lecturer["email"])
                print(f"  ⏭️  {lecturer['name']} — sudah ada, skip")
                skip_count += 1
                continue
            except auth.UserNotFoundError:
                pass

            user = auth.create_user(
                email=lecturer["email"],
                password=DEFAULT_PASSWORD,
                display_name=lecturer["name"],
            )

            db.collection("users").document(user.uid).set({
                "email": lecturer["email"],
                "name": lecturer["name"],
                "nim": None,
                "role": "dosen",
                "created_at": firestore.SERVER_TIMESTAMP,
            })

            print(f"  ✅ {lecturer['name']} — {lecturer['email']}")
            success_count += 1

        except Exception as e:
            print(f"  ❌ {lecturer['name']} — ERROR: {e}")
            error_count += 1

    # Summary
    print()
    print("=" * 60)
    print(f"  SELESAI!")
    print(f"  ✅ Berhasil: {success_count}")
    print(f"  ⏭️  Sudah ada: {skip_count}")
    print(f"  ❌ Error: {error_count}")
    print("=" * 60)
    print()
    print("📋 Daftar akun:")
    print("-" * 60)
    print(f"{'Email':<35} {'Password':<10} {'Role'}")
    print("-" * 60)
    for s in STUDENTS:
        print(f"{s['email']:<35} {DEFAULT_PASSWORD:<10} mahasiswa")
    for l in LECTURERS:
        print(f"{l['email']:<35} {DEFAULT_PASSWORD:<10} dosen")
    print("-" * 60)


if __name__ == "__main__":
    main()
