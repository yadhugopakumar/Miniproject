import 'package:flutter/material.dart';

import '../pages/auth/pinlogin.dart';

class SuccessDialog extends StatelessWidget {
  final String title;
  final String message;

  const SuccessDialog({
    Key? key,
    required this.title,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.green.shade50, // Light green background
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      title: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 28),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.green.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: TextStyle(color: Colors.green.shade900),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const LockScreen()));
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.green.shade800,
          ),
          child: const Text("OK"),
        ),
      ],
    );
  }
}
