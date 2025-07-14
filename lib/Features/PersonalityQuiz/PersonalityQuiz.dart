import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:hey_you/Common/topbar.dart';
import 'package:hey_you/Features/PersonalityQuiz/personality_quiz_controller.dart';
import 'package:hey_you/Features/PersonalityQuiz/subwidgets/leftCenteredIconButton.dart';
import 'package:hey_you/Features/PersonalityQuiz/subwidgets/rightCenteredIconButton.dart';

import '../../Common/navigation_menu.dart';
import '../../Data/models/QuizQuestions.dart';
import '../../Data/repositories/authentication/authentication_repository.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/text_string.dart';

class PersonalityQuizPage extends StatefulWidget {
  const PersonalityQuizPage({super.key});
  @override
  State<PersonalityQuizPage> createState() => _PersonalityQuizPageState();
}

class _PersonalityQuizPageState extends State<PersonalityQuizPage>
    with SingleTickerProviderStateMixin {
  // ── batching ───────────────────────────────────────────────────────
  final PersonalityQuizController controller = PersonalityQuizController();
  static const int batchSize = 10;
  int currentBatch = 0; // 0-based
  int slideDirection = 1; // 1 = next, −1 = back
  bool showInfo = true;

  int get numBatches => (questionList.length / batchSize).ceil();
  List<int> get batchIndices {
    final start = currentBatch * batchSize;
    final end = ((currentBatch + 1) * batchSize).clamp(0, questionList.length);
    return List.generate(end - start, (i) => start + i);
  }

  bool get batchComplete =>
      batchIndices.every((i) => questionList[i].type == 0 || (questionList[i].answer ?? 0) >= 1);
  double get progress =>
      questionList.where((q) => q.type == 0 || (q.answer ?? 0) >= 1).length /
      questionList.length;

  // ── controllers ────────────────────────────────────────────────────
  ScrollController? _scroll; // nullable & swappable
  ScrollController _makeController(double offset) =>
      ScrollController(initialScrollOffset: offset);

  late final AnimationController _shakeCtrl;
  late final Animation<double> _shake;

  // ── init / dispose ────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    controller.initAnswers();

    _scroll = _makeController(0); // start first batch at top

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addStatusListener((s) {
      if (s == AnimationStatus.completed) _shakeCtrl.value = 0;
    });

    _shake = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 14.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 14.0, end: -14.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -14.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _scroll?.dispose();
    super.dispose();
  }

  // ── navigation helpers ────────────────────────────────────────────
  Future<void> _animateScroll(double to) => _scroll!.animateTo(
    to,
    duration: const Duration(milliseconds: 350),
    curve: Curves.easeInOut,
  );

  Future<void> _next() async {
    if (!batchComplete) {
      _shakeCtrl.forward(from: 0);
      return;
    }
    if (currentBatch >= numBatches - 1) return;

    slideDirection = 1;
    await _animateScroll(_scroll!.position.maxScrollExtent); // scroll to bottom
    setState(() {
      currentBatch++;
      _scroll = _makeController(0); // new list at top
    });
  }

  Future<void> _back() async {
    if (currentBatch == 0) return;

    slideDirection = -1;

    // 1️⃣ Scroll current batch to the top first (for a clean slide start)
    await _animateScroll(0);

    // 2️⃣ Replace controller that starts at TOP (offset 0)
    _scroll = _makeController(0);

    // 3️⃣ Flip to previous batch (will slide down from top)
    setState(() => currentBatch--);

    // 4️⃣ After the slide animation ends (500 ms), jump to bottom
    Future.delayed(const Duration(milliseconds: 5), () {
      if (_scroll!.hasClients) {
        _scroll!.jumpTo(_scroll!.position.maxScrollExtent);
      }
    });
  }

  void _exitQuiz() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Exit Quiz?'),
            content: const Text(
              'Are you sure you want to exit? You can choose to save or not to save.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => {
                  _exit(),
                  Get.offAll(() => NavigationMenu())
                }, child: const Text('Exit', style: TextStyle(color: Colors.red)),
              ),
              TextButton(
                onPressed:
                    () => {
                      Get.offAll(() => NavigationMenu()),
                      controller.submitQuiz(),
                    },
                child: const Text('Exit and Save', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (shouldExit == true) {
      Navigator.of(
        context,
      ).pop(); // You may want to replace this with your own navigation
    }
  }

  void _submit() {
    if (!batchComplete) {
      _shakeCtrl.forward(from: 0);
      return;
    }
    controller.submitQuiz();
  }

  void _exit() {
    controller.initAnswers();
  }

  // ── build ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final accent = TColors.primary;

    // shared nav-button style (uniform size)
    final navBtnStyle = ElevatedButton.styleFrom(
      minimumSize: const Size(120, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
    );

    return Scaffold(
      appBar: TopBar(),
      body: Column(
        children: [
          // ── info banner ──
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: showInfo ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    TColors.primary.withOpacity(0.1),
                    TColors.secondary.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: TColors.primary.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: TColors.primary.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.info_outline,
                      size: 20,
                      color: TColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Text Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          TTexts.quizTitle,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: TColors.primary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          TTexts.quizUnder,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.black54,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Close Button
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => setState(() => showInfo = false),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: TColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.black45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            secondChild: const SizedBox(height: 0),
          ),

          // ── progress bar & divider ──
          Material(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text('Page ${currentBatch + 1} of $numBatches'),
                      const Spacer(),
                      Text(
                        '${(progress * 100).round()}% complete',
                        style: TextStyle(color: accent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: progress),
                    duration: const Duration(milliseconds: 400),
                    builder:
                        (_, v, __) => ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: v,
                            minHeight: 8,
                            backgroundColor: Colors.grey[300],
                            color: accent,
                          ),
                        ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.black12, height: 1)
                ],
              ),
            ),
          ),

          // ── stacked batch list ──
          Expanded(
            child: ClipRect(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (child, anim) {
                  final inFrom =
                      slideDirection == 1
                          ? const Offset(0, 1)
                          : const Offset(0, -1);
                  final outTo =
                      slideDirection == 1
                          ? const Offset(0, -1)
                          : const Offset(0, 1);
                  final incoming = child.key == ValueKey(currentBatch);

                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: incoming ? inFrom : Offset.zero,
                      end: incoming ? Offset.zero : outTo,
                    ).animate(incoming ? anim : ReverseAnimation(anim)),
                    child: child,
                  );
                },
                child: ListView.separated(
                  key: ValueKey(currentBatch),
                  controller: _scroll!,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                  physics: const BouncingScrollPhysics(),
                  separatorBuilder: (_, __) => const SizedBox(height: 28),
                  itemCount: batchIndices.length,
                  itemBuilder: (_, i) {
                    final idx = batchIndices[i];
                    final q = questionList[idx];
                    final answered = (q.answer != null && q.answer != '' && q.answer != 0);

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: TColors.primary.withOpacity(.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Q${idx + 1}',
                                    style: TextStyle(color: TColors.primary),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    q.title,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                if (answered)
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (q.type == 0) // Free-response question
                              TextField(
                                controller: controller.textControllers[q.key],
                                onChanged: (value) {
                                  setState(() {
                                    q.answer = value; // Update the answer directly
                                    controller.setAnswer(idx, value); // Update controller if needed
                                  });
                                },
                                decoration: InputDecoration(
                                  hintText: 'Enter your response...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                ),
                                maxLines: 3, // Allow multi-line input
                                maxLength: 255,
                              )
                            else // Multiple-choice question
                              Row(
                                children: List.generate(7, (n) {
                                  final sel = q.answer == n + 1;
                                  return Expanded(
                                    child: InkWell(
                                      onTap: () => setState(() => controller.setAnswer(idx, n + 1)),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 150),
                                        margin: const EdgeInsets.symmetric(horizontal: 1),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: sel ? TColors.primary : Colors.grey[200],
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(n == 0 ? 16 : 4),
                                            bottomLeft: Radius.circular(n == 0 ? 16 : 4),
                                            topRight: Radius.circular(n == 6 ? 16 : 4),
                                            bottomRight: Radius.circular(n == 6 ? 16 : 4),
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${n + 1}',
                                            style: TextStyle(
                                              color: sel ? Colors.white : Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // ── navigation bar ──
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: Row(
              children: [
                if (currentBatch == 0)
                  // On first page, only show Exit (pushed left)
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(80, 38),
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red[600],
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: const BorderSide(
                            color: Color(0xFFD32F2F),
                            width: 1.2,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: _exitQuiz,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.close,
                              size: 18,
                              color: Color(0xFFD32F2F),
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Exit',
                              style: TextStyle(color: Color(0xFFD32F2F)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (currentBatch == numBatches - 1)
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(80, 38),
                          backgroundColor: Colors.white,
                          foregroundColor: TColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),

                          padding: EdgeInsets.zero,
                        ),
                        onPressed: _back,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.arrow_back_ios_new, size: 18),
                            SizedBox(width: 5),
                            Text('Back'),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  // Pills: Back | Exit
                  Expanded(
                    flex: 2,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Back Button (Left pill)
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(80, 38),
                              backgroundColor: Colors.white,
                              foregroundColor: TColors.primary,
                              elevation: 0,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  bottomLeft: Radius.circular(12),
                                  topRight: Radius.circular(0),
                                  bottomRight: Radius.circular(0),
                                ),
                              ),
                              side: BorderSide(
                                color: TColors.primary.withOpacity(.3),
                                width: 1.2,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: _back,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.arrow_back_ios_new, size: 18),
                                SizedBox(width: 5),
                                Text('Back'),
                              ],
                            ),
                          ),
                        ),
                        // Vertical Divider (thin, subtle)
                        Container(
                          width: 1,
                          height: 38,
                          color: TColors.primary.withOpacity(.09),
                        ),
                        // Exit (Right pill)
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(80, 38),
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red[600],
                              elevation: 0,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(0),
                                  bottomLeft: Radius.circular(0),
                                  topRight: Radius.circular(14),
                                  bottomRight: Radius.circular(14),
                                ),
                              ),
                              side: const BorderSide(
                                color: Color(0xFFD32F2F),
                                width: 1.2,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: _exitQuiz,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.close,
                                  size: 18,
                                  color: Color(0xFFD32F2F),
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'Exit',
                                  style: TextStyle(color: Color(0xFFD32F2F)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                Expanded(
                  flex: 1,
                  child: Container(),
                ), // Spacing to the next/submit button
                // Right: Next or Submit (rightCenteredButton pattern)
                Expanded(
                  flex: 1,
                  child: rightCenteredButton(
                    label: currentBatch < numBatches - 1 ? 'Next' : 'Submit',
                    icon:
                        currentBatch < numBatches - 1
                            ? Icons.arrow_forward_ios
                            : Icons.check,
                    onPressed: currentBatch < numBatches - 1 ? _next : _submit,
                    enabled: batchComplete,
                    accent: TColors.primary,
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
