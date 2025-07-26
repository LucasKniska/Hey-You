import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;

import 'package:hey_you/Data/repositories/user/user_repository.dart';

class MeetNowToggle extends StatelessWidget {
  MeetNowToggle({super.key});


  bool get enabled => UserRepository.instance.currentUserRx.value.discoverable;


  void toggleDiscoverable() {
    UserRepository.instance.currentUserRx.value.discoverable = !enabled;
    UserRepository.instance.updateUserField('Discoverable', UserRepository.instance.currentUserRx.value.discoverable);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {

      bool enabled = UserRepository.instance.currentUserRx.value.discoverable;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        width: double.infinity,
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.grey.shade50,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          border: Border.all(
            color: enabled ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: enabled
                  ? Colors.blue.withOpacity(0.08)
                  : Colors.grey.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          children: [
            // Header section with status and toggle
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  // Status indicator icon
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: enabled ? Colors.green : Colors.grey,
                      boxShadow: enabled ? [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        )
                      ] : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Status text
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        enabled ? 'You\'re discoverable' : 'You\'re hidden',
                        key: ValueKey(enabled),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: enabled ? Colors.black87 : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                  // Toggle switch - now tappable
                  GestureDetector(
                    onTap: () => {toggleDiscoverable()},
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 50,
                      height: 28,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: enabled ? Colors.blue : Colors.grey.shade300,
                      ),
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        alignment: enabled ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          width: 24,
                          height: 24,
                          margin: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Animated button section
            GestureDetector(
              onTap: () => {toggleDiscoverable()},
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 1000),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                  child: enabled
                      ? _AvailableButton(key: const ValueKey('available'))
                      : _ShimmerBorderButton(
                    key: const ValueKey('not_available'),
                    child: const Text(
                      'Press to find a new connection',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}



class _AvailableButton extends StatelessWidget {
  const _AvailableButton({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: const Text(
        'Finding you a new connection...',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _ShimmerBorderButton extends StatefulWidget {
  final Widget child;

  const _ShimmerBorderButton({required this.child, super.key});

  @override
  State<_ShimmerBorderButton> createState() => _ShimmerBorderButtonState();
}

class _ShimmerBorderButtonState extends State<_ShimmerBorderButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4), // Faster animation
      vsync: this,
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        // Create pulsing effect for border
        final pulseOpacity = (0.3 + 0.4 * (1 + math.sin(_controller.value * 2 * math.pi)) / 2);
        final shimmerWidth = 0.3;
        final shimmerCenter = _controller.value;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.transparent,
          ),
          child: CustomPaint(
            painter: ShimmerBorderPainter(
              shimmerCenter: shimmerCenter,
              shimmerWidth: shimmerWidth,
              pulseOpacity: pulseOpacity,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.transparent,
              ),
              child: Center(child: widget.child),
            ),
          ),
        );
      },
    );
  }
}

class ShimmerBorderPainter extends CustomPainter {
  final double shimmerCenter;
  final double shimmerWidth;
  final double pulseOpacity;

  ShimmerBorderPainter({
    required this.shimmerCenter,
    required this.shimmerWidth,
    required this.pulseOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));

    // Create the shimmer gradient
    final shimmerGradient = LinearGradient(
      colors: [
        Colors.transparent,
        Colors.blueAccent.withOpacity(0.6),
        Colors.white.withOpacity(0.9),
        Colors.blueAccent.withOpacity(0.6),
        Colors.transparent,
      ],
      stops: [
        (shimmerCenter - shimmerWidth).clamp(0.0, 1.0),
        (shimmerCenter - shimmerWidth/2).clamp(0.0, 1.0),
        shimmerCenter.clamp(0.0, 1.0),
        (shimmerCenter + shimmerWidth/2).clamp(0.0, 1.0),
        (shimmerCenter + shimmerWidth).clamp(0.0, 1.0),
      ],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    // Create the base border paint
    final baseBorderPaint = Paint()
      ..color = Colors.blueAccent.withOpacity(pulseOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Create the shimmer paint
    final shimmerPaint = Paint()
      ..shader = shimmerGradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Draw the base border
    canvas.drawRRect(rrect, baseBorderPaint);

    // Draw the shimmer effect on top
    canvas.drawRRect(rrect, shimmerPaint);
  }

  @override
  bool shouldRepaint(ShimmerBorderPainter oldDelegate) {
    return oldDelegate.shimmerCenter != shimmerCenter ||
        oldDelegate.pulseOpacity != pulseOpacity;
  }
}