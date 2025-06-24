// lib/services/auth_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:klasifikasi_daun/utils/auth_token_manager.dart';

class AuthException implements Exception {
  final String message;
  final int? statusCode;

  AuthException(this.message, {this.statusCode});

  @override
  String toString() =>
      'AuthException: $message${statusCode != null ? ' (Status code: $statusCode)' : ''}';
}

class AuthResponse {
  final int? code;
  final String? status;
  final String message;
  final AuthTokenResult? result;

  AuthResponse({
    this.code,
    this.status,
    required this.message,
    this.result,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      code: json.containsKey('code') 
            ? (json['code'] is String 
               ? int.tryParse(json['code'] as String) 
               : json['code'] as int?) 
            : null,
      status: json.containsKey('status') ? json['status'] as String : null,
      message: json['message']?.toString() ?? 'Operasi berhasil',
      result: json.containsKey('result') && json['result'] != null
          ? AuthTokenResult.fromJson(json['result'] as Map<String, dynamic>)
          : (json.containsKey('access_token') 
              ? AuthTokenResult.fromJson({
                  'access_token': json['access_token'],
                  'token_type': json['token_type'] ?? 'bearer',
                })
              : null),
    );
  }
}

class AuthTokenResult {
  final String accessToken;
  final String tokenType;
  final int idUser; 
  final String nama;
  final String email; 
  final String? profilePictureUrl; 

  AuthTokenResult({
    required this.accessToken,
    required this.tokenType,
    required this.idUser, 
    required this.nama, 
    required this.email,
    this.profilePictureUrl,
  });

  factory AuthTokenResult.fromJson(Map<String, dynamic> json) {
    return AuthTokenResult(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String? ?? 'bearer',
      idUser: json['user_id'] as int, // Sesuaikan dengan key 'user_id' di backend login
      nama: json['nama'] as String, // Sesuaikan dengan key 'nama' di backend login
      email: json['email'] as String, // Sesuaikan dengan key 'email' di backend login
      profilePictureUrl: json.containsKey('profile_picture_url') 
          ? json['profile_picture_url'] as String? 
          : null, 
    );
  }
}

class AuthService {
  final String baseUrl = "http://192.168.196.187:8000/api/v1"; 
  final Duration _timeout = const Duration(seconds: 30);

