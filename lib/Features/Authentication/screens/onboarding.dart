import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:hey_you/Features/Authentication/screens/signup.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../components/PulsingButton.dart';
import '../components/ShimmeringText.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({Key? key}) : super(key: key);

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  double _waveOffset = 0;

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
      // This line animates the wave offset whenever you swipe!
      _waveOffset = (page % onboardingSteps.length) * 150.0;
    });
  }

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      final newPage = _pageController.page?.round() ?? 0;
      if (newPage != _currentPage) {
        setState(() {
          _currentPage = newPage;
          _waveOffset = (_currentPage % 3) * 100.0; // or use steps.length
        });
      }
    });
  }

  final List<_OnboardingData> onboardingSteps = [
    _OnboardingData(
      icon: Iconsax.task_square,
      title: 'Take Our Personality Test',
      description:
          'Answer a few quick questions so we can match you with someone you’ll actually click with.',
    ),
    _OnboardingData(
      icon: Iconsax.setting_4,
      title: 'Set Your Preferences',
      description:
          'Choose who you want to meet—update your interests and filters any time for the perfect match in the moment.',
    ),
    _OnboardingData(
      icon: Iconsax.people,
      title: 'Match & Meet',
      description:
          'Get paired with someone nearby. If you find the connection interesting, we will help you meet them!',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Top animated wave
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            left: -300 + _waveOffset, // Make this more negative
            top: -100,
            child: _WaveShape(
              width: 800, // Make this much wider
              height: 200, // Optionally a bit taller too
              color: Colors.blue.shade100,
            ),
          ),

          // Bottom animated wave
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            right:  -300+_waveOffset,
            bottom: -110,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationX(pi), // Flip vertically
              child: _WaveShape(
                width: 800,
                height: 200,
                color: Colors.purple.shade100,
              ),
            ),
          ),

          const AnimatedBubblesBackground(bottomHeavier: true),
          SafeArea(
            child: Column(
              children: [
                // EXPANDED: Center the content vertically
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // <-- KEY
                      children: [

                        ShimmerText(
                          text: "HeyU",
                          style: TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 3),
                                blurRadius: 16,
                                color: Theme.of(context).primaryColor.withOpacity(0.18),
                              ),
                            ],
                          ),
                        ),


                        const SizedBox(height: 8),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 28),
                          child: Text(
                            'Meet Real People. Make Real Connections.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Opacity(
                            opacity: 0.5,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Iconsax.arrow_left_2, size: 18),
                                SizedBox(width: 4),
                                Text('Swipe', style: TextStyle(fontSize: 14)),
                                SizedBox(width: 4),
                                Icon(Iconsax.arrow_right_3, size: 18),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 300,
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: onboardingSteps.length,
                            onPageChanged: _onPageChanged,
                            itemBuilder: (context, index) {
                              final data = onboardingSteps[index];
                              return _OnboardingCard(
                                icon: data.icon,
                                title: data.title,
                                description: data.description,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        SmoothPageIndicator(
                          controller: _pageController,
                          count: onboardingSteps.length,
                          effect: WormEffect(
                            dotColor: Colors.grey.shade300,
                            activeDotColor: Theme.of(context).primaryColor,
                            dotHeight: 10,
                            dotWidth: 10,
                          ),
                        ),

                      ],
                    ),
                  ),
                ),
                // Always at bottom
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 28,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: PulsingButton(
                      text: "Get Started",
                      onPressed: () {
                        Get.to(
                              () => SignUpScreen(), // Your page widget
                          transition: Transition.rightToLeft, // This slides the new page in from the right
                          duration: Duration(milliseconds: 400), // Optional: controls animation speed
                        );

                      },
                    ),

                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingData {
  final IconData icon;
  final String title;
  final String description;

  _OnboardingData({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class _OnboardingCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      margin: const EdgeInsets.symmetric(horizontal: 28, vertical: 6),
      color: Colors.white.withOpacity(0.96),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 34),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: Theme.of(context).primaryColor),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 13),
            Text(
              description,
              style: TextStyle(fontSize: 15.5, color: Colors.grey.shade800),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Animated Bubbles: blue, purple, green; more bubbles on the bottom
class AnimatedBubblesBackground extends StatefulWidget {
  final bool bottomHeavier;
  const AnimatedBubblesBackground({this.bottomHeavier = false, Key? key})
    : super(key: key);

  @override
  State<AnimatedBubblesBackground> createState() =>
      _AnimatedBubblesBackgroundState();
}

class _AnimatedBubblesBackgroundState extends State<AnimatedBubblesBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Bubble> _bubbles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    // More bubbles at the bottom if bottomHeavier is true
    _bubbles = List.generate(10, (index) {
      final top =
          widget.bottomHeavier
              ? (index < 5
                  ? Random().nextDouble() *
                      270 // upper bubbles
                  : 270 + Random().nextDouble() * 530) // lower bubbles
              : Random().nextDouble() * 700;
      final left = Random().nextDouble() * 370;
      final size = 20.0 + Random().nextDouble() * 54;
      // Colors: blue, purple, green only
      final color =
          [
            Colors.blue.shade100,
            Colors.blue.shade200,
            Colors.blue.shade300,
            Colors.purple.shade100,
            Colors.purple.shade200,
            Colors.green.shade100,
            Colors.green.shade200,
            Colors.teal.shade200,
          ][index % 8];
      return _Bubble(left: left, top: top, size: size, color: color);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return IgnorePointer(
          child: Stack(
            children:
                _bubbles.map((bubble) {
                  final double opacity =
                      0.33 +
                      0.25 * sin(_controller.value * 2 * pi + bubble.size);
                  return Positioned(
                    left: bubble.left,
                    top:
                        bubble.top +
                        18 *
                            sin(_controller.value * 2 * pi + bubble.left / 120),
                    child: Opacity(
                      opacity: opacity.clamp(0.08, 0.68),
                      child: Container(
                        width: bubble.size,
                        height: bubble.size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: bubble.color,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        );
      },
    );
  }
}

class _Bubble {
  final double left;
  final double top;
  final double size;
  final Color color;

  _Bubble({
    required this.left,
    required this.top,
    required this.size,
    required this.color,
  });
}

class _WaveShape extends StatelessWidget {
  final double width;
  final double height;
  final Color color;

  const _WaveShape({
    required this.width,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(width, height), painter: _WavePainter(color));
  }
}

class _WavePainter extends CustomPainter {
  final Color color;
  _WavePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withOpacity(0.8);

    final path =
        Path()
          ..moveTo(0, size.height * 0.8)
          ..quadraticBezierTo(
            size.width * 0.25,
            size.height * 1.05,
            size.width * 0.5,
            size.height * 0.85,
          )
          ..quadraticBezierTo(
            size.width * 0.75,
            size.height * 0.65,
            size.width,
            size.height * 0.85,
          )
          ..lineTo(size.width, 0)
          ..lineTo(0, 0)
          ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

