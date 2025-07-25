import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hey_you/Data/repositories/user/user_repository.dart';

import '../../../Data/models/UserModel.dart';
import '../../../utils/constants/colors.dart';

class ProfileHeaderAndStats extends StatefulWidget {

  const ProfileHeaderAndStats({Key? key}) : super(key: key);

  @override
  State<ProfileHeaderAndStats> createState() => _ProfileHeaderAndStatsState();
}

class _ProfileHeaderAndStatsState extends State<ProfileHeaderAndStats> {
  @override
  Widget build(BuildContext context) {
    final currentUser = UserRepository.instance.currentUser;

    final firstName = currentUser.firstName.isNotEmpty ? currentUser.firstName : "User";
    final lastInitial = currentUser.lastName.isNotEmpty ? currentUser.lastName : "";
    final initials =
        "${firstName.isNotEmpty ? firstName[0] : ''}${currentUser.lastName.isNotEmpty ? currentUser.lastName[0] : ''}";

    return Column(
      children: [
        const SizedBox(height: 32),
        // Profile header: avatar + name
        Center(
          child: Column(
            children: [
              Material(
                elevation: 7,
                shape: const CircleBorder(),
                child: Container(
                  padding: const EdgeInsets.all(3), // Border thickness
                  decoration: const BoxDecoration(
                    color: Colors.white, // Border color
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 34,
                    backgroundColor: TColors.primary.withAlpha(180),
                    child: Text(
                      initials.isNotEmpty ? initials : '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 26,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  "$firstName $lastInitial",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        // Animated Stats Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: AnimatedStatCard(
                  icon: Icons.people,
                  label: (currentUser.totalConnections == 1) ? 'Connection' : 'Connections',
                  value: currentUser.totalConnections.toString(),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(22),
                    bottomLeft: Radius.circular(22),
                  ),
                ),
              ),
              Container(width: 1, height: 64, color: Colors.grey[200]),
              Expanded(
                child: AnimatedStatCard(
                  icon: Icons.flash_on,
                  label: 'Current Streak',
                  value: currentUser.currentStreak.toString(),
                  borderRadius: BorderRadius.zero,
                ),
              ),
              Container(width: 1, height: 64, color: Colors.grey[200]),
              Expanded(
                child: AnimatedStatCard(
                  icon: Icons.star,
                  label: 'Longest Streak',
                  value: currentUser.longestStreak.toString(),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(22),
                    bottomRight: Radius.circular(22),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
      ],
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
          elevation: 6,
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