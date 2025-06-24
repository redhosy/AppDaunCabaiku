// lib/services/diagnosa_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:camera/camera.dart';
import '../models/diagnosis_response.dart';
import '../utils/auth_token_manager.dart';


class DiagnosaService {
  // PENTING: GANTI IP ADDRESS INI DENGAN IP SERVER FASTAPI ANDA YANG AKTIF!
  final String _diagnosaBaseUrl = 'http://192.168.196.187:8000/api/v1/diagnosa'; 

  Future<DiagnosisResponse> predictImage(XFile image) async {
    try {
      // FIX UTAMA: Tentukan Content-Type secara eksplisit
      String contentType = 'image/jpeg'; // Default jika tidak bisa dideteksi
      // Coba deteksi Content-Type dari mimeType XFile
      if (image.mimeType != null && image.mimeType!.startsWith('image/')) {
        contentType = image.mimeType!;
      } else {
        // Fallback jika mimeType tidak tersedia atau tidak valid
        // Coba deteksi dari ekstensi file
        final fileExtension = image.path.split('.').last.toLowerCase();
        if (fileExtension == 'png') {
          contentType = 'image/png';
        } else if (fileExtension == 'jpg' || fileExtension == 'jpeg') {
          contentType = 'image/jpeg';
        }
        // Jika tidak dikenali, tetap gunakan default atau lempar error jika ingin
      }

      debugPrint('[DiagnosaService] Content-Type file yang akan dikirim: $contentType'); // Log Content-Type yang sudah ditentukan

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_diagnosaBaseUrl/predict'),
      );
      // FIX: Tambahkan parameter contentType ke MultipartFile.fromPath
      request.files.add(await http.MultipartFile.fromPath('file', image.path, contentType: MediaType.parse(contentType))); 

      final String? userToken = await AuthTokenManager.getToken();
      if (userToken != null) {
        request.headers['Authorization'] = 'Bearer $userToken';
        debugPrint('[DiagnosaService] Mengirim token autentikasi untuk prediksi.');
      } else {
        debugPrint('[DiagnosaService] Peringatan: Token autentikasi tidak ditemukan. Prediksi mungkin gagal jika endpoint dilindungi.');
        throw Exception('Anda tidak terautentikasi. Silakan login kembali.');
      }

      var response = await request.send();
      if (response.statusCode == 200 || response.statusCode == 201) {
        final respStr = await response.stream.bytesToString();
        final Map<String, dynamic> data = json.decode(respStr);
        
        data['scanned_image_path'] = image.path; 
        
        return DiagnosisResponse.fromJson(data);
      } else {
        final errorBody = await response.stream.bytesToString();
        debugPrint('[DiagnosaService] Error during prediction: ${response.statusCode}, Body: $errorBody');
        if (response.statusCode == 401) {
          throw Exception('Autentikasi gagal. Silakan login kembali.');
        }
        throw Exception('Gagal memuat data prediksi. Status: ${response.statusCode} - ${errorBody}');
      }
    } on SocketException {
      throw Exception('Tidak ada koneksi internet atau server tidak dapat dijangkau.');
    } catch (e) {
      debugPrint('[DiagnosaService] Exception in predictImage: $e');
      throw Exception('Terjadi kesalahan saat mendapatkan prediksi: ${e.toString()}');
    }
  }
}