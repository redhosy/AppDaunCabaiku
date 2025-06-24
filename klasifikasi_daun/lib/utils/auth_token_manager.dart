// lib/utils/auth_token_manager.dart
import 'package:flutter/foundation.dart'; // Import for debugPrint
import 'package:shared_preferences/shared_preferences.dart';

class AuthTokenManager {
  static const String _authTokenKey = 'user_auth_token';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _userIdKey = 'user_id';
  static const String _profilePictureUrlKey = 'profile_picture_url';
  static const String _userBioKey = 'user_bio'; // FIX: Tambah key untuk bio

  // Menyimpan token dan info user lengkap
  static Future<void> saveTokenAndUserInfo(String token, String userName, int userId, String userEmail, String? profilePictureUrl, String? userBio) async { // FIX: Tambah userBio
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authTokenKey, token);
    await prefs.setString(_userNameKey, userName);
    await prefs.setString(_userEmailKey, userEmail); 
    await prefs.setInt(_userIdKey, userId);
    if (profilePictureUrl != null && profilePictureUrl.isNotEmpty) {
      await prefs.setString(_profilePictureUrlKey, profilePictureUrl);
    } else {
      await prefs.remove(_profilePictureUrlKey);
    }
    if (userBio != null && userBio.isNotEmpty) { // FIX: Simpan bio user
      await prefs.setString(_userBioKey, userBio);
    } else {
      await prefs.remove(_userBioKey);
    }
    debugPrint('[AuthTokenManager] Token & info user berhasil disimpan.');
  }

  // --- Metode GET ---
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_authTokenKey);
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }
  
  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }
  
  static Future<String?> getProfilePictureUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_profilePictureUrlKey);
  }

  static Future<String?> getUserBio() async { // FIX: Metode baru untuk mengambil bio user
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userBioKey);
  }

  // --- Metode SAVE Spesifik (untuk EditUser) ---
  static Future<void> saveUserName(String userName) async { 
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, userName);
    debugPrint('[AuthTokenManager] Nama user berhasil diperbarui secara lokal.');
  }

  static Future<void> saveProfilePictureUrl(String url) async { 
    final prefs = await SharedPreferences.getInstance();
    if (url.isNotEmpty) {
      await prefs.setString(_profilePictureUrlKey, url);
    } else {
      await prefs.remove(_profilePictureUrlKey);
    }
    debugPrint('[AuthTokenManager] URL foto profil berhasil diperbarui secara lokal.');
  }

  static Future<void> saveUserBio(String userBio) async { // FIX: Metode baru untuk menyimpan bio
    final prefs = await SharedPreferences.getInstance();
    if (userBio.isNotEmpty) {
      await prefs.setString(_userBioKey, userBio);
    } else {
      await prefs.remove(_userBioKey);
    }
    debugPrint('[AuthTokenManager] Bio user berhasil diperbarui secara lokal.');
  }


  // Menghapus semua info user dari SharedPreferences (saat logout)
  static Future<void> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authTokenKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_profilePictureUrlKey);
    await prefs.remove(_userBioKey); // FIX: Hapus juga key bio
    debugPrint('[AuthTokenManager] Semua info user berhasil dihapus.');
  }
}