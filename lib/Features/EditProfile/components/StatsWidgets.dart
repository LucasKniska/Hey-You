import 'package:flutter/material.dart';

import '../../../Data/models/UserModel.dart';

class StatsRow extends StatelessWidget {
  final UserModel currentUser;

  const StatsRow({Key? key, required this.currentUser}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // A pill effect: First/Last cards have only one rounded side
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: AnimatedStatCard(
              icon: Icons.people,
              label: (currentUser.totalConnections == 1) ? 'Connection' : 'Connections',
              value: currentUser.totalConnections.toString(),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(36),
                bottomLeft: Radius.circular(36),
              ),
            ),
          ),
          Container(width: 1, height: 64, color: Colors.grey[200]), // thin divider
          Expanded(
            child: AnimatedStatCard(
              icon: Icons.flash_on,
              label: 'Current Streak',
              value: currentUser.currentStreak.toString(),
              borderRadius: BorderRadius.zero,
            ),
          ),
          Container(width: 1, height: 64, color: Colors.grey[200]), // thin divider
          Expanded(
            child: AnimatedStatCard(
              icon: Icons.star,
              label: 'Longest Streak',
              value: currentUser.longestStreak.toString(),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedStatCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String value;
  final BorderRadius borderRadius;

  const AnimatedStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.borderRadius,
    Key? key,
  }) : super(key: key);

  @override
  State<AnimatedStatCard> createState() => _AnimatedStatCardState();
}

class _AnimatedStatCardState extends State<AnimatedStatCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scaleAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.08), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
    _controller.forward(from: 0.0);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
  }

  void _onTapCancel() {
    setState(() {
      _isPressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color bgColor = _isPressed ? Colors.blueAccent : Colors.white;
    final Color iconColor = _isPressed ? Colors.white : Colors.blueAccent;
    final Color textColor = _isPressed ? Colors.white : Colors.grey[700]!;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Material(
          elevation: 2,
          color: bgColor,
          borderRadius: widget.borderRadius,
          child: Container(
            height: 110,
            margin: EdgeInsets.zero,
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, size: 30, color: iconColor),
                const SizedBox(height: 6),
                Text(
                  widget.value,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: textColor),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: textColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
