import 'package:flutter/material.dart';

class CustomPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final Function(String)? onChanged;
  final String? errorText;
  final String labelText; // <-- Variabel ini sekarang akan digunakan

  const CustomPasswordField({
    Key? key,
    required this.controller,
    this.onChanged,
    this.errorText,
    required this.labelText, // <-- Menjadikan ini parameter yang diperlukan
  }) : super(key: key); // Menggunakan Key? key, bukan Key? key, required String labelText

  @override
  State<CustomPasswordField> createState() => _CustomPasswordFieldState();
}

class _CustomPasswordFieldState extends State<CustomPasswordField> {
  bool _isObscured = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      onChanged: widget.onChanged,
      obscureText: _isObscured,
      decoration: InputDecoration(
        labelText: widget.labelText, // <-- Menggunakan variabel labelText di sini
        hintText: 'Masukkan ${widget.labelText.toLowerCase()}', // Opsional: Sesuaikan hintText
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(_isObscured ? Icons.visibility_off : Icons.visibility),
          onPressed: () {
            setState(() {
              _isObscured = !_isObscured;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3F7D58), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        errorText: widget.errorText,
      ),
      textInputAction: TextInputAction.done,
    );
  }
}