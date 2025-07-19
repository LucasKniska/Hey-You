import 'package:flutter/material.dart';
import 'XMarkPainter.dart';

class AnimatedXMark extends StatefulWidget {
  const AnimatedXMark({super.key});

  @override
  State<AnimatedXMark> createState() => _AnimatedXMarkState();
}

class _AnimatedXMarkState extends State<AnimatedXMark>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) {
        return CustomPaint(
          size: const Size(60, 60),
          painter: XMarkPainter(_animation.value),
        );
      },
    );
  }
}
