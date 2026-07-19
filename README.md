# Face Attendance App — Flutter

Aplikasi absensi mahasiswa berbasis **face recognition** menggunakan Flutter, Firebase, dan Flask ML backend.

## Fitur

| Role | Fitur |
|------|-------|
| **Mahasiswa** | Login → Dashboard → Scan Absensi (face recognition) → Riwayat |
| **Dosen** | Login → Dashboard → Lihat absensi mahasiswa → Filter per tanggal |

## Tech Stack

- **Flutter** — Mobile app (iOS dan Android)
- **Firebase Auth** — Autentikasi email/password
- **Cloud Firestore** — Database absensi
- **Flask API** — Backend ML (face recognition dengan InsightFace/ArcFace)
- **google_mlkit_face_detection** — Deteksi wajah lokal (on-device)
- **flutter_bloc** — State management (Cubit)

---

## Setup Firebase (Step-by-Step)

### 1. Buat Project Firebase

1. Buka [Firebase Console](https://console.firebase.google.com)
2. Klik **"Add project"** / **"Tambah project"**
3. Beri nama project (misal: `face-attendance`)
4. **Disable** Google Analytics (opsional, tidak diperlukan)
5. Klik **"Create project"**

### 2. Tambahkan Aplikasi iOS

1. Di Firebase Console, klik ikon **iOS**
2. **Apple bundle ID:** `com.example.faceAttendanceApp`
   - Cek di `ios/Runner.xcodeproj` → Build Settings → Product Bundle Identifier
3. Klik **"Register app"**
4. Download file **`GoogleService-Info.plist`**
5. **Taruh file** di: `ios/Runner/GoogleService-Info.plist`
   - Buka Xcode → klik kanan folder Runner → Add Files → pilih `GoogleService-Info.plist`
   - Pastikan "Copy items if needed" dicentang
6. Klik **Next** sampai selesai

### 3. Tambahkan Aplikasi Android

1. Di Firebase Console, klik ikon **Android**
2. **Android package name:** `com.example.face_attendance_app`
   - Cek di `android/app/build.gradle.kts` → `namespace`
3. **(Opsional)** Debug signing certificate SHA-1:
   ```bash
   cd android && ./gradlew signingReport
   ```
   Copy SHA-1 dari variant `debug`
4. Klik **"Register app"**
5. Download file **`google-services.json`**
6. **Taruh file** di: `android/app/google-services.json`
7. Klik **Next** sampai selesai

### 4. Enable Authentication

1. Di Firebase Console → **Authentication** → **Sign-in method**
2. Klik **"Email/Password"**
3. Toggle **Enable** → klik **Save**

### 5. Buat Firestore Database

1. Di Firebase Console → **Firestore Database**
2. Klik **"Create database"**
3. Pilih lokasi server terdekat (misal: `asia-southeast2` untuk Jakarta)
4. Pilih **"Start in test mode"** (untuk development)
5. Klik **"Create"**

### 6. Set Firestore Security Rules

Di Firebase Console → Firestore → **Rules**, paste:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow create: if request.auth.uid == userId;
      allow update: if request.auth.uid == userId;
    }
    match /attendance_logs/{logId} {
      allow create: if request.auth != null;
      allow read: if request.auth != null;
    }
  }
}
```

Klik **"Publish"**.

### 7. Buat Firestore Indexes

Di Firebase Console → Firestore → **Indexes**, buat composite index:

| Collection | Fields | Query Scope |
|---|---|---|
| `attendance_logs` | `user_uid` Asc, `date_key` Asc, `recognized` Asc | Collection |
| `attendance_logs` | `user_uid` Asc, `recognized` Asc, `timestamp` Desc | Collection |
| `attendance_logs` | `date_key` Asc, `recognized` Asc, `timestamp` Asc | Collection |

> **Tip:** Index akan otomatis diminta saat pertama kali query dijalankan. Cek log error di debug console, klik link yang diberikan Firebase untuk auto-create index.

---

## Setup Project Flutter

### 1. Install Dependencies

```bash
cd face_attendance_app
flutter pub get
```

### 2. Konfigurasi API Backend

Edit file `lib/core/constants/api_config.dart`:

```dart
static const String baseUrl = "http://192.168.18.12:5000";
// Atau jika menggunakan ngrok:
// static const String baseUrl = "https://xxxx.ngrok-free.app";
```

### 3. Jalankan Flask Backend

```bash
cd face-recognition-ml
source venv/bin/activate
python api/app.py
```

### 4. Jalankan Flutter App

```bash
cd face_attendance_app
flutter run
```

---

## Cara Menggunakan

### Sebagai Mahasiswa

1. **Register** — Pilih role "Mahasiswa", isi nama, email, NIM, password
2. **Login** — Masukkan email dan password
3. **Dashboard** — Lihat status absensi hari ini
4. **Scan Absensi** — Arahkan wajah ke kamera, klik "Absen Sekarang"
5. **Riwayat** — Lihat semua riwayat kehadiran

### Sebagai Dosen

1. **Register** — Pilih role "Dosen", isi nama, email, password
2. **Login** — Masukkan email dan password
3. **Dashboard** — Lihat daftar mahasiswa yang hadir hari ini
4. **Filter Tanggal** — Gunakan panah kiri/kanan atau klik tanggal untuk date picker
5. **Statistik** — Lihat jumlah hadir, total mahasiswa, dan persentase kehadiran

---

## Firestore Collections

### `users`
| Field | Type | Keterangan |
|-------|------|------------|
| `email` | string | Email user |
| `name` | string | Nama lengkap |
| `nim` | string? | NIM (null untuk dosen) |
| `role` | string | "mahasiswa" / "dosen" |
| `created_at` | timestamp | Tanggal registrasi |

### `attendance_logs`
| Field | Type | Keterangan |
|-------|------|------------|
| `user_uid` | string | Reference ke users |
| `student_name` | string | Nama dari ML prediction |
| `nim` | string | NIM dari ML prediction |
| `confidence` | double | Confidence score |
| `similarity` | double | Similarity score |
| `recognized` | bool | Apakah dikenali |
| `message` | string | Pesan dari API |
| `timestamp` | timestamp | Waktu absensi |
| `date_key` | string | "2026-07-17" (filter harian) |

---

## Troubleshooting

### Firebase Init Error
- Pastikan `google-services.json` dan `GoogleService-Info.plist` sudah di tempat yang benar
- Jalankan `flutter clean && flutter pub get` setelah menambahkan file

### CocoaPods Error (iOS)
```bash
cd ios && rm -rf Pods Podfile.lock && cd .. && flutter clean && flutter pub get
```

### Firestore Index Error
Jika muncul error "requires an index", klik link di error message untuk auto-create index.

### Koneksi ke Backend
- Pastikan Flask API berjalan dan accessible dari device
- Jika pakai device fisik, gunakan IP lokal (bukan `localhost`)
- Jika pakai ngrok: `ngrok http 5000`, lalu update `baseUrl`
