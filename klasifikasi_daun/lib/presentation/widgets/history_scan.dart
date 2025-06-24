import 'package:flutter/material.dart';

class RiwayatScanMenuItem extends StatelessWidget {
  final VoidCallback? onTap;

  const RiwayatScanMenuItem({Key? key, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const Icon(
          Icons.history,
          color: Color(0xFF3F7D58),
        ),
        title: const Text(
          'Riwayat Scan',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: onTap
      ),
    );
  }
}