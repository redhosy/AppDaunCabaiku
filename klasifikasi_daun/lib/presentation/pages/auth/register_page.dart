import 'package:flutter/material.dart';
import 'package:klasifikasi_daun/presentation/widgets/custome_password_field.dart';
import 'package:klasifikasi_daun/services/auth_service.dart';
import 'package:klasifikasi_daun/presentation/widgets/custom_button.dart';
import 'package:klasifikasi_daun/presentation/widgets/custom_email_field.dart';
import 'package:klasifikasi_daun/presentation/widgets/custom_nama_field.dart'; // Asumsi ini adalah CustomTextField untuk nama/username
import 'dart:io'; // Untuk InternetAddress.lookup dan SocketException
import 'package:connectivity_plus/connectivity_plus.dart'; // Untuk cek koneksi internet
import 'package:flutter/services.dart'; // Untuk PlatformException dari connectivity_plus

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _namaController = TextEditingController(); // Ini akan menjadi `username`
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController(); 
  final AuthService _authService = AuthService();

  String? _namaError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  bool _isLoading = false;

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validateNama(String nama) {
    setState(() {
      if (nama.isEmpty) {
        _namaError = 'Nama tidak boleh kosong';
      } else if (nama.length < 2) {
        _namaError = 'Nama minimal 2 karakter';
      } else {
        _namaError = null;
      }
    });
  }

  void _validateEmail(String email) {
    setState(() {
      if (email.isEmpty) {
        _emailError = 'Email tidak boleh kosong';
      } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        _emailError = 'Format email tidak valid';
      } else {
        _emailError = null;
      }
    });
  }

  void _validatePassword(String password) {
    setState(() {
      if (password.isEmpty) {
        _passwordError = 'Password tidak boleh kosong';
      } else if (password.length < 8) { // FIX: Password minimal 8 karakter (sesuai LoginPage)
        _passwordError = 'Password minimal 8 karakter';
      } else {
        _passwordError = null;
      }
      _validateConfirmPassword(_confirmPasswordController.text); 
    });
  }

  void _validateConfirmPassword(String confirmPassword) {
    setState(() {
      if (confirmPassword.isEmpty) {
        _confirmPasswordError = 'Konfirmasi password tidak boleh kosong';
      } else if (confirmPassword != _passwordController.text) {
        _confirmPasswordError = 'Password tidak cocok';
      } else {
        _confirmPasswordError = null;
      }
    });
  }

  // Fungsi untuk memeriksa koneksi internet yang lebih robust
  Future<bool> _checkInternetConnection() async {
    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return false; // Tidak ada jenis koneksi sama sekali
      }

      // Lakukan ping ke host yang dikenal stabil
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true; // Berhasil terhubung ke google.com
      }
      return false; // Tidak bisa menjangkau google.com
    } on SocketException catch (e) {
      debugPrint('Error SocketException checking internet: $e');
      return false; // Gagal menjangkau host
    } on PlatformException catch (e) {
      debugPrint('Error PlatformException checking internet: $e');
      return true; // Jika ada error platform, anggap terhubung
    } catch (e) {
      debugPrint('Error checking internet: $e');
      return true; // Asumsi terhubung jika error lain
    }
  }

  // Fungsi untuk menampilkan dialog error
  void _showErrorDialog(String title, String message) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 18)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF3F7D58))),
          ),
        ],
      ),
    );
  }

  // Fungsi untuk menampilkan dialog sukses
  void _showSuccessDialog(String message) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green),
            SizedBox(width: 8),
            Text('Berhasil', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.of(context).pushReplacementNamed('/login'); // Kembali ke halaman login
            },
            child: const Text('Login Sekarang', style: TextStyle(color: Color(0xFF3F7D58))),
          ),
        ],
      ),
    );
  }

  void _submit() async {
    final username = _namaController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Validasi form terlebih dahulu
    _validateNama(username);
    _validateEmail(email);
    _validatePassword(password);
    _validateConfirmPassword(confirmPassword);

    // Cek apakah ada field yang kosong
    if (username.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Semua field harus diisi!'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    // Cek apakah ada error validasi
    if (_namaError != null || _emailError != null || _passwordError != null || _confirmPasswordError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${_namaError ?? _emailError ?? _passwordError ?? _confirmPasswordError}'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    // Periksa koneksi internet terlebih dahulu
    bool isConnected = await _checkInternetConnection();
    if (!isConnected) {
      _showErrorDialog(
        'Tidak Ada Koneksi Internet',
        'Periksa koneksi internet Anda dan coba lagi.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    debugPrint('=== MEMULAI PROSES REGISTRASI ===');
    debugPrint('Username: "$username"');
    debugPrint('Email: "$email"');
    debugPrint('Password length: ${password.length}');
    debugPrint('Confirm Password length: ${confirmPassword.length}');
    debugPrint('Base URL AuthService: ${_authService.baseUrl}');

    try {
      final String message = await _authService.register(username, email, password);
      
      debugPrint('=== REGISTRASI BERHASIL ===');
      debugPrint('Pesan dari AuthService: $message');

      setState(() {
        _isLoading = false;
      });

      _showSuccessDialog(message);

    } on AuthException catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('=== ERROR REGISTRASI (AuthException) ===');
      debugPrint('Error message: ${e.message}');
      debugPrint('Status code: ${e.statusCode}');
      _showErrorDialog('Registrasi Gagal', e.message);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('=== ERROR REGISTRASI (Unhandled) ===');
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('Error: $e');

      String errorMessage = 'Registrasi gagal. Silakan coba lagi.';
      
      if (e is SocketException) {
        errorMessage = 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Waktu tunggu habis. Server tidak merespons.';
      } else if (e.toString().contains('FormatException')) {
        errorMessage = 'Terjadi kesalahan format data dari server.';
      }

      _showErrorDialog('Registrasi Gagal', errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Center(
                  child: Image.asset('assets/amico3.png', scale: 1.3),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Daftar Akun Baru!',
                  style: TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3F7D58),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Buat akun untuk mulai menggunakan aplikasi scan daun cabai',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // Input Nama (digunakan sebagai username untuk backend)
                CustomNama(
                  controller: _namaController,
                  onChanged: (value) => _validateNama(value),
                ),
                if (_namaError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 8),
                    child: Text(
                      _namaError!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                const SizedBox(height: 16),

                // Input Email
                CustomEmailField(
                  controller: _emailController,
                  onChanged: (value) => _validateEmail(value),
                ),
                if (_emailError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 8),
                    child: Text(
                      _emailError!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                const SizedBox(height: 16),

                // Input Password
                CustomPasswordField(
                  controller: _passwordController,
                  onChanged: (value) => _validatePassword(value),
                  labelText: 'Password',
                ),
                if (_passwordError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 8),
                    child: Text(
                      _passwordError!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                const SizedBox(height: 16),

                // Input Konfirmasi Password
                CustomPasswordField(
                  controller: _confirmPasswordController,
                  onChanged: (value) => _validateConfirmPassword(value),
                  labelText: 'Konfirmasi Password',
                ),
                if (_confirmPasswordError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 8),
                    child: Text(
                      _confirmPasswordError!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                const SizedBox(height: 24),

                // Button Daftar
                CustomButton(
                  text: _isLoading ? 'Loading...' : 'Daftar',
                  onPressed: _isLoading ? null : _submit,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 16),

                // Link ke Login
                FittedBox(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Sudah punya akun?',
                        style: TextStyle(color: Color(0xFF3F7D58)),
                      ),
                      TextButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            color: Color(0xFF3F7D58),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}