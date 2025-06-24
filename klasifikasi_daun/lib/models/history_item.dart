import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'diagnosis_response.dart';

final uuid = Uuid();

class HistoryItem {
  final String id; // Unique ID (lokal) - UUID
  final int backendId; // id_diagnosa dari backend
  final String predictedDisease; // jenis_penyakit dari backend
  final Map<String, int> confidence; // Akurasi per kategori (int 0-100)
  final String recommendation;
  final DateTime scanDate;
  final String imagePath; // Local path of the scanned image
  final String backendImageUrl; // Image URL lengkap dari backend

  HistoryItem({
    String? id,
    required this.backendId,
    required this.predictedDisease,
    required this.confidence,
    required this.recommendation,
    required this.scanDate,
    required this.imagePath,
    required this.backendImageUrl,
  }) : id = id ?? uuid.v4();

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'] as String,
      backendId: json['backend_id'] as int,
      predictedDisease: json['predicted_disease'] as String,
      confidence: Map<String, int>.from(json['confidence'] as Map),
      recommendation: json['rekomendasi'] as String,
      scanDate: DateTime.parse(json['scan_date'] as String),
      imagePath: json['image_path'] as String,
      backendImageUrl: json['backend_image_url'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'backend_id': backendId,
      'predicted_disease': predictedDisease,
      'confidence': confidence,
      'rekomendasi': recommendation,
      'scan_date': scanDate.toIso8601String(),
      'image_path': imagePath,
      'backend_image_url': backendImageUrl,
    };
  }

  // Convert DiagnosisResponse (dari /diagnosa/predict) ke HistoryItem
  factory HistoryItem.fromDiagnosisResponse(DiagnosisResponse diagnosisResponse) {
    return HistoryItem(
      backendId: diagnosisResponse.idDiagnosa,
      predictedDisease: diagnosisResponse.jenisPenyakit,
      confidence: diagnosisResponse.accuracies,
      recommendation: diagnosisResponse.rekomendasi,
      scanDate: diagnosisResponse.createDate,
      imagePath: diagnosisResponse.scannedImagePath ?? '',
      backendImageUrl: diagnosisResponse.image,
    );
  }

  Color get statusColor {
    switch (predictedDisease.toLowerCase()) {
      case 'sehat':
        return const Color(0xFF10B981);
      case 'kuning':
        return const Color(0xFFF59E0B);
      case 'keriting':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  IconData get statusIcon {
    switch (predictedDisease.toLowerCase()) {
      case 'sehat':
        return Icons.check_circle_outline;
      case 'kuning':
        return Icons.warning_amber_outlined;
      case 'keriting':
        return Icons.bug_report_outlined;
      default:
        return Icons.info_outline;
    }
  }

  int get topAccuracy {
    if (confidence.isEmpty) return 0;
    return confidence.values.reduce((a, b) => a > b ? a : b);
  }
}