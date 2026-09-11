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

class GeofenceException implements Exception {
  final String message;

  const GeofenceException(this.message);
}

class GeofenceService {
  Future<GeofenceCheckResult> getVerifiedPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const GeofenceException(
        'Aktifkan lokasi/GPS untuk melakukan absensi.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const GeofenceException(
        'Izin lokasi diperlukan untuk melakukan absensi.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      ),
    );

    if (position.isMocked) {
      throw const GeofenceException(
        'Lokasi tidak dapat diverifikasi. Matikan aplikasi pengubah GPS.',
      );
    }

    if (position.accuracy > GeofenceConfig.maxAccuracyMeters) {
      throw GeofenceException(
        'Akurasi lokasi saat ini '
        '${position.accuracy.toStringAsFixed(0)} meter. '
        'Maksimum ${GeofenceConfig.maxAccuracyMeters.toStringAsFixed(0)} '
        'meter. Aktifkan Lokasi Presisi dan coba lagi.',
      );
    }

    final distanceMeters = Geolocator.distanceBetween(
      GeofenceConfig.campusLatitude,
      GeofenceConfig.campusLongitude,
      position.latitude,
      position.longitude,
    );

    if (distanceMeters > GeofenceConfig.radiusMeters) {
      throw const GeofenceException(
        'Absensi tidak dapat dilakukan karena Anda berada di luar area kampus.',
      );
    }

    return GeofenceCheckResult(
      position: position,
      distanceMeters: distanceMeters,
    );
  }
}
