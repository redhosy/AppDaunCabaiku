// lib/services/history_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/diagnosis_response.dart';
import '../models/history_item.dart';
import '../presentation/widgets/custom_chart.dart'; // Import LeafData (asumsi ini ada)
import 'package:intl/intl.dart';
import '../utils/auth_token_manager.dart';
import 'package:flutter/foundation.dart'; // Untuk debugPrint
import 'package:http_parser/http_parser.dart'; // Untuk MediaType.parse

class HistoryService {
  static const String _historyKey = 'leaf_diagnosis_history';
  static const int _maxHistoryItems = 100;
  
  static const String _diagnosaApiBaseUrl = 'http://192.168.196.187:8000/api/v1/diagnosa'; // Pastikan IP ini benar

  static List<HistoryItem>? _cachedAllHistory; 

  // Simpan hasil diagnosa ke cache lokal (setelah prediksi berhasil di backend)
  static Future<void> saveToHistoryLocally(DiagnosisResponse diagnosis) async {
    try {
      final HistoryItem historyItem = HistoryItem.fromDiagnosisResponse(diagnosis);
      
      final prefs = await SharedPreferences.getInstance();
      
      final existingHistory = await _getHistoryLocally();
      
      final updatedHistory = [historyItem, ...existingHistory];
      
      final limitedHistory = updatedHistory.length > _maxHistoryItems
          ? updatedHistory.sublist(0, _maxHistoryItems)
          : updatedHistory;
      
      final jsonList = limitedHistory.map((item) => item.toJson()).toList();
      await prefs.setString(_historyKey, json.encode(jsonList));
      debugPrint('[HistoryService] Histori berhasil disimpan ke cache lokal!');
      
      _cachedAllHistory = updatedHistory; // Update cache in-memory
      
    } catch (e) {
      debugPrint('[HistoryService] Terjadi kesalahan saat menyimpan histori ke cache lokal: ${e.toString()}');
    }
  }

