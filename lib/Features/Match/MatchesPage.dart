import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hey_you/Common/styles/spacing_styles.dart';
import 'package:hey_you/Data/models/CurrentMatch.dart';
import 'package:hey_you/Data/repositories/user/user_repository.dart';
import 'package:hey_you/Features/Match/MeetNowPage.dart';
import 'package:hey_you/Features/Match/subwidgets/MeetNowToggle.dart';
import 'package:hey_you/Features/Match/subwidgets/SearchFilters.dart';
import 'package:hey_you/Features/Match/subwidgets/SectionTitle.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../Data/models/UserModel.dart';
import '../../utils/constants/sizes.dart';
import '../../utils/constants/text_string.dart';
import '../EditProfile/profile_controller.dart';
import '../ViewConnections/previousConnections.dart';
import 'MatchPopup.dart';
import 'SplashScreens/RejectedSplashScreen/RejectedSplashScreen.dart';
import 'controllers/howToMeet_controller.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {

  Timer? matchTimer;
  late Duration? remaining;
  CurrentMatch? current;
  int userNum = -1;
  RxString matchHeader = ''.obs;

  final userRepo = UserRepository.instance;
  final currentUser = UserRepository.instance.currentUser;

  // Enhanced animation controllers
  late AnimationController _glowController;
  late AnimationController _shimmerController;
  late AnimationController _floatController;
  late AnimationController _colorController;
  late AnimationController _borderController;

  // Enhanced animations
  late Animation<double> _glowAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _floatAnimation;
  late Animation<Color?> _colorAnimation1;
  late Animation<Color?> _colorAnimation2;
  late Animation<double> _borderAnimation;

  @override
  void initState() {
    super.initState();
    Get.put(ProfileController());

    remaining = null;

    checkForCurrentMatch();

    // Watch currentUser changes
    ever<UserModel?>(userRepo.currentUserRx, (user) async {
      if (user == null) return;

      final profile = ProfileController.instance;
      profile.updateMods();

      final currentMatchId = user.currentMatch;


      print('Reacting to user change in MapPage');
      print(currentMatchId);
      print(currentMatchId.isEmpty);

      if (currentMatchId.isEmpty) {
        setState(() {
          current = null;
        });
        return;
      }

      CurrentMatch? currentMatchNow = await loadCurrentMatch(currentMatchId);


      print('Current Match Now: $currentMatchNow');

      if (!mounted || currentMatchNow == null || currentMatchNow == current) return;
      setState(() => remaining = Duration(minutes: 10));

      if(matchTimer != null && matchTimer!.isActive){
        matchTimer!.cancel();
      }
      matchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if(context.mounted) {
          final Duration newRemaining = currentMatchNow.expirationTime.difference(
            DateTime.now(),
          );
          setState(() => remaining = newRemaining);
        }
      });


      String matchHeaderUpdate;
      if (currentMatchNow.status == 'new') {
        matchHeaderUpdate = 'New Connection!';
      } else if (currentMatchNow.status == 'now') {
        matchHeaderUpdate = 'Meet Up Now!';
      } else {
        matchHeaderUpdate = '';
      }

      setState(() {
        current = currentMatchNow;
        userNum = (currentMatchNow.userData[0].id == currentUser.id) ? 0 : 1;
        matchHeader.value = matchHeaderUpdate;
      });
    });

      // Initialize enhanced animations
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )
      ..repeat(reverse: true);

    _shimmerController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )
      ..repeat();

    _floatController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )
      ..repeat(reverse: true);

    _colorController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )
      ..repeat(reverse: true);

    _borderController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )
      ..repeat();

    // Glow animation - subtle intensity changes
    _glowAnimation = Tween<double>(
      begin: 0.1,
      end: 0.4,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    // Gentler shimmer animation
    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));

    // Subtle floating animation
    _floatAnimation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOut,
    ));

    // Color breathing animations
    _colorAnimation1 = ColorTween(
      begin: Colors.blue.shade400,
      end: Colors.purple.shade400,
    ).animate(CurvedAnimation(
      parent: _colorController,
      curve: Curves.easeInOut,
    ));

    _colorAnimation2 = ColorTween(
      begin: Colors.lightBlue.shade300,
      end: Colors.pink.shade300,
    ).animate(CurvedAnimation(
      parent: _colorController,
      curve: Curves.easeInOut,
    ));

    // Border light animation
    _borderAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _borderController,
      curve: Curves.easeInOut,
    ));

  }

  @override
  void dispose() {
    _glowController.dispose();
    _shimmerController.dispose();
    _floatController.dispose();
    _colorController.dispose();
    _borderController.dispose();
    matchTimer?.cancel();
    super.dispose();
  }

  Future<CurrentMatch?> loadCurrentMatch(String matchId) async {
    final doc = await FirebaseFirestore.instance.collection('Matches').doc(matchId).get();
    if (doc.exists) {
      return CurrentMatch.fromJson(doc.data()!);
    }
    return null;
  }

  Widget _buildNewConnectionCard() {
    if (current == null) return const SizedBox.shrink();

    final otherUserName = (currentUser.id == current!.userData[0].id)
        ? current!.userData[1].userName
        : current!.userData[0].userName;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _glowController,
        _shimmerController,
        _floatController,
        _colorController,
        _borderController,
      ]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: Container(
            margin: const EdgeInsets.only(left: 16, right: 16),
            child: Stack(
              children: [
                // Subtle glow effect
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(_glowAnimation.value),
                        blurRadius: 15 + (_glowAnimation.value * 10),
                        offset: const Offset(0, 4),
                        spreadRadius: _glowAnimation.value * 3,
                      ),
                      BoxShadow(
                        color: Colors.purple.withOpacity(_glowAnimation.value * 0.5),
                        blurRadius: 20 + (_glowAnimation.value * 5),
                        offset: const Offset(0, 8),
                        spreadRadius: _glowAnimation.value * 2,
                      ),
                    ],
                  ),
                ),

                // Gentle gradient shimmer background
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        _colorAnimation1.value ?? Colors.blue.shade400,
                        _colorAnimation2.value ?? Colors.lightBlue.shade300,
                        Colors.blue.shade300,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      transform: GradientRotation(_shimmerAnimation.value * 0.5),
                    ),
                  ),
                ),

                // Border light effect
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3 + (_borderAnimation.value * 0.4)),
                      width: 1.5,
                    ),
                  ),
                ),

                // Main card content
                Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: Colors.white,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (current!.id.isNotEmpty && current!.status == 'new') {
                          Get.dialog(MatchPopup(current: current!)).then((_) async {
                            final refreshed = await loadCurrentMatch(current!.id);
                            if (refreshed != null) {
                              setState(() {
                                current = refreshed;
                                matchHeader.value = refreshed.status == 'new'
                                    ? 'New Connection!'
                                    : refreshed.status == 'now'
                                    ? 'Meet Up Now!'
                                    : '';
                              });
                            }
                          });
                        } else {
                          Get.to(() => MeetNowPage(
                            current: current!,
                            userLocation: current!.userData[0].location,
                            otherUserLocation: current!.userData[1].location,
                          ));
                        }
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            // Celebration emoji and header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(width: 8),
                                Obx(() => Text(
                                  matchHeader.value,
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                )),
                                const SizedBox(width: 8),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // User avatar with subtle animation
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue.shade100,
                                    Colors.lightBlue.shade100,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Iconsax.user,
                                size: 48,
                                color: Colors.blue.shade600,
                              ),
                            ),

                            const SizedBox(height: 16),

                            Text(
                              otherUserName,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),

                            const SizedBox(height: 4),

                            TimeToConnect(),

                            const SizedBox(height: 8),

                            // Action button with app-consistent styling
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue.shade400,
                                    Colors.lightBlue.shade400,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  if (current!.id.isNotEmpty && current!.status == 'new') {
                                    Get.dialog(MatchPopup(current: current!));
                                  } else {
                                    Get.to(() => MeetNowPage(
                                      current: current!,
                                      userLocation: current!.userData[0].location,
                                      otherUserLocation: current!.userData[1].location,
                                    ));
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      current!.status == 'new'
                                          ? Iconsax.search_normal_1
                                          : Iconsax.location,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      current!.status == 'new'
                                          ? 'View Profile'
                                          : 'Meet Now',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    /// Checks if the timer has run out
    if(remaining != null && remaining! < Duration.zero && current != null){
      print('Printing remaining: ${_formatDuration(remaining!)}');
      HowToMeetController.deleteCurrentMatch(current!);
      // Loading screen type
      return RejectedSplashScreen(
        onFinish: () => {
          // Change the data to create a new match
          setState(() {})

        },
      );
    }


    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Status header with toggle
            MeetNowToggle(),

            // NEW CONNECTION CARD - Enhanced with subtle animations
            _buildNewConnectionCard(),

            /// Combined Header and Possible Matches Section
            Container(
              color: Colors.white,
              alignment: Alignment.center,
              padding: TSpacingStyle.normalPadding,
              child: Column(
                children: [
                  // Section title
                  Container(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: sectionTitle(Iconsax.people, 'Possible Matches Near You'),
                  ),

                  SizedBox(height: TSizes.spaceBtwSections),

                  // sectionTitle(Iconsax.personalcard, 'Search Filters'),
                  SizedBox(height: TSizes.spaceBtwItems),
                  searchFilters(context),

                  /// Previous Connections Sections
                  sectionTitle(Iconsax.personalcard, TTexts.previousConnections),
                  SizedBox(height: TSizes.spaceBtwItems),
                  PreviousConnection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}';
  }


  void checkForCurrentMatch() async {

    UserModel user = currentUser;

    final profile = ProfileController.instance;
    profile.updateMods();

    final currentMatchId = user.currentMatch;


    print('Reacting to user change in MapPage');
    print(currentMatchId);
    print(currentMatchId.isEmpty);

    if (currentMatchId.isEmpty) {
      setState(() {
        current = null;
        remaining = null;
      });
      matchTimer?.cancel();
      return;
    }

    CurrentMatch? currentMatchNow = await loadCurrentMatch(currentMatchId);

    print('Current Match Now: $currentMatchNow');

    if (!mounted || currentMatchNow == null || currentMatchNow == current) return;
    setState(() => remaining = Duration(minutes: 10));

    if(matchTimer != null && matchTimer!.isActive){
      matchTimer!.cancel();
    }
    matchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {

      if(context.mounted) {
        final Duration newRemaining = currentMatchNow.expirationTime.difference(
          DateTime.now(),
        );

        setState(() => remaining = newRemaining);
      }
    });

    String matchHeaderUpdate;
    if (currentMatchNow.status == 'new') {
      matchHeaderUpdate = 'New Connection!';
    } else if (currentMatchNow.status == 'now') {
      matchHeaderUpdate = 'Meet Up Now!';
    } else {
      matchHeaderUpdate = '';
    }

    setState(() {
      current = currentMatchNow;
      userNum = (currentMatchNow.userData[0].id == currentUser.id) ? 0 : 1;
      matchHeader.value = matchHeaderUpdate;
    });
  }


  Widget TimeToConnect() {

    if (current!.status != 'new') {
      return Text(
        'Ready to meet up!',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Colors.grey.shade600,
        ),
      );
    }

    if(remaining!.inSeconds < 120) {
      return Text(
        'Time left to connect: ' + _formatDuration(remaining!),
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Colors.red,
        ),
      );
    }

    return Text(
      'Time left to connect: ' + _formatDuration(remaining!),
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: Colors.grey.shade600,
      ),
    );
  }
}