import 'package:flutter/material.dart';
import 'AnimatedXMark.dart';

class RejectedSplashScreen extends StatefulWidget {
  final VoidCallback onFinish;

  const RejectedSplashScreen({super.key, required this.onFinish});

  @override
  State<RejectedSplashScreen> createState() => _RejectedSplashScreenState();
}

class _RejectedSplashScreenState extends State<RejectedSplashScreen>
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
      if (mounted) {
        _controller.forward(); // start fade out
      }
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
        color: Colors.redAccent,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AnimatedXMark(),
              const SizedBox(height: 16),
              Text(
                'Connection Rejected',
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
