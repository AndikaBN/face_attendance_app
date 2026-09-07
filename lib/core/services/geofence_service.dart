import 'package:geolocator/geolocator.dart';
import 'package:face_attendance_app/core/constants/geofence_config.dart';

class GeofenceCheckResult {
  final Position position;
  final double distanceMeters;

  const GeofenceCheckResult({
    required this.position,
    required this.distanceMeters,
  });
}

class GeofenceService {
  Future<GeofenceCheckResult> getVerifiedPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Layanan lokasi/GPS harus diaktifkan untuk absensi');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Izin lokasi diperlukan untuk melakukan absensi');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      ),
    );

    if (position.isMocked) {
      throw Exception('Lokasi palsu terdeteksi. Matikan aplikasi pengubah GPS');
    }

    if (position.accuracy > GeofenceConfig.maxAccuracyMeters) {
      throw Exception(
        'Akurasi lokasi terlalu rendah (${position.accuracy.toStringAsFixed(1)} m). '
        'Coba aktifkan GPS di area terbuka',
      );
    }

    final distanceMeters = Geolocator.distanceBetween(
      GeofenceConfig.campusLatitude,
      GeofenceConfig.campusLongitude,
      position.latitude,
      position.longitude,
    );

    if (distanceMeters > GeofenceConfig.radiusMeters) {
      throw Exception(
        'Anda berada di luar area kampus '
        '(${distanceMeters.toStringAsFixed(1)} m dari titik absensi)',
      );
    }

    return GeofenceCheckResult(
      position: position,
      distanceMeters: distanceMeters,
    );
  }
}