  String extractErrorMessage(Map<String, dynamic> body) {
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
    } else if (body.containsKey('error_description')) {
      return body['error_description'].toString();
    } else {
      return 'Terjadi kesalahan yang tidak diketahui';
    }
  }

  /// Metode untuk Login User
  Future<AuthResponse> login(String email, String password) async { 
    try {
      debugPrint('[AuthService] Memulai proses login...');
      debugPrint('[AuthService] Email: $email, URL: $baseUrl/login');

      final response = await http
          .post(
            Uri.parse("$baseUrl/login"),
            headers: {'Content-Type': 'application/json'}, 
            body: jsonEncode({ 
              'email': email,
              'password': password,
            }),
          )
          .timeout(_timeout);

      debugPrint('[AuthService] Login status: ${response.statusCode}');
      debugPrint('[AuthService] Login body: ${response.body}');

      if (response.body.isEmpty) {
        throw AuthException('Response server kosong', statusCode: response.statusCode);
      }

      final Map<String, dynamic> body;
      try {
        body = jsonDecode(response.body) as Map<String, dynamic>;
      } on FormatException {
        throw AuthException('Format response dari server tidak valid', statusCode: response.statusCode);
      }

      bool isSuccessJson = (response.statusCode >= 200 && response.statusCode < 300) &&
                           (body.containsKey('code') && (body['code'] == 200 || body['code'] == '200') && body.containsKey('status') && body['status'] == 'ok');

      if (isSuccessJson) {
        // Ambil token, user_id, nama, dan email dari body['result']
        final String? token = body['result']?['access_token']?.toString();
        final int? userId = body['result']?['user_id'] as int?; 
        final String? nama = body['result']?['nama']?.toString(); 
        final String? userEmail = body['result']?['email']?.toString();
        final String? profilePictureUrl = body['result']?['profile_picture_url']?.toString();
        
        debugPrint('--- Debug Token Extraction ---');
        debugPrint('Token from body[\'result\'][\'access_token\']: ${token?.runtimeType} | $token');
        debugPrint('UserId from body[\'result\'][\'user_id\']: $userId?.runtimeType | $userId');
        debugPrint('UserName from body[\'result\'][\'nama\']: ${nama?.runtimeType} | $nama');
        debugPrint('UserEmail from body[\'result\'][\'email\']: ${userEmail?.runtimeType} | $userEmail');
        debugPrint('ProfilePictureUrl from body[\'result\'][\'profile_picture_url\']: ${profilePictureUrl?.runtimeType} | $profilePictureUrl');

        if (token != null && token.isNotEmpty && userId != null && nama != null && userEmail != null) {
          // FIX: Panggil saveTokenAndUserInfo
          await AuthTokenManager.saveTokenAndUserInfo(token, nama, userId, userEmail, profilePictureUrl, null); 
          debugPrint('[AuthService] Login berhasil dan token disimpan.');
          return AuthResponse( 
            code: int.tryParse(body['code'].toString()) ?? 200, 
            status: body['status']?.toString() ?? 'ok',
            message: body['message']?.toString() ?? 'Login berhasil!',
            result: AuthTokenResult(
              accessToken: token,
              tokenType: body['token_type']?.toString() ?? 'bearer',
              idUser: userId,
              nama: nama,
              email: userEmail,
              profilePictureUrl: profilePictureUrl, 
            ),
          );
        } else {
          debugPrint('[AuthService] Token atau informasi user tidak lengkap di response.');
          throw AuthException('Token atau informasi user tidak lengkap setelah login.', statusCode: response.statusCode);
        }
      } else {
        final message = extractErrorMessage(body);
        throw AuthException(message, statusCode: response.statusCode);
      }
    } on SocketException {
      throw AuthException('Tidak dapat terhubung ke server. Periksa koneksi internet Anda.');
    } on TimeoutException {
      throw AuthException('Waktu tunggu habis. Coba lagi nanti.');
    } on FormatException { 
      throw AuthException('Format response dari server tidak valid', statusCode: 0); 
    } catch (e) {
      debugPrint('[AuthService] Login error: $e');
      if (e is AuthException) {
        throw e;
      }
      throw AuthException('Terjadi kesalahan tidak terduga saat login: ${e.toString()}');
    }
  }

  /// Metode untuk Registrasi User
  Future<String> register(String nama, String email, String password) async {
    try {
      debugPrint('[AuthService] Memulai proses registrasi...');
      debugPrint('Nama: $nama, Email: $email');
      debugPrint('URL: $baseUrl/register');

      final response = await http
          .post(
            Uri.parse('$baseUrl/register'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'nama': nama,
              'email': email,
              'password': password,
            }),
          )
          .timeout(_timeout);

      debugPrint('[AuthService] Response status: ${response.statusCode}');
      debugPrint('[AuthService] Response body: ${response.body}');

      if (response.body.isEmpty) {
        throw AuthException('Response server kosong', statusCode: response.statusCode);
      }

      final Map<String, dynamic> body;
      try {
        body = jsonDecode(response.body) as Map<String, dynamic>;
      } on FormatException {
        throw AuthException('Format response dari server tidak valid', statusCode: response.statusCode);
      }

      bool isSuccessJson = body.containsKey('code') && (body['code'] == 200 || body['code'] == '200') &&
                        body.containsKey('status') && body['status'] == 'ok';

      if (response.statusCode >= 200 && response.statusCode < 300 && isSuccessJson) {
        return body['message']?.toString() ?? 'Registrasi berhasil!';
      } else {
        final message = extractErrorMessage(body);
        throw AuthException(message, statusCode: response.statusCode);
      }
    } on SocketException {
      throw AuthException('Tidak dapat terhubung ke server. Periksa koneksi internet Anda.');
    } on TimeoutException {
      throw AuthException('Server tidak merespons. Coba lagi nanti.');
    } on FormatException { 
      throw AuthException('Format response dari server tidak valid', statusCode: 0); 
    } catch (e) {
      debugPrint('[AuthService] Error tidak terduga: $e');
      if (e is AuthException) {
        throw e;
      }
      throw AuthException('Terjadi kesalahan tidak terduga saat registrasi: ${e.toString()}');
    }
  }

  /// Forgot Password (Mengirim email reset password)
  Future<void> forgotPassword(String email) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/forgot-password'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'email': email}),
          )
          .timeout(_timeout);

      debugPrint('Forgot Password Status: ${response.statusCode}');
      debugPrint('Forgot Password Body: ${response.body}');

      if (response.body.isEmpty) {
        throw AuthException('Response server kosong', statusCode: response.statusCode);
      }

      final Map<String, dynamic> body;
      try {
        body = jsonDecode(response.body) as Map<String, dynamic>;
      } on FormatException {
        throw AuthException('Format response tidak valid.', statusCode: response.statusCode);
      }

      bool isSuccess = body.containsKey('code') && (body['code'] == 200 || body['code'] == '200') &&
                       body.containsKey('status') && body['status'] == 'ok';

      if (isSuccess) {
        if (body['message'] != null) {
          debugPrint('Email reset password berhasil dikirim.');
          return;
        }
      } else {
        final message = extractErrorMessage(body);
        throw AuthException(message, statusCode: response.statusCode);
      }
    } on SocketException {
      throw AuthException('Tidak dapat terhubung ke server.');
    } on TimeoutException {
      throw AuthException('Waktu tunggu habis.');
    } on FormatException { 
      throw AuthException('Format response tidak valid.', statusCode: 0); 
    } catch (e) {
      debugPrint('Error lupa password: $e');
      if (e is AuthException) {
        throw e;
      }
      throw AuthException('Terjadi kesalahan: ${e.toString()}');
    }
  }

  /// Logout (hapus token dari AuthTokenManager dan navigasi)
  static Future<void> logout(BuildContext context) async {
    await AuthTokenManager.deleteToken();
    print('[AuthService] Logout berhasil.');

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/onboarding',
      (route) => false,
    );
  }

  /// Cek apakah user sudah login (ada token)
  Future<bool> isLoggedIn() async {
    final token = await AuthTokenManager.getToken();
    return token != null && token.isNotEmpty;
  }
}