import 'package:flutter/material.dart';

Widget leftIconCenteredTextBtn({
  required VoidCallback? onPressed,
  required Color bg,
  required Color fg,
  required BorderSide side,
  required IconData icon,
  required String label,
}) =>
    ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(120, 48),
        backgroundColor: bg,
        foregroundColor: fg,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: side,
        padding: EdgeInsets.zero,
      ),
      onPressed: onPressed,
      icon:Icon(icon,
        color: Colors.black87,
        size: 18,
      ),
      label: Text(label),
    );

