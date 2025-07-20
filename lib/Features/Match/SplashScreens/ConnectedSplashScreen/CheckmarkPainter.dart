
import 'package:flutter/material.dart';

class CheckmarkPainter extends CustomPainter {
  final double progress;

  CheckmarkPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(size.width * 0.2, size.height * 0.5);
    path.lineTo(size.width * 0.4, size.height * 0.7);
    path.lineTo(size.width * 0.8, size.height * 0.3);

    final totalLength = path.computeMetrics().first.length;
    final currentLength = totalLength * progress;

    final partialPath = Path();
    for (var metric in path.computeMetrics()) {
      partialPath.addPath(metric.extractPath(0, currentLength), Offset.zero);
    }

    canvas.drawPath(partialPath, paint);
  }

  @override
  bool shouldRepaint(covariant CheckmarkPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
