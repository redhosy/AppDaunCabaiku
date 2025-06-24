import 'package:flutter/material.dart';
import 'package:klasifikasi_daun/presentation/widgets/custom_button.dart';
import 'package:klasifikasi_daun/presentation/widgets/custom_email_field.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = false;
  String? _emailError;

  void _validateEmail(String email) {
    if (email.isEmpty) {
      _emailError = 'Email tidak boleh kosong';
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _emailError = 'Format email tidak valid';
    } else {
      _emailError = null;
    }
  }

  void _submit() {
    final email = _emailController.text.trim();

    setState(() {
      _validateEmail(email);
    });

    if (_emailError == null) {
      setState(() => _isLoading = true);

      Future.delayed(const Duration(seconds: 2), () {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Permintaan reset telah dikirim")),
        );

        Navigator.pop(context);
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Icon(Icons.arrow_back_ios_new_outlined),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Image.asset(
                    'assets/amico1.png',
                    scale: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Lupa Kata Sandi?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Masukkan alamat email yang terdaftar untuk mengatur ulang kata sandi Anda.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                // Email input
                Form(
                  key: _formKey,
                  child: CustomEmailField(
                    controller: _emailController,
                    onChanged: (value) {},
                  ),
                ),
                // Error message tampil di luar field
                if (_emailError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 8),
                    child: Text(
                      _emailError!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),

                const SizedBox(height: 24),

                // Tombol kirim
                CustomButton(
                    text: 'Kirim Permintaan',
                    onPressed: _isLoading ? null : _submit,
                    isLoading: _isLoading),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
