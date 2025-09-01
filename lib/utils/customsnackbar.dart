import 'package:flutter/material.dart';

class AppSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    bool success = true,
  }) {
    final bgColor = success ? const Color.fromARGB(255, 153, 236, 156) : Color.fromARGB(255, 255, 115, 105);
    final icon = success ? Icons.check_circle : Icons.error;

    ScaffoldMessenger.of(context).showSnackBar(
      
      SnackBar(
        
        content: Row(
          children: [
            Icon(icon,color:Colors.black),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }
}
