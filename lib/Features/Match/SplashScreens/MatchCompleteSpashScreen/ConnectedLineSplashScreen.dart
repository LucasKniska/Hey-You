import 'package:flutter/material.dart';

class ConnectedCircleSplashScreen extends StatefulWidget {
  final VoidCallback onFinish;

  const ConnectedCircleSplashScreen({super.key, required this.onFinish});

  @override
  State<ConnectedCircleSplashScreen> createState() =>
      _ConnectedCircleSplashScreenState();
}

class _ConnectedCircleSplashScreenState
    extends State<ConnectedCircleSplashScreen> with TickerProviderStateMixin {
  late AnimationController _moveController;
  late AnimationController _fadeController;

  late Animation<double> _movement;
  late Animation<double> _textOpacity;
  late Animation<double> _fadeOut;

  @override
  void initState() {
    super.initState();

    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000), // Made fade out longer
    );

    _movement = Tween<double>(begin: 0.35, end: 0.0).animate(
      CurvedAnimation(parent: _moveController, curve: Curves.easeOutExpo),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _moveController,
        curve: const Interval(0.8, 1.0, curve: Curves.easeIn),
      ),
    );

    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(_fadeController);

    _moveController.forward();

    Future.delayed(const Duration(seconds: 4), () {
      _fadeController.forward();
    });

    _fadeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onFinish();
      }
    });
  }

  @override
  void dispose() {
    _moveController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeOut,
      child: Container(
        color: Colors.blue,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;
            final centerY = screenHeight * 0.4;
            const iconSize = 80.0;
            const iconRadius = iconSize / 2;

            return AnimatedBuilder(
              animation: _movement,
              builder: (context, child) {
                final centerX = screenWidth / 2;

                final leftX = centerX - iconRadius - (_movement.value * screenWidth);
                final rightX = centerX + iconRadius + (_movement.value * screenWidth) - iconSize;
                final rotation = _movement.value * 4; // Slower rolling

                return Stack(
                  children: [
                    Positioned(
                      left: leftX,
                      top: centerY,
                      child: _buildPersonCircle(rotation),
                    ),
                    Positioned(
                      left: rightX,
                      top: centerY,
                      child: _buildPersonCircle(-rotation),
                    ),
                    Align(
                      alignment: const Alignment(0, 0.1),
                      child: FadeTransition(
                        opacity: _textOpacity,
                        child: Text(
                          'Connected',
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildPersonCircle(double rotation) {
    return RotatingCircle(
      rotation: rotation,
      size: 80,
      child: const Icon(Icons.person, color: Colors.white, size: 48),
    );
  }
}

class RotatingCircle extends StatelessWidget {
  final double rotation;
  final double size;
  final Widget child;

  const RotatingCircle({
    super.key,
    required this.rotation,
    required this.size,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: rotation,
            child: CustomPaint(
              size: Size(size, size),
              painter: ArcBorderPainter(),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class ArcBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final rect = Offset.zero & size;
    final startAngle = 0.0;
    final sweepAngle = 2 * 3.14159 * 0.8; // 80% arc

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


