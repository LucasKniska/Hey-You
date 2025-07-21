

import 'package:flutter/material.dart';

import '../utils/constants/colors.dart';

import 'package:get/get.dart'; // Import GetX
import '../Data/repositories/user/user_repository.dart'; // Import your UserRepository

class TopBar extends StatefulWidget implements PreferredSizeWidget {
  final bool backArrow;

  const TopBar({super.key, this.backArrow = false});

  @override
  State<TopBar> createState() => _TopBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
// ... (imports remain the same)
// ... (imports remain the same, ensure you have TColors defined)
// import 'dart:math' as math; // For Pi if you prefer

class _TopBarState extends State<TopBar>
    with TickerProviderStateMixin { // << Use TickerProviderStateMixin for multiple controllers if needed
  late AnimationController _gradientRotationController;
  late Animation<double> _rotationAnimation;

  // For the cross-fade animation
  // No explicit controller needed for AnimatedCrossFade, duration is set directly

  final UserRepository _userRepository = UserRepository.instance;

  @override
  void initState() {
    super.initState();
    _gradientRotationController = AnimationController(
      vsync: this, // A single TickerProvider is fine here
      duration: const Duration(seconds: 20),
    )..repeat();

    _rotationAnimation =
        Tween<double>(begin: 0.0, end: 2.0 * 3.1415926535).animate( // Using Pi literal
          CurvedAnimation(
            parent: _gradientRotationController,
            curve: Curves.linear,
          ),
        );
  }

  @override
  void dispose() {
    _gradientRotationController.dispose();
    super.dispose();
  }

  // Helper function to build the gradient container to avoid repetition
  Widget _buildGradientContainer(List<Color> gradientColors, bool isDiscoverable) {
    // If you want the rotation animation to stop when not discoverable,
    // you could conditionally use _rotationAnimation.value or a fixed value (e.g., 0.0)
    // For simplicity here, we'll let it rotate the gray gradient too.
    return AnimatedBuilder(
        animation: _rotationAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                transform: GradientRotation(_rotationAnimation.value),
              ),
            ),
          );
        });
  }

  Widget _buildSolidGrayContainer() {
    return Container(
      color: Colors.grey.shade800, // Example solid gray
    );
  }


  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bool isUserDiscoverable = _userRepository.currentUserRx.value.discoverable;

      // Define the two states for AnimatedCrossFade
      Widget firstChild; // Discoverable UI
      Widget secondChild; // Non-discoverable UI

      List<Color> discoverableGradientColors = [
        TColors.primary,
        TColors.accent,
        TColors.accent.withOpacity(0.9),
        TColors.primary.withOpacity(0.8),
      ];

      List<Color> nonDiscoverableGradientColors = [ // If you want animated gray
        Colors.grey.shade500,
        Colors.grey.shade600,
        Colors.grey.shade600,
        Colors.grey.shade500,
      ];

      if (isUserDiscoverable) {
        firstChild = _buildGradientContainer(discoverableGradientColors, true);
        // secondChild could be an empty container or a transparent one if you
        // only want the discoverable state to have a complex gradient.
        // For a smoother morph *to* gray, secondChild should be the gray state.
        // But for AnimatedCrossFade, one is "first" and one is "second".
        // Let's make firstChild always the discoverable state,
        // and secondChild always the non-discoverable one.
      }
      // Non-discoverable state will be the second child for the cross-fade

      //Animated Gray Gradient
      secondChild = _buildGradientContainer(nonDiscoverableGradientColors, false);

      return AppBar(
        automaticallyImplyLeading: false,
        leading: widget.backArrow
            ? IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        )
            : null,
        title: Text(
          'Hey You',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            // Text color might need to adapt if background becomes very light
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        flexibleSpace: AnimatedCrossFade(
          duration: const Duration(milliseconds: 2000), // Adjust duration of the morph
          firstChild: isUserDiscoverable
              ? _buildGradientContainer(discoverableGradientColors, true)
              : _buildGradientContainer(nonDiscoverableGradientColors, true),
          secondChild: !isUserDiscoverable
              ? _buildGradientContainer(nonDiscoverableGradientColors, true)
              : _buildGradientContainer(discoverableGradientColors, true), // The "other" state
          crossFadeState: isUserDiscoverable
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          // Optional: customize the fade curves
          // firstCurve: Curves.easeInOut,
          // secondCurve: Curves.easeInOut,
          // sizeCurve: Curves.easeInOut,
          layoutBuilder: (topChild, topChildKey, bottomChild, bottomChildKey) {
            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: <Widget>[
                Positioned(
                  key: bottomChildKey,
                  left: 0.0,
                  top: 0.0,
                  right: 0.0,
                  bottom: 0.0,
                  child: bottomChild,
                ),
                Positioned(
                  key: topChildKey,
                  child: topChild,
                ),
              ],
            );
          },
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      );
    });
  }
}
