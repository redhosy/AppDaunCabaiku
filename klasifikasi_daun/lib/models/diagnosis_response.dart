import 'package:flutter/material.dart';

class DiagnosisResponse {
  final int idDiagnosa;
  final int idUser;
  final String tanggal; // Format "YYYY-MM-DD"
  final String jenisPenyakit; // Contoh: "Kuning", "Sehat", "Keriting"
  final String image; // URL lengkap gambar dari backend
  final String rekomendasi;
  final String kategori; // Kategori penyakit (SEHAT, KERITING, KUNING)
  final double akurasi; // Akurasi keseluruhan (top akurasi)
  final DateTime createDate;
  final String? scannedImagePath; // Path gambar lokal yang digunakan untuk prediksi (ditambahkan di client)

  final Map<String, int> accuracies; // Akurasi per kategori (dibuat di fromJson)

  DiagnosisResponse({
    required this.idDiagnosa,
    required this.idUser,
    required this.tanggal,
    required this.jenisPenyakit,
    required this.image,
    required this.rekomendasi,
    required this.kategori,
    required this.akurasi,
    required this.createDate,
    this.scannedImagePath,
    required this.accuracies,
  });

  factory DiagnosisResponse.fromJson(Map<String, dynamic> json) {
    Map<String, int> accuraciesMap = {
      "Sehat": 0,
      "Kuning": 0,
      "Keriting": 0,
    };
    String predictedDisease = json['jenis_penyakit'] as String;
    double primaryAccuracy = (json['akurasi'] as num).toDouble(); // Akurasi dari backend adalah float/num

    accuraciesMap[predictedDisease] = primaryAccuracy.round();

    return DiagnosisResponse(
      idDiagnosa: json['id_diagnosa'] as int,
      idUser: json['id_user'] as int,
      tanggal: json['tanggal'] as String,
      jenisPenyakit: predictedDisease,
      image: json['image'] as String,
      rekomendasi: json['rekomendasi'] as String,
      kategori: json['kategori'] as String,
      akurasi: primaryAccuracy,
      createDate: DateTime.parse(json['create_date'] as String),
      scannedImagePath: json['scanned_image_path'] as String?,
      accuracies: accuraciesMap,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_diagnosa': idDiagnosa,
      'id_user': idUser,
      'tanggal': tanggal,
      'jenis_penyakit': jenisPenyakit,
      'image': image,
      'rekomendasi': rekomendasi,
      'kategori': kategori,
      'akurasi': akurasi,
      'create_date': createDate.toIso8601String(),
      'scanned_image_path': scannedImagePath,
    };
  }
}