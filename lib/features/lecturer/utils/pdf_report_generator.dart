import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:face_attendance_app/features/attendance/data/models/attendance_log_model.dart';
import 'package:face_attendance_app/features/auth/data/models/user_model.dart';

/// Class utility untuk menghasilkan & mencetak Laporan PDF Absensi Dosen.
class PdfReportGenerator {
  PdfReportGenerator._();

  /// Generasi dokumen PDF byte data.
  static Future<Uint8List> generateReportPdf({
    required UserModel lecturer,
    required DateTime date,
    required List<AttendanceLogModel> logs,
    required int totalStudents,
    required int presentCount,
    required int izinCount,
    required int alpaCount,
  }) async {
    final pdf = pw.Document();
    final dateFormatted = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date);
    final printTime = DateFormat('dd/MM/yyyy HH:mm', 'id_ID').format(DateTime.now());

    final attendancePercentage = totalStudents > 0
        ? (((presentCount + izinCount) / totalStudents) * 100).toStringAsFixed(1)
        : '0.0';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return [
            // Header Laporan
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'LAPORAN KEHADIRAN MAHASISWA',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Sistem Absensi Wajah Mahasiswa (Face Attendance)',
                      style: const pw.TextStyle(
                        fontSize: 11,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      dateFormatted,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Dosen: ${lecturer.name}',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Divider(thickness: 1.5, color: PdfColors.blue900),
            pw.SizedBox(height: 14),

            // Ringkasan Statistik Box
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildStatBox('Total Mahasiswa', '$totalStudents', PdfColors.blue800),
                  _buildStatBox('Hadir (Masuk)', '$presentCount', PdfColors.green700),
                  _buildStatBox('Izin', '$izinCount', PdfColors.orange700),
                  _buildStatBox('Alpa', '$alpaCount', PdfColors.red700),
                  _buildStatBox('Persentase', '$attendancePercentage%', PdfColors.blue900),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Judul Tabel
            pw.Text(
              'Daftar Kehadiran Mahasiswa',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey900,
              ),
            ),
            pw.SizedBox(height: 8),

            // Tabel Absensi
            pw.TableHelper.fromTextArray(
              headers: ['No', 'NIM', 'Nama Mahasiswa', 'Status', 'Waktu / Keterangan'],
              data: List<List<String>>.generate(logs.length, (index) {
                final log = logs[index];
                final statusStr = log.isMasuk
                    ? 'MASUK'
                    : log.isIzin
                        ? 'IZIN'
                        : 'ALPA';
                final note = log.isIzin
                    ? 'Alasan: ${log.alasanIzin ?? "-"}'
                    : 'Pukul ${log.timeFormatted} (${log.similarityPercent} sim)';

                return [
                  '${index + 1}',
                  log.nim.isNotEmpty ? log.nim : '-',
                  log.studentName,
                  statusStr,
                  note,
                ];
              }),
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              columnWidths: {
                0: const pw.FixedColumnWidth(28),
                1: const pw.FixedColumnWidth(70),
                2: const pw.FlexColumnWidth(3),
                3: const pw.FixedColumnWidth(60),
                4: const pw.FlexColumnWidth(3),
              },
            ),
            pw.SizedBox(height: 30),

            // Footer Tanda Tangan Dosen
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Dicetak otomatis pada: $printTime WIB',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('Dosen Pengampu,', style: const pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 40),
                    pw.Text(
                      '( ${lecturer.name} )',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildStatBox(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
        ),
      ],
    );
  }

  /// Cetak / Simpan PDF langsung via dialog native.
  static Future<void> printOrSavePdf({
    required UserModel lecturer,
    required DateTime date,
    required List<AttendanceLogModel> logs,
    required int totalStudents,
    required int presentCount,
    required int izinCount,
    required int alpaCount,
  }) async {
    final pdfBytes = await generateReportPdf(
      lecturer: lecturer,
      date: date,
      logs: logs,
      totalStudents: totalStudents,
      presentCount: presentCount,
      izinCount: izinCount,
      alpaCount: alpaCount,
    );

    final dateFormatted = DateFormat('yyyy-MM-dd').format(date);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Laporan_Absensi_$dateFormatted.pdf',
    );
  }
}
