import 'package:flutter/material.dart';

class ButtonTentangApps extends StatelessWidget {
  final VoidCallback? onTap;

  const ButtonTentangApps({Key? key, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container( // FIX UTAMA: Bungkus dengan Material widget secara eksplisit
      margin: const EdgeInsets.only(bottom: 10), // Tambahkan margin bawah
      child: ListTile(
        leading: const Icon(
          Icons.info_outline,
          color: Color(0xFF3F7D58),
        ),
        title: const Text(
          'Tentang Aplikasi',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios, 
          color: Colors.grey.shade400, 
          size: 20
        ),
        onTap: onTap, // Memanggil callback onTap
      ),
    );
  }
}
