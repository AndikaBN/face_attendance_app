import 'package:flutter_test/flutter_test.dart';
import 'package:face_attendance_app/main.dart';

void main() {
  testWidgets('App renders without error', (WidgetTester tester) async {
    await tester.pumpWidget(const FaceAttendanceApp());
    // Verifikasi app berhasil render
    expect(find.text('Absensi Wajah'), findsNothing); // Will show after camera init
  });
}
