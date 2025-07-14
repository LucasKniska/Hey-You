import 'package:flutter/material.dart';

Widget rightCenteredButton({
  required String label,
  required IconData icon,
  required VoidCallback onPressed,
  bool enabled = true,
  Color accent = Colors.blue,
}) {
  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      minimumSize: const Size(90, 38),
      backgroundColor: enabled ? accent : accent.withOpacity(0.5),
      foregroundColor: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
    ),
    onPressed: enabled ? onPressed : null,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        Icon(icon, size: 18, color: Colors.white),
      ],
    ),
  );
}



