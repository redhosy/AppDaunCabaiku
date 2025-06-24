import 'package:flutter/material.dart';

class EditUserMenuItem extends StatelessWidget {
  final VoidCallback? onTap;

  const EditUserMenuItem({Key? key, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const Icon(
          Icons.edit_document,
          color: Color(0xFF3F7D58),
        ),
        title: const Text(
          'Edit User',
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