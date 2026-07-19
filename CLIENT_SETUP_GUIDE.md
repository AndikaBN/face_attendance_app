# PANDUAN SETUP REMOTE CLIENT — FACE ATTENDANCE APP

Dokumen ini dibuat khusus untuk memandu Anda melakukan remote setup menggunakan **TeamViewer / AnyDesk** di komputer client dari awal sampai aplikasi siap digunakan.

---

## DAFTAR ISI
1. [Langkah 1: Menambahkan Anggota (Client) di Firebase Console](#1-menambahkan-anggota-di-firebase-console)
2. [Langkah 2: Setup Firebase CLI di Komputer Client](#2-setup-firebase-cli-di-komputer-client)
3. [Langkah 3: Setup & Menjalankan ML Backend (Python)](#3-setup--menjalankan-ml-backend-python)
4. [Langkah 4: Setup & Menjalankan Aplikasi Flutter](#4-setup--menjalankan-aplikasi-flutter)

---

## 1. MENAMBAHKAN ANGGOTA DI FIREBASE CONSOLE

Agar client bisa mengakses project Firebase **`face-attendance-be662`** Anda:

1. Buka **[Firebase Console](https://console.firebase.google.com/)** di browser Anda.
2. Pilih project **`face-attendance-be662`**.
3. Di panel kiri, klik ikon gerigi **Settings (Setelan Project)** -> pilih **Users and Permissions (Pengguna dan Izin)**.
4. Klik tombol **Add member (Tambahkan anggota)** di bagian kanan atas.
5. Masukkan **Email Google client** Anda.
6. Pilih **Role (Peran)**:
   * **Editor** (bisa edit Firestore/Auth tetapi tidak bisa hapus project) ATAU
   * **Viewer** (hanya bisa melihat).
7. Klik **Add member (Tambahkan anggota)**.
8. Minta client untuk membuka Gmail-nya dan klik **Terima Undangan (Accept Invitation)**.

---

## 2. SETUP FIREBASE CLI DI KOMPUTER CLIENT

Langkah ini diperlukan agar komputer client terhubung dengan akun Firebase Anda.

### A. Install Firebase CLI
Buka Terminal/Command Prompt di komputer client, lalu install Firebase CLI (membutuhkan Node.js terinstall):
```bash
npm install -g firebase-tools
```
*Jika client tidak punya Node.js, download installer standalone Firebase CLI di [dokumentasi resmi Firebase](https://firebase.google.com/docs/cli#install_the_firebase_cli).*

### B. Login ke Firebase CLI
Jalankan perintah berikut di Terminal client:
```bash
firebase login
```
1. Browser otomatis akan terbuka ke halaman login Google.
2. Minta client login menggunakan akun Google-nya (yang sudah Anda tambahkan sebagai anggota di Langkah 1).
3. Klik **Allow** (Izinkan).
4. Terminal akan menampilkan pesan: `✔ Success! Logged in as email@client.com`.

*Catatan: Jika remote browser bermasalah / lemot, gunakan mode manual:*
```bash
firebase login --no-localhost
```
Copy link yang muncul di terminal, paste ke browser client, lalu copy kode otorisasi dan paste kembali ke terminal.

### C. Install FlutterFire CLI
Jalankan perintah ini untuk mengaktifkan FlutterFire secara global di komputer client:
```bash
dart pub global activate flutterfire_cli
```
*Pastikan path Dart/Flutter sudah terdaftar di environment variable OS client.*

---

## 3. SETUP & MENJALANKAN ML BACKEND (PYTHON)

### A. Copy/Clone File ML Backend
Pindahkan folder `face-recognition-ml` ke komputer client.

### B. Buat Virtual Environment
Buka terminal client di dalam folder `face-recognition-ml` dan buat venv:
```bash
# Windows
python -m venv venv
venv\Scripts\activate

# macOS / Linux
python3 -m venv venv
source venv/bin/activate
```

### C. Install Dependencies & Jalankan
```bash
# Upgrade pip
pip install --upgrade pip

# Install requirements
pip install -r requirements.txt

# Jalankan API server
python api/app.py
```
*Pastikan server backend berjalan di port 5000 (atau 5001) dan tampil pesan model loaded.*

---

## 4. SETUP & MENJALANKAN APLIKASI FLUTTER

### A. Copy/Clone Aplikasi Flutter
Pindahkan folder `face_attendance_app` ke komputer client.

### B. Sesuaikan IP Server Backend
Buka file `lib/core/constants/api_config.dart` di editor client. Ubah `baseUrl` sesuai IP lokal komputer client / IP server backend:
```dart
static const String baseUrl = "http://IP_LELAP_PC_CLIENT:5000";
```

### C. Jalankan Config Firebase (Jika Perlu Regenerasi File)
Jika ingin mendaftarkan ulang konfigurasi Firebase di komputer client:
```bash
flutterfire configure --project=face-attendance-be662
```
Pilih platform Android & iOS (sesuai target device client). File `google-services.json` dan `GoogleService-Info.plist` akan terbuat secara otomatis dengan konfigurasi yang tepat.

### D. Download Package & Jalankan App
Minta client menyambungkan HP-nya (aktifkan USB Debugging) atau gunakan Emulator:
```bash
# Bersihkan cache
flutter clean

# Ambil packages
flutter pub get

# Jalankan aplikasi
flutter run
```

---

## TIPS BILA TERJADI ERROR SAAT REMOTE
* **Error `Firebase has not been correctly initialized`:** Pastikan file `google-services.json` (Android) / `GoogleService-Info.plist` (iOS) sudah berada di folder proyek yang benar setelah menjalankan `flutterfire configure`.
* **Kamera tidak muncul:** Izinkan akses kamera secara manual di pengaturan HP/Emulator client.
* **Tidak bisa seeding database:** Ketuk judul **"Face Attendance"** 5 kali di halaman login untuk memicu automatic seeder.
