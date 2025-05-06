import 'package:flutter/material.dart';

class XMarkPainter extends CustomPainter {
  final double progress;

  XMarkPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(size.width * 0.2, size.height * 0.2);
    path.lineTo(size.width * 0.8, size.height * 0.8);
    path.moveTo(size.width * 0.8, size.height * 0.2);
    path.lineTo(size.width * 0.2, size.height * 0.8);

    final metrics = path.computeMetrics().toList();
    final totalLength = metrics.fold(0.0, (sum, m) => sum + m.length);
    final currentLength = totalLength * progress;

    final partialPath = Path();
    double drawn = 0.0;
    for (var metric in metrics) {
      final remaining = currentLength - drawn;
      if (remaining > 0) {
        final length = remaining.clamp(0.0, metric.length);
        partialPath.addPath(metric.extractPath(0, length), Offset.zero);
        drawn += length;
      }
    }

    canvas.drawPath(partialPath, paint);
  }

  @override
  bool shouldRepaint(covariant XMarkPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
