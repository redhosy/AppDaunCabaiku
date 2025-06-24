import 'package:flutter/material.dart';

class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tentang Aplikasi'),
        centerTitle: true,
        foregroundColor: Colors.white, // Warna teks di AppBar
        backgroundColor: Color(0xFF38B48B), // Warna hijau khas aplikasi
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF38B48B), Color(0xFF269C7E)],
            ),
          ),
        ),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.asset(
                'assets/Logo2.png', // GANTI DENGAN PATH LOGO APLIKASI ANDA
                height: 120,
                width: 120,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Aplikasi Analisis Daun Cabai',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF3F7D58),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Center(
              child: Text(
                'Versi 1.0.0', // Sesuaikan versi aplikasi Anda
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Deskripsi:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3F7D58),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Aplikasi ini dirancang untuk membantu petani dan penggemar tanaman dalam menganalisis kondisi kesehatan daun cabai. Dengan hanya mengambil atau mengunggah gambar daun, aplikasi akan memberikan diagnosis potensi penyakit dan rekomendasi penanganannya.',
              style: TextStyle(fontSize: 16, height: 1.5),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 20),
            const Text(
              'Teknologi yang Digunakan:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3F7D58),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Aplikasi ini memanfaatkan kekuatan Machine Learning di sisi backend untuk analisis gambar yang akurat:',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 8),
            _buildTechRow('Capture Gambar',
                'Menggunakan kamera perangkat atau galeri untuk mendapatkan citra daun.'),
            _buildTechRow('Preprocessing Gambar',
                'Citra diolah (resize, konversi warna) agar siap dianalisis.'),
            _buildTechRow('Convolutional Neural Network (CNN)',
                'Model Deep Learning untuk mengekstraksi fitur-fitur kompleks dari gambar daun.'),
            _buildTechRow('Support Vector Machine (SVM)',
                'Algoritma Machine Learning yang mengklasifikasikan fitur yang diekstraksi oleh CNN untuk mendiagnosis jenis penyakit.'),
            const SizedBox(height: 20),
            const Text(
              'Pengembang:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3F7D58),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Dibuat oleh Redho Septayudien', // GANTI DENGAN NAMA ANDA/TIM
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                '© 2025 Redho Septayudien (Mahasiswa)', // Sesuaikan tahun dan nama copyright
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget untuk baris teknologi
  Widget _buildTechRow(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline,
              size: 20, color: Color(0xFF38B48B)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
