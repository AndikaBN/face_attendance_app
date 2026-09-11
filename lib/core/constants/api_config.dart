/// Konfigurasi API untuk koneksi ke Flask ML backend.
class ApiConfig {
  /// Base URL Flask API.
  /// Ganti dengan URL ngrok jika menggunakan tunnel.
  static const String baseUrl = "https://fd97-103-190-47-12.ngrok-free.app";

  /// Endpoint untuk prediksi wajah.
  static const String predictEndpoint = "/predict";

  /// Endpoint untuk daftar mahasiswa.
  static const String studentsEndpoint = "/students";

  /// Endpoint health check.
  static const String healthEndpoint = "/health";

  /// Timeout dalam detik.
  static const int connectTimeout = 30;
  static const int receiveTimeout = 30;
}
