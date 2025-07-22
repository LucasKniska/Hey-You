import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedGradientBackground extends StatelessWidget {
  final Animation<double> controller;
  final Widget? child;

  const AnimatedGradientBackground({
    Key? key,
    required this.controller,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        final angle = 2 * pi * t;
        final shifted = (sin(angle) + 1) / 2;

        return Stack(
          children: [
            // Main subtle animated blue gradient
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-cos(angle), -sin(angle)),
                  end: Alignment(cos(angle), sin(angle)),
                  colors: [
                    Color.lerp(const Color(0xFFE3F0FF), const Color(0xFFCCE0FF), shifted)!, // lightest blue
                    Color.lerp(const Color(0xFFCCE0FF), const Color(0xFFA9D4FA), (cos(angle) + 1) / 2)!, // main subtle blue
                    Color.lerp(const Color(0xFFC0D5FF), const Color(0xFFD0E5FF), (sin(angle + pi) + 1) / 2)!, // mid blue
                  ],
                  stops: [
                    0.0,
                    0.7,
                    1.0,
                  ],
                ),
              ),
            ),
            if (child != null) child!,
          ],
        );
      },
    );
  }
}