  // Mengambil histori khusus user dari backend (GET /api/v1/diagnosa/my-history/)
  static Future<List<HistoryItem>> _getHistoryFromBackend({int skip = 0, int limit = 10}) async { 
    debugPrint('[HistoryService] --- START _getHistoryFromBackend ---');
    final startTime = DateTime.now();
    try {
      final uri = Uri.parse('$_diagnosaApiBaseUrl/my-history/?skip=$skip&limit=$limit'); 
      final headers = <String, String>{};
      final token = await AuthTokenManager.getToken(); 
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
        debugPrint('[HistoryService] Mengirim token autentikasi untuk GET histori user (skip=$skip, limit=$limit).');
      } else {
        throw Exception('Token autentikasi tidak ditemukan. Silakan login kembali.');
      }

      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 20)); 
      
      debugPrint('[HistoryService] Backend Response Status: ${response.statusCode}');
      debugPrint('[HistoryService] Backend Response Body Length: ${response.body.length}');

      if (response.statusCode == 200) {
        final jsonDecodeStartTime = DateTime.now();
        final List<dynamic> jsonList = json.decode(response.body);
        debugPrint('[HistoryService] JSON Decode selesai dalam: ${DateTime.now().difference(jsonDecodeStartTime).inMilliseconds} ms');

        final mapToObjectsStartTime = DateTime.now();
        final List<HistoryItem> fetchedHistory = jsonList.map((json) {
          final diagResponse = DiagnosisResponse.fromJson(json);
          return HistoryItem.fromDiagnosisResponse(diagResponse);
        }).toList();
        debugPrint('[HistoryService] Map ke objek selesai dalam: ${DateTime.now().difference(mapToObjectsStartTime).inMilliseconds} ms');

        debugPrint('[HistoryService] --- END _getHistoryFromBackend (SUCCESS) total time: ${DateTime.now().difference(startTime).inMilliseconds} ms ---');
        return fetchedHistory;
      } else {
        final errorBody = response.body;
        debugPrint('[HistoryService] Gagal mengambil histori user dari backend: ${response.statusCode}, Body: $errorBody');
        if (response.statusCode == 401) {
          throw Exception('Autentikasi gagal. Silakan login kembali.');
        }
        throw Exception('Gagal memuat histori user dari server. Status: ${response.statusCode} - $errorBody');
      }
    } on SocketException catch (e) {
      debugPrint('[HistoryService] SocketException di _getHistoryFromBackend: ${e.toString()}');
      debugPrint('[HistoryService] --- END _getHistoryFromBackend (SOCKET_ERROR) total time: ${DateTime.now().difference(startTime).inMilliseconds} ms ---');
      throw Exception('Tidak ada koneksi internet atau server tidak dapat dijangkau.');
    } on TimeoutException catch (e) {
      debugPrint('[HistoryService] TimeoutException di _getHistoryFromBackend: ${e.toString()}');
      debugPrint('[HistoryService] --- END _getHistoryFromBackend (TIMEOUT_ERROR) total time: ${DateTime.now().difference(startTime).inMilliseconds} ms ---');
      throw Exception('Waktu tunggu ke server habis.');
    } catch (e) {
      debugPrint('[HistoryService] Error tak terduga di _getHistoryFromBackend: $e');
      debugPrint('[HistoryService] --- END _getHistoryFromBackend (UNHANDLED_ERROR) total time: ${DateTime.now().difference(startTime).inMilliseconds} ms ---');
      throw Exception('Terjadi kesalahan saat memuat data dari server: ${e.toString()}');
    }
  }

  static Future<List<HistoryItem>> _getHistoryLocally() async {
    debugPrint('[HistoryService] --- START _getHistoryLocally ---');
    final startTime = DateTime.now();
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_historyKey);
      
      if (historyJson == null) {
        debugPrint('[HistoryService] Histori lokal kosong.');
        debugPrint('[HistoryService] --- END _getHistoryLocally (EMPTY) total time: ${DateTime.now().difference(startTime).inMilliseconds} ms ---');
        return [];
      }
      
      final jsonDecodeStartTime = DateTime.now();
      final List<dynamic> jsonList = json.decode(historyJson);
      debugPrint('[HistoryService] JSON Decode lokal selesai dalam: ${DateTime.now().difference(jsonDecodeStartTime).inMilliseconds} ms');

      final mapToObjectsStartTime = DateTime.now();
      final List<HistoryItem> localHistory = jsonList.map((json) => HistoryItem.fromJson(json)).toList();
      debugPrint('[HistoryService] Map ke objek lokal selesai dalam: ${DateTime.now().difference(mapToObjectsStartTime).inMilliseconds} ms');

      _cachedAllHistory = localHistory; // Update cache in-memory dari lokal
      debugPrint('[HistoryService] --- END _getHistoryLocally (SUCCESS) total time: ${DateTime.now().difference(startTime).inMilliseconds} ms ---');
      return localHistory;
      
    } catch (e) {
      debugPrint('[HistoryService] Error memuat histori dari SharedPreferences: ${e.toString()}');
      debugPrint('[HistoryService] --- END _getHistoryLocally (ERROR) total time: ${DateTime.now().difference(startTime).inMilliseconds} ms ---');
      return [];
    }
  }

  static Future<List<HistoryItem>> getHistory({bool forceRefresh = false, int skip = 0, int limit = 10}) async { 
    debugPrint('[HistoryService] --- START getHistory (forceRefresh=$forceRefresh, skip=$skip, limit=$limit) ---');
    if (_cachedAllHistory != null && !forceRefresh && skip == 0 && limit > 0 && _cachedAllHistory!.length >= limit) { 
      debugPrint('[HistoryService] Mengambil histori dari cache in-memory (halaman pertama).');
      return _cachedAllHistory!.sublist(0, limit); 
    }
    
    try {
      List<HistoryItem> backendHistory;
      if (skip >= 0 && limit > 0) { 
        backendHistory = await _getHistoryFromBackend(skip: skip, limit: limit);
      } else {
        backendHistory = await _getHistoryFromBackend(skip: 0, limit: 100); 
      }
      
      if (skip == 0) { 
          _cachedAllHistory = backendHistory; 
          await _saveHistoryListLocally(backendHistory);
      } else { 
          _cachedAllHistory?.addAll(backendHistory);
          await _saveHistoryListLocally(_cachedAllHistory!); 
      }
      debugPrint('[HistoryService] --- END getHistory (SUCCESS) ---');
      return backendHistory;
      
    } catch (e) {
      debugPrint('[HistoryService] Gagal memuat histori dari backend di getHistory, mencoba dari cache lokal sebagai fallback: ${e.toString()}');
      debugPrint('[HistoryService] --- END getHistory (ERROR) ---');
      return await _getHistoryLocally();
    }
  }

  static Future<void> _saveHistoryListLocally(List<HistoryItem> history) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = history.map((item) => item.toJson()).toList();
      await prefs.setString(_historyKey, json.encode(jsonList));
      _cachedAllHistory = history; // Update cache in-memory
      debugPrint('[HistoryService] Cache histori lokal berhasil diperbarui.');
    } catch (e) {
      debugPrint('[HistoryService] Error saving history list locally: ${e.toString()}');
    }
  }

  static Future<List<HistoryItem>> getRecentHistory({int limit = 5, required List<HistoryItem> data}) async { 
    return data.length > limit 
        ? data.sublist(0, limit)
        : data;
  }

  static Future<Map<String, int>> getHistoryStatsV2({required List<HistoryItem> data}) async { 
    final stats = <String, int>{
      'total': data.length, 
      'sehat': 0,
      'kuning': 0,
      'keriting': 0,
    };
    for (final item in data) {
      switch (item.predictedDisease.toLowerCase()) {
        case 'sehat':
          stats['sehat'] = stats['sehat']! + 1;
          break;
        case 'kuning':
          stats['kuning'] = stats['kuning']! + 1;
          break;
        case 'keriting':
          stats['keriting'] = stats['keriting']! + 1;
          break;
      }
    }
    return stats;
  }

  static Future<int> getTodaysScanCountV2({required List<HistoryItem> data}) async { 
    final today = DateTime.now();
    return data.where((item) {
      return item.scanDate.year == today.year &&
             item.scanDate.month == today.month &&
             item.scanDate.day == today.day;
    }).length;
  }

  static Future<List<LeafData>> getWeeklyLeafData({required List<HistoryItem> data}) async { 
    final now = DateTime.now();
    
    Map<String, Map<String, int>> dailyCounts = {};
    final List<String> weekDayNames = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']; 

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);
      dailyCounts[formattedDate] = {'sehat': 0, 'kuning': 0, 'keriting': 0};
    }

    for (var item in data) { 
      final formattedDate = DateFormat('yyyy-MM-dd').format(item.scanDate);
      if (dailyCounts.containsKey(formattedDate)) {
        switch (item.predictedDisease.toLowerCase()) {
          case 'sehat':
            dailyCounts[formattedDate]!['sehat'] = dailyCounts[formattedDate]!['sehat']! + 1;
            break;
          case 'kuning':
            dailyCounts[formattedDate]!['kuning'] = dailyCounts[formattedDate]!['kuning']! + 1;
            break;
          case 'keriting':
            dailyCounts[formattedDate]!['keriting'] = dailyCounts[formattedDate]!['keriting']! + 1;
            break;
        }
      }
    }

    final List<LeafData> weeklyData = [];
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);
      
      final dayNameIndex = date.weekday % 7; 
      final dayName = weekDayNames[dayNameIndex];

      final counts = dailyCounts[formattedDate]!;
      weeklyData.add(LeafData(
        day: dayName,
        sehat: counts['sehat']!.toDouble(),
        kuning: counts['kuning']!.toDouble(),
        keriting: counts['keriting']!.toDouble(),
      ));
    }
    return weeklyData;
  }

  // Mengambil satu item histori berdasarkan ID lokal (GET /api/v1/diagnosa/{id_diagnosa})
  static Future<HistoryItem?> getHistoryItemById(String id) async {
    // Coba dari cache in-memory terlebih dahulu
    if (_cachedAllHistory != null) {
      final cachedItem = _cachedAllHistory!.cast<HistoryItem?>().firstWhere(
        (item) => item?.id == id,
        orElse: () => null,
      );
      if (cachedItem != null) {
        debugPrint('[HistoryService] Mengambil detail histori dari cache in-memory.');
        return cachedItem;
      }
    }

    // Fallback ke cache lokal
    final allHistory = await _getHistoryLocally(); 
    final localItem = allHistory.cast<HistoryItem?>().firstWhere(
      (item) => item?.id == id,
      orElse: () => null,
    );

    if (localItem != null && localItem.backendId != -1) {
      try {
        final uri = Uri.parse('$_diagnosaApiBaseUrl/${localItem.backendId}'); 
        final headers = <String, String>{};
        final token = await AuthTokenManager.getToken();
        if (token != null) {
          headers['Authorization'] = 'Bearer $token';
          debugPrint('[HistoryService] Mengirim token untuk GET detail histori.');
        } else {
          throw Exception('Token autentikasi tidak ditemukan. Silakan login kembali.');
        }

        final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 20));
        if (response.statusCode == 200) {
          final diagResponse = DiagnosisResponse.fromJson(json.decode(response.body));
          final updatedLocalHistory = allHistory.map((item) {
            if (item.id == localItem.id) {
              return HistoryItem.fromDiagnosisResponse(diagResponse);
            }
            return item;
          }).toList();
          await _saveHistoryListLocally(updatedLocalHistory); // Simpan kembali ke lokal
          return HistoryItem.fromDiagnosisResponse(diagResponse);
        } else {
          debugPrint('[HistoryService] Gagal mengambil detail histori dari backend: ${response.statusCode} - ${response.body}');
          if (response.statusCode == 401) {
            throw Exception('Autentikasi gagal. Silakan login kembali.');
          }
          return localItem;
        }
      } on SocketException {
        debugPrint('[HistoryService] Tidak ada koneksi internet saat mencoba memuat detail histori dari backend.');
        return localItem;
      } catch (e) {
        debugPrint('[HistoryService] Error saat mengambil detail histori dari backend: $e');
        return localItem;
      }
    }
    return localItem;
  }

  static Future<void> deleteHistoryItem(String id) async {
    try {
      final allHistory = await _getHistoryLocally(); // Dapatkan dari lokal untuk menemukan backendId
      final itemToDelete = allHistory.cast<HistoryItem?>().firstWhere(
        (item) => item?.id == id,
        orElse: () => null,
      );

      if (itemToDelete != null && itemToDelete.backendId != -1) {
        try {
          final uri = Uri.parse('$_diagnosaApiBaseUrl/${itemToDelete.backendId}');
          final headers = <String, String>{};
          final token = await AuthTokenManager.getToken();
          if (token != null) {
            headers['Authorization'] = 'Bearer $token';
          }
          await http.delete(uri, headers: headers);
          debugPrint('[HistoryService] Item backend ${itemToDelete.backendId} berhasil dihapus.');
          _cachedAllHistory?.removeWhere((item) => item.id == id); // Hapus dari cache in-memory
        } catch (e) {
          debugPrint('[HistoryService] Gagal menghapus item backend ${itemToDelete.backendId}: $e');
        }
      } else if (itemToDelete == null) {
        debugPrint('[HistoryService] Item histori tidak ditemukan di lokal atau tidak memiliki backendId.');
      }

      final updatedHistory = allHistory.where((item) => item.id != id).toList();
      final prefs = await SharedPreferences.getInstance();
      final jsonList = updatedHistory.map((item) => item.toJson()).toList();
      await prefs.setString(_historyKey, json.encode(jsonList));
      debugPrint('[HistoryService] Histori berhasil dihapus dari lokal!');
      
    } catch (e) {
      debugPrint('[HistoryService] Terjadi kesalahan saat menghapus item histori: $e');
      rethrow;
    }
  }

  static Future<void> clearHistory() async {
    try {
      final allHistory = await _getHistoryLocally();
      
      for (var item in allHistory) {
        if (item.backendId != -1) {
          try {
            final uri = Uri.parse('$_diagnosaApiBaseUrl/${item.backendId}');
            final headers = <String, String>{};
            final token = await AuthTokenManager.getToken();
            if (token != null) {
              headers['Authorization'] = 'Bearer $token';
            }
            await http.delete(uri, headers: headers);
            debugPrint('[HistoryService] Item backend ${item.backendId} berhasil dihapus.');
          } catch (e) {
            debugPrint('[HistoryService] Gagal menghapus item backend ${item.backendId}: $e');
          }
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
      _cachedAllHistory = []; // Hapus cache in-memory
      debugPrint('[HistoryService] Semua histori berhasil dihapus dari lokal!');
    } catch (e) {
      debugPrint('[HistoryService] Terjadi kesalahan saat menghapus semua histori: $e');
      rethrow;
    }
  }

  static Future<Map<String, int>> getHistoryStats({required List<HistoryItem> data}) async { 
    final stats = <String, int>{
      'total': data.length, 
      'sehat': 0,
      'kuning': 0,
      'keriting': 0,
    };
    for (final item in data) {
      switch (item.predictedDisease.toLowerCase()) {
        case 'sehat':
          stats['sehat'] = stats['sehat']! + 1;
          break;
        case 'kuning':
          stats['kuning'] = stats['kuning']! + 1;
          break;
        case 'keriting':
          stats['keriting'] = stats['keriting']! + 1;
          break;
      }
    }
    return stats;
  }

  static Future<int> getTodaysScanCount({required List<HistoryItem> data}) async { 
    final today = DateTime.now();
    return data.where((item) {
      return item.scanDate.year == today.year &&
             item.scanDate.month == today.month &&
             item.scanDate.day == today.day;
    }).length;
  }

  static Future<List<LeafData>> getWeeklyData({required List<HistoryItem> data}) async { 
    final now = DateTime.now();
    
    Map<String, Map<String, int>> dailyCounts = {};
    final List<String> weekDayNames = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']; 

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);
      dailyCounts[formattedDate] = {'sehat': 0, 'kuning': 0, 'keriting': 0};
    }

    for (var item in data) { 
      final formattedDate = DateFormat('yyyy-MM-dd').format(item.scanDate);
      if (dailyCounts.containsKey(formattedDate)) {
        switch (item.predictedDisease.toLowerCase()) {
          case 'sehat':
            dailyCounts[formattedDate]!['sehat'] = dailyCounts[formattedDate]!['sehat']! + 1;
            break;
          case 'kuning':
            dailyCounts[formattedDate]!['kuning'] = dailyCounts[formattedDate]!['kuning']! + 1;
            break;
          case 'keriting':
            dailyCounts[formattedDate]!['keriting'] = dailyCounts[formattedDate]!['keriting']! + 1;
            break;
        }
      }
    }

    final List<LeafData> weeklyData = [];
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);
      
      final dayNameIndex = date.weekday % 7; 
      final dayName = weekDayNames[dayNameIndex];

      final counts = dailyCounts[formattedDate]!;
      weeklyData.add(LeafData(
        day: dayName,
        sehat: counts['sehat']!.toDouble(),
        kuning: counts['kuning']!.toDouble(),
        keriting: counts['keriting']!.toDouble(),
      ));
    }
    return weeklyData;
  }
}