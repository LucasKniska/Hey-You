import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
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
    final currentUserRx = UserRepository.instance.currentUserRx;

    final firstName = currentUser.firstName.isNotEmpty ? currentUser.firstName : "User";
    final lastInitial = currentUser.lastName.isNotEmpty ? currentUser.lastName : "";
    final initials =
        "${firstName.isNotEmpty ? firstName[0] : ''}${currentUser.lastName.isNotEmpty ? currentUser.lastName[0] : ''}";

    return Obx(() => Column(
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
        StatsBarWithInlineDeadline(currentUser: currentUserRx.value),
        const SizedBox(height: 18),
      
      ],
    ));
  }
}


class StatsBarWithInlineDeadline extends StatelessWidget {
  final dynamic currentUser; // pass currentUserRx.value
  final int windowDays;

  const StatsBarWithInlineDeadline({
    super.key,
    required this.currentUser,
    this.windowDays = 3,
  });

  @override
  Widget build(BuildContext context) {
    // ----- Deadline logic (same as your original) -----
    const names = ['None','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];

    DateTime now = DateTime.now();
    DateTime? nextline = currentUser.currentStreakTimer;
    DateTime nextDeadline;

    bool isPast;
    bool isToday;
    if (nextline != null && currentUser.currentStreak != 0){
      nextDeadline = currentUser.currentStreakTimer.toLocal().add(Duration(days: windowDays, minutes: -1));

      isPast = nextDeadline.isBefore(now.subtract(const Duration(days: 1)));
      isToday =
          nextDeadline.year == now.year &&
              nextDeadline.month == now.month &&
              nextDeadline.day == now.day;
    } else {
      isPast = true;
      isToday = false;
      nextDeadline = DateTime.now();
    }


    String line = '';
    if (!isPast) {
      line = isToday
          ? 'Connect with someone TODAY to keep your streak!'
          : 'Connect with someone new by ${names[nextDeadline.weekday]} to keep your streak!';
    }

    // Progress + urgency color (only if not past)
    int daysLeft = 0;
    double progress = 0.0;
    Color urgencyColor = Colors.green;

    if (!isPast) {
      final hoursLeft = nextDeadline.difference(now).inHours;
      daysLeft = nextDeadline.difference(now).inDays+1;
      progress = ( ((windowDays*24)-hoursLeft) / (windowDays*24));

      urgencyColor = daysLeft >= 2
          ? Colors.green
          : (daysLeft == 1 ? Colors.orange : Colors.red);
    }

    // ----- UI -----
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Stats row (your existing cards)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: AnimatedStatCard(
                      icon: Icons.flash_on,
                      label: 'Current Streak',
                      value: currentUser.currentStreak.toString(),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(22),
                        bottomLeft: Radius.circular(22),
                      ),
                    ),
                  ),
                  Container(width: 1, height: 64, color: Colors.grey[200]),
                  Expanded(
                    child: AnimatedStatCard(
                      icon: Icons.people,
                      label: (currentUser.totalConnections == 1)
                          ? 'Connection'
                          : 'Connections',
                      value: currentUser.totalConnections.toString(),
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

              // Inline reminder (only if deadline not in the past)
              if (!isPast) ...[
                const SizedBox(height: 10),
                Divider(height: 1, color: Colors.grey[200]),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.bolt_outlined, size: 18, color: urgencyColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        line,
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: urgencyColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      child: Text(
                        isToday
                            ? 'Today'
                            : '$daysLeft day${daysLeft > 1 ? 's' : ''} left',
                        style: TextStyle(
                          fontSize: 12,
                          color: urgencyColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.black12,
                    color: urgencyColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


Widget NextStreakDeadline() {
  const names = ['None', 'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];

  String text = '';

  DateTime? nextDeadline = UserRepository.instance.currentUser.currentStreakTimer;

  // The deadline is three days from nextDeadline
  // If the deadline is behind us then say nothing
  // If the deadline is today
  // Else specify the weekday

  if(nextDeadline == null){
    text = '';
  }
  nextDeadline = nextDeadline!.add(const Duration(days: 3));

  if(UserRepository.instance.currentUser.currentStreak == -1){
    text = '';
  } else if (nextDeadline.month == DateTime.now().month && nextDeadline.day == DateTime.now().day && nextDeadline.year == DateTime.now().year) {
    text = 'Connect with someone TODAY to keep your streak going!';
  } else if (nextDeadline.isBefore(DateTime.now())){
    text = '';
  } else {
    text = 'Connect with someone new by ${names[nextDeadline.weekday]} to keep your streak!';
  }

  return Text(
    text,
    style: TextStyle(color: Colors.grey[600])
  );
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