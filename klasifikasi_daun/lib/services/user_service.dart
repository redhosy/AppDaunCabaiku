// lib/services/user_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart'; 
import 'package:klasifikasi_daun/utils/auth_token_manager.dart';
import 'package:flutter/foundation.dart'; 
import 'package:http_parser/http_parser.dart'; 

class UserService {
  // FIX UTAMA: Perbaiki _usersApiBaseUrl
  // URL ini harus mengarah ke base path yang tepat, yaitu hingga /api/v1
  // karena '/users' sudah dihapus dari prefix di routers/authentication.py
  final String _usersApiBaseUrl = 'http://192.168.196.187:8000/api/v1'; // Ganti dengan IP server Anda yang benar!
  
  final Duration _timeout = const Duration(seconds: 30);

  String _extractErrorMessage(Map<String, dynamic> body) {
    if (body.containsKey('message')) {
      return body['message'].toString();
    } else if (body.containsKey('detail')) {
      var detail = body['detail'];
      if (detail is String) {
        return detail;
      } else if (detail is List && detail.isNotEmpty) {
        List<String> errors = [];
        for (var error in detail) {
          if (error is Map<String, dynamic>) {
            String field = '';
            if (error.containsKey('loc') && error['loc'] is List && error['loc'].length > 1) {
              field = error['loc'][1].toString();
            }
            String msg = error['msg']?.toString() ?? 'Nilai tidak valid';
            errors.add('$field: $msg');
          }
        }
        return errors.join(', ');
      }
      return detail.toString();
    } else {
      return 'Terjadi kesalahan yang tidak diketahui';
    }
  }

  // Metode untuk mendapatkan detail profil user yang sedang login (GET /users/me)
  Future<Map<String, dynamic>> getMyProfileDetails() async {
    debugPrint('[UserService] Mengambil detail profil user...');
    try {
      // FIX: URL akan menjadi /api/v1/me
      final uri = Uri.parse('$_usersApiBaseUrl/me'); 
      final headers = <String, String>{};
      final token = await AuthTokenManager.getToken();

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
        debugPrint('[UserService] Mengirim token untuk GET /me.');
      } else {
        throw Exception('Token autentikasi tidak ditemukan. Silakan login kembali.');
      }

      final response = await http.get(uri, headers: headers).timeout(_timeout);
      debugPrint('[UserService] GET /me Status: ${response.statusCode}');
      debugPrint('[UserService] GET /me Body: ${response.body}');

      if (response.body.isEmpty) {
        throw Exception('Response server kosong.');
      }

      final Map<String, dynamic> body = json.decode(response.body);

      if (response.statusCode == 200 && (body['code'] == '200' || body['code'] == 200)) {
        return body['result'] as Map<String, dynamic>; 
      } else {
        final message = _extractErrorMessage(body);
        throw Exception('Gagal mengambil detail profil: ${message}');
      }
    } on SocketException {
      throw Exception('Tidak ada koneksi internet atau server tidak dapat dijangkau.');
    } on TimeoutException {
      throw Exception('Waktu tunggu habis saat mengambil profil.');
    } catch (e) {
      debugPrint('[UserService] Error di getMyProfileDetails: $e');
      rethrow;
    }
  }

  // Metode untuk mengupdate nama dan bio user (PUT /users/me)
  Future<Map<String, dynamic>> updateMyProfile({required String nama, String? bio}) async {
    debugPrint('[UserService] Mengupdate profil user (nama: $nama, bio: $bio)...');
    try {
      final uri = Uri.parse('$_usersApiBaseUrl/me'); // Sekarang ini akan menjadi .../api/v1/me
      final headers = <String, String>{'Content-Type': 'application/json'};
      final token = await AuthTokenManager.getToken();

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
        debugPrint('[UserService] Mengirim token untuk PUT /me.');
      } else {
        throw Exception('Token autentikasi tidak ditemukan. Silakan login kembali.');
      }

      final Map<String, dynamic> bodyData = {'nama': nama};
      if (bio != null) {
        bodyData['bio'] = bio;
      }

      final response = await http.put(
        uri,
        headers: headers,
        body: jsonEncode(bodyData),
      ).timeout(_timeout);

      debugPrint('[UserService] PUT /me Status: ${response.statusCode}');
      debugPrint('[UserService] PUT /me Body: ${response.body}');

      if (response.body.isEmpty) {
        throw Exception('Response server kosong.');
      }

      final Map<String, dynamic> body = json.decode(response.body);

      if (response.statusCode == 200 && (body['code'] == '200' || body['code'] == 200)) {
        return body['result'] as Map<String, dynamic>; 
      } else {
        final message = _extractErrorMessage(body);
        throw Exception('Gagal mengupdate profil: ${message}');
      }
    } on SocketException {
      throw Exception('Tidak ada koneksi internet atau server tidak dapat dijangkau.');
    } on TimeoutException {
      throw Exception('Waktu tunggu habis saat mengupdate profil.');
    } catch (e) {
      debugPrint('[UserService] Error di updateMyProfile: $e');
      rethrow;
    }
  }

  // Metode untuk mengunggah foto profil (POST /users/upload_profile_picture)
  Future<String> uploadProfilePicture(XFile imageFile) async {
    debugPrint('[UserService] Mengunggah foto profil...');
    try {
      // FIX: URL akan menjadi .../api/v1/upload_profile_picture
      final uri = Uri.parse('$_usersApiBaseUrl/upload_profile_picture'); 
      var request = http.MultipartRequest(
        'POST',
        uri,
      );
      
      String contentType = 'image/jpeg'; 
      if (imageFile.mimeType != null && imageFile.mimeType!.startsWith('image/')) {
        contentType = imageFile.mimeType!;
      } else {
        final fileExtension = imageFile.path.split('.').last.toLowerCase();
        if (fileExtension == 'png') { contentType = 'image/png'; }
        else if (fileExtension == 'jpg' || fileExtension == 'jpeg') { contentType = 'image/jpeg'; }
      }

      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path, contentType: MediaType.parse(contentType)));

      final token = await AuthTokenManager.getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
        debugPrint('[UserService] Mengirim token untuk POST /upload_profile_picture.');
      } else {
        throw Exception('Token autentikasi tidak ditemukan. Silakan login kembali.');
      }

      var response = await request.send().timeout(_timeout);
      
      final respStr = await response.stream.bytesToString();
      debugPrint('[UserService] POST /upload_profile_picture Status: ${response.statusCode}');
      debugPrint('[UserService] POST /upload_profile_picture Body: $respStr');

      if (respStr.isEmpty) {
        throw Exception('Response server kosong.');
      }

      final Map<String, dynamic> body = json.decode(respStr);

      if (response.statusCode == 200 && (body['code'] == '200' || body['code'] == 200)) {
        return body['result']['profile_picture_url'] as String; 
      } else {
        final message = _extractErrorMessage(body);
        throw Exception('Gagal mengunggah foto profil: ${message}');
      }
    } on SocketException {
      throw Exception('Tidak ada koneksi internet atau server tidak dapat dijangkau.');
    } on TimeoutException {
      throw Exception('Waktu tunggu habis saat mengunggah foto profil.');
    } catch (e) {
      debugPrint('[UserService] Error di uploadProfilePicture: $e');
      rethrow;
    }
  }
}