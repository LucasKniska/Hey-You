import 'package:flutter/material.dart';

import 'AnimatedCheckmark.dart';

class ConnectedSplashScreen extends StatefulWidget {
  final VoidCallback onFinish;

  const ConnectedSplashScreen({super.key, required this.onFinish});

  @override
  State<ConnectedSplashScreen> createState() => _ConnectedSplashScreenState();
}

class _ConnectedSplashScreenState extends State<ConnectedSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeOut;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(_controller);

    Future.delayed(const Duration(seconds: 2), () {
      _controller.forward(); // start fade out
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onFinish();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeOut,
      child: Container(
        color: Colors.green,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedCheckmark(),
              const SizedBox(height: 16),
              Text(
                'Connected',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
