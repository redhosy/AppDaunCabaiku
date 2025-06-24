import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:klasifikasi_daun/models/history_item.dart';

class DetailHistoryPage extends StatelessWidget {
  final HistoryItem historyItem;

  const DetailHistoryPage({Key? key, required this.historyItem}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Diagnosa'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (historyItem.imagePath.isNotEmpty && File(historyItem.imagePath).existsSync())
                Center(
                  child: Image.file(
                    File(historyItem.imagePath),
                    height: 250,
                    fit: BoxFit.cover,
                  ),
                )
              else if (historyItem.backendImageUrl.isNotEmpty)
                Center(
                  child: Image.network(
                    historyItem.backendImageUrl, // Gunakan URL gambar lengkap
                    height: 250,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 250,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Text(
                            'Gagal memuat gambar dari server.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                Container(
                  height: 250,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                  ),
                ),
              const SizedBox(height: 20),

              // Detail Hasil Diagnosa
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
                        'Informasi Diagnosa',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(height: 20, thickness: 1),
                      _buildInfoRow('Kondisi Daun:', historyItem.predictedDisease, isBold: true),
                      const SizedBox(height: 10),

                      const Text(
                        'Akurasi Tiap Penyakit:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      // Tampilkan akurasi dari map confidence
                      _buildAccuracyBar('Sehat', historyItem.confidence['Sehat'] ?? 0, Colors.green),
                      _buildAccuracyBar('Kuning', historyItem.confidence['Kuning'] ?? 0, Colors.orange),
                      _buildAccuracyBar('Keriting', historyItem.confidence['Keriting'] ?? 0, Colors.brown),
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
                        historyItem.recommendation,
                        style: const TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 15),
                      _buildInfoRow('Tanggal Scan:', DateFormat('dd MMM yyyy').format(historyItem.scanDate)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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