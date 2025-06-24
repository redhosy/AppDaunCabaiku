import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:klasifikasi_daun/presentation/widgets/custom_button.dart';
import 'package:klasifikasi_daun/presentation/widgets/custom_button_stroke.dart';
import 'package:klasifikasi_daun/presentation/widgets/custom_email_field.dart';
import 'package:klasifikasi_daun/presentation/widgets/custome_password_field.dart';
import 'package:klasifikasi_daun/services/auth_service.dart';
import 'dart:io';
import 'package:flutter/services.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  String? _emailError;
  String? _passwordError;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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

  void _validatePass(String password) {
    setState(() {
      if (password.isEmpty) {
        _passwordError = 'Password tidak boleh kosong';
      } else if (password.length < 8) {
        _passwordError = 'Password minimal 8 karakter';
      } else {
        _passwordError = null;
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
            Text(title, style: const TextStyle(fontSize: 16)),
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
            Text('Login Berhasil', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Tutup dialog
              Navigator.of(context).pushReplacementNamed('/home');
            },
            child: const Text('Lanjutkan', style: TextStyle(color: Color(0xFF3F7D58))),
          ),
        ],
      ),
    );
  }

  void _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    _validateEmail(email);
    _validatePass(password);

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Email dan password harus diisi!'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }
    
    if (_emailError != null || _passwordError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${_emailError ?? _passwordError}'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

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

    debugPrint('=== MEMULAI PROSES LOGIN ===');
    debugPrint('Email yang dikirim: "$email"');
    debugPrint('Password length: ${password.length}');
    debugPrint('Base URL AuthService: ${_authService.baseUrl}');

    try {
      final AuthResponse result = await _authService.login(email, password); 
      
      debugPrint('=== LOGIN BERHASIL (di LoginPage) ===');
      debugPrint('Response code: ${result.code}'); 
      debugPrint('Response status: ${result.status}');
      debugPrint('Response message: ${result.message}');
      debugPrint('Token: ${result.result?.accessToken ?? "No token"}');

      // FIX: Tambahkan debug prints untuk kondisi sukses
      debugPrint('--- Kondisi Sukses Detail ---');
      debugPrint('result.code == 200: ${result.code == 200}');
      debugPrint('result.status == "ok": ${result.status == 'ok'}');
      debugPrint('result.result?.accessToken != null: ${result.result?.accessToken != null}');
      debugPrint('result.result?.accessToken.isNotEmpty: ${result.result?.accessToken?.isNotEmpty}');

      if (result.code == 200 && 
          result.status == 'ok' && 
          result.result?.accessToken != null && 
          result.result!.accessToken.isNotEmpty) {
        
        setState(() {
          _isLoading = false;
        });
        _showSuccessDialog(result.message);

      } else {
        debugPrint('=== LOGIN GAGAL (Respons 200 OK tapi JSON error / Token tidak valid) ===');
        debugPrint('Code: ${result.code}, Status: ${result.status}');
        debugPrint('Token diterima: ${result.result?.accessToken != null}');
        debugPrint('Token isi: ${result.result?.accessToken?.isNotEmpty}');
        
        String errorMessage = result.message.isNotEmpty ? result.message : 'Login gagal, silakan coba lagi';
        throw AuthException(errorMessage, statusCode: result.code);
      }

    } on AuthException catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('=== ERROR LOGIN (AuthException) di LoginPage ===');
      debugPrint('Error message: ${e.message}');
      debugPrint('Status code: ${e.statusCode}');
      _showErrorDialog('Login Gagal', e.message);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('=== ERROR LOGIN (Unhandled Exception) di LoginPage ===');
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('Error: $e');

      String errorMessage = 'Login gagal. Silakan coba lagi.';
      String errorTitle = 'Login Gagal';
      
      if (e is SocketException) {
        errorMessage = 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
        errorTitle = 'Koneksi Bermasalah';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Waktu tunggu habis. Server tidak merespons.';
        errorTitle = 'Waktu Habis';
      } else if (e.toString().contains('FormatException')) {
        errorMessage = 'Terjadi kesalahan format data dari server.';
        errorTitle = 'Error Server';
      }

      _showErrorDialog(errorTitle, errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Center(
                    child: Image.asset(
                      'assets/amico2.png',
                      scale: 1.3,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Login Ke Akun Anda!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3F7D58),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Masuk untuk mengakses fitur scan daun cabai',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),

                  // Email Field
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

                  // Password input
                  CustomPasswordField(
                    controller: _passwordController,
                    onChanged: (value) => _validatePass(value),
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

                  const SizedBox(height: 24),

                  // Login Button
                  CustomButton(
                    text: _isLoading ? 'Loading...' : 'Login',
                    onPressed: _isLoading ? null : _submit,
                    isLoading: _isLoading,
                  ),

                  const SizedBox(height: 8),

                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading ? null : () {
                        Navigator.pushNamed(context, '/forgot');
                      },
                      child: const Text(
                        'Lupa Password?',
                        style: TextStyle(
                          color: Color(0xFF3F7D58),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Divider with "OR"
                  const Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Colors.grey,
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors.grey,
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Button Registrasi
                  CustomButtonStroke(
                    text: 'Registrasi',
                    onPressed: _isLoading ? null : () {
                      Navigator.pushNamed(context, '/register');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}