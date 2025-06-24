// lib/presentation/pages/home/preview/preview_page.dart
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:klasifikasi_daun/presentation/pages/home/history/detail_history_page.dart';
import 'package:klasifikasi_daun/presentation/widgets/custom_Loading_widget.dart';
import 'package:klasifikasi_daun/services/diagnosa_service.dart';
import 'package:klasifikasi_daun/services/histori_service.dart';
import 'package:klasifikasi_daun/models/diagnosis_response.dart';
import 'package:klasifikasi_daun/models/history_item.dart'; // FIX: Import HistoryItem

class PreviewPage extends StatefulWidget {
  final XFile picture;

  const PreviewPage({Key? key, required this.picture}) : super(key: key);

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  final DiagnosaService _diagnosaService = DiagnosaService();
  DiagnosisResponse? _diagnosisResponse;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _performDiagnosis();
  }

  Future<void> _performDiagnosis() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true; // Aktifkan loading
      _errorMessage = null;
    });
    try {
      // Panggil layanan diagnosa (ini juga yang menyimpan ke backend)
      _diagnosisResponse = await _diagnosaService.predictImage(widget.picture);

      // Setelah prediksi berhasil dan data sudah di backend, simpan ke cache lokal
      if (_diagnosisResponse != null) {
        await HistoryService.saveToHistoryLocally(_diagnosisResponse!);
      }

      // Beri jeda sebentar agar pengguna dapat melihat hasil (jika perlu)
      // await Future.delayed(const Duration(seconds: 1)); // Diperpendek jika perlu

      // FIX UTAMA: Alih-alih pop, langsung arahkan ke DetailHistoryPage
      if (mounted && _diagnosisResponse != null) {
        // Konversi DiagnosisResponse menjadi HistoryItem
        final HistoryItem newHistoryItem = HistoryItem.fromDiagnosisResponse(_diagnosisResponse!);
        
        // PushReplacement agar PreviewPage dihilangkan dari stack, dan DetailHistoryPage menjadi penggantinya
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DetailHistoryPage(historyItem: newHistoryItem),
          ),
        );
      }

    } catch (e) {
      debugPrint("Error dalam _performDiagnosis: $e");
      if (mounted) {
        String displayError = e.toString();
        if (displayError.contains(':')) {
          displayError = displayError.split(':')[1].trim();
        }
        setState(() {
          _errorMessage = displayError; // Set pesan error
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $_errorMessage')),
        );
        // Kembali ke halaman sebelumnya (CameraPage) setelah ada error
        Future.delayed(const Duration(seconds: 2), () {
          if(mounted) Navigator.pop(context);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Nonaktifkan loading di akhir
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hasil Diagnosa'),
      ),
      body: Stack( // Menggunakan Stack agar LoadingWidget bisa jadi overlay
        children: [
          // Konten utama PreviewPage
          _diagnosisResponse == null && !_isLoading && _errorMessage == null
              ? const Center(child: Text("Memuat hasil diagnosa..."))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Image.file(
                            File(widget.picture.path),
                            height: 250,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_diagnosisResponse != null)
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Hasil Scan Daun',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Divider(height: 20, thickness: 1),
                                  _buildInfoRow('Jenis Penyakit:', _diagnosisResponse!.jenisPenyakit, isBold: true),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Akurasi Tiap Penyakit:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  _buildAccuracyBar('Sehat', _diagnosisResponse!.accuracies['Sehat'] ?? 0, Colors.green),
                                  _buildAccuracyBar('Kuning', _diagnosisResponse!.accuracies['Kuning'] ?? 0, Colors.orange),
                                  _buildAccuracyBar('Keriting', _diagnosisResponse!.accuracies['Keriting'] ?? 0, Colors.brown),
                                  const SizedBox(height: 15),
                                  const Text(
                                    'Rekomendasi:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    _diagnosisResponse!.rekomendasi,
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                  const SizedBox(height: 15),
                                  _buildInfoRow('Tanggal Scan:', DateFormat('dd MMMyyyy').format(_diagnosisResponse!.createDate)),
                                ],
                              ),
                            ),
                          ),
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              'Gagal mendapatkan hasil diagnosa: $_errorMessage',
                              style: const TextStyle(color: Colors.red, fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
          
          // Tampilkan CustomLoadingWidget sebagai overlay jika _isLoading true
          if (_isLoading)
            const LoadingWidget(
              message: "Menganalisa daun, mohon tunggu...",
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildAccuracyBar(String label, int accuracy, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontSize: 15),
            ),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: accuracy / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$accuracy%',
            style: const TextStyle(fontSize: 15),
          ),
        ],
      ),
    );
  }
}