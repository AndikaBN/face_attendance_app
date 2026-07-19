/// Model untuk response dari endpoint POST /predict pada Flask API.
class PredictResponseModel {
  final bool success;
  final bool recognized;
  final String? studentName;
  final String? nim;
  final double? similarity;
  final double? confidence;
  final String message;

  PredictResponseModel({
    required this.success,
    required this.recognized,
    this.studentName,
    this.nim,
    this.similarity,
    this.confidence,
    required this.message,
  });

  /// Parse dari JSON response Flask API.
  /// Defensif: nim bisa datang sebagai int atau String dari Flask.
  factory PredictResponseModel.fromJson(Map<String, dynamic> json) {
    return PredictResponseModel(
      success: json['success'] as bool? ?? false,
      recognized: json['recognized'] as bool? ?? false,
      studentName: json['student_name']?.toString(),
      nim: json['nim']?.toString(),
      similarity: (json['similarity'] as num?)?.toDouble(),
      confidence: (json['confidence'] as num?)?.toDouble(),
      message: json['message']?.toString() ?? 'Tidak ada pesan',
    );
  }

  /// Confidence sebagai persentase (0-100).
  String get confidencePercent {
    if (confidence == null) return '-';
    return '${(confidence! * 100).toStringAsFixed(1)}%';
  }

  /// Similarity sebagai persentase (0-100).
  String get similarityPercent {
    if (similarity == null) return '-';
    return '${(similarity! * 100).toStringAsFixed(1)}%';
  }

  @override
  String toString() {
    return 'PredictResponseModel('
        'success: $success, '
        'recognized: $recognized, '
        'studentName: $studentName, '
        'nim: $nim, '
        'similarity: $similarity, '
        'confidence: $confidence, '
        'message: $message)';
  }
}
