import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../Data/TemporaryModifications.dart';
import '../../Data/repositories/user/user_repository.dart';
import '../../utils/theme/snackbars.dart';


class ModificationFullSheet extends StatefulWidget {
  const ModificationFullSheet({super.key});

  @override
  State<ModificationFullSheet> createState() => _ModificationFullSheetState();
}

class _ModificationFullSheetState extends State<ModificationFullSheet> {
  final TextEditingController _controller = TextEditingController();
  int _selectedType = 0;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    final textTheme = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [

        // FULL SCREEN MODAL SHEET
        Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedContainer(
            duration: 300.ms,
            curve: Curves.ease,
            width: size.width,
            height: size.height * 0.90,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                  offset: Offset(0, -4),
                )
              ],
            ),
            child: SafeArea(
              top: false,
              bottom: false,
              child: Column(
                children: [
                  // Drag handle
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0, bottom: 16),
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  // Title and subtitle
                  Text('Add Filter',
                      style: textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold)),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 6.0),
                    child: Text(
                      'Custom preferences help us match you better!',
                      style: textTheme.bodyMedium!.copyWith(color: Colors.black54),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Input field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: TextField(
                      controller: _controller,
                      maxLength: 40,
                      decoration: InputDecoration(
                        hintText: 'e.g., "Other Computer Science Majors"',
                        labelText: 'Enter Filter',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        prefixIcon: Icon(Icons.edit_note_rounded),
                        counterText: '',
                      ),
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _addModification(context),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Segmented control with better spacing
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: CupertinoSegmentedControl<int>(
                      borderColor: primary,
                      selectedColor: primary,
                      unselectedColor: Colors.white,
                      children: {
                        0: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.today_rounded,
                                  color: _selectedType == 0 ? Colors.white : primary, size: 18),
                              SizedBox(width: 6),
                              Text("Daily",
                                style: TextStyle(
                                    color: _selectedType == 0 ? Colors.white : primary,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        1: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.push_pin_rounded,
                                  color: _selectedType == 1 ? Colors.white : primary, size: 18),
                              SizedBox(width: 6),
                              Text("Permanent",
                                style: TextStyle(
                                    color: _selectedType == 1 ? Colors.white : primary,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      },
                      groupValue: _selectedType,
                      onValueChanged: (int val) => setState(() => _selectedType = val),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Add button with more spacing
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: AnimatedSwitcher(
                        duration: 200.ms,
                        child: _isLoading
                            ? ElevatedButton.icon(
                          key: ValueKey('loading'),
                          onPressed: null,
                          icon: SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                          label: Text('Adding...'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary.withOpacity(0.8),
                            padding: EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        )
                            : ElevatedButton.icon(
                          key: ValueKey('add'),
                          onPressed: _controller.text.trim().isEmpty ||
                              (_selectedType == 0 && currentUser.temporaryModifications.length >= 5) ||
                              (_selectedType == 1 && currentUser.permanentModifications.length >= 5)
                              ? null
                              : () => _addModification(context),
                          icon: Icon(Icons.add, size: 24, color: Colors.white),
                          label: Text(
                            'Add Filter',
                            style: textTheme.titleMedium!.copyWith(
                                color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _controller.text.trim().isEmpty ||
                                (_selectedType == 0 && currentUser.temporaryModifications.length >= 5) ||
                                (_selectedType == 1 && currentUser.permanentModifications.length >= 5)
                                ? primary.withOpacity(0.2)
                                : primary,
                            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Chips and lists
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSection(
                            icon: Icons.today_rounded,
                            title: "Daily Filters",
                            mods: currentUser.temporaryModifications.map((mod) => mod.modification).toList(),
                            color: Colors.blueAccent,
                            emptyText: "No daily filter yet!\nTry \"People in my major\"",
                            onDelete: (mod) {
                              setState(() {
                                currentUser.temporaryModifications
                                    .removeWhere((modTemp) => modTemp.modification == mod);
                              });
                            },
                          ),
                          SizedBox(height: 20),
                          _buildSection(
                            icon: Icons.push_pin_rounded,
                            title: "Permanent Filters",
                            mods: currentUser.permanentModifications,
                            color: Colors.deepPurpleAccent,
                            emptyText: "No permanent filters yet!\nTry \"Loves coffee chats\"",
                            onDelete: (mod) {
                              currentUser.permanentModifications.remove(mod);
                              setState(() {});
                            },
                          ),
                          SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _addModification(BuildContext context) async {
    final mod = _controller.text.trim();
    if (mod.isEmpty) return;
    setState(() => _isLoading = true);
    await Future.delayed(Duration(milliseconds: 450));
    setState(() {
      if (_selectedType == 0 && currentUser.temporaryModifications.length < 5) {
        currentUser.temporaryModifications.insert(0, TemporaryModification(start: DateTime.now(), modification: mod));
      } else if (_selectedType == 1 && currentUser.permanentModifications.length < 5) {
        currentUser.permanentModifications.insert(0, mod);
      } else {
        TSnackBars.errorSnackBar(title: 'Can only have 5 permanent modifications.');

      }
      _controller.clear();
      _isLoading = false;
    });
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<String> mods,
    required Color color,
    required String emptyText,
    required Function(String) onDelete,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 22),
            SizedBox(width: 7),
            Text(title,
                style: textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w700)),
            Spacer(),
            Text('${mods.length}/5', style: textTheme.bodySmall!.copyWith(color: Colors.grey)),
          ],
        ),
        SizedBox(height: 6),
        if (mods.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Icon(Icons.sentiment_satisfied_alt, color: color.withOpacity(0.6)),
                SizedBox(width: 10),
                Flexible(child: Text(emptyText, style: textTheme.bodyMedium!.copyWith(color: Colors.black38))),
              ],
            ),
          ),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: mods.map((mod) {
            return Animate(
              effects: [FadeEffect(duration: 200.ms), ScaleEffect(duration: 200.ms)],
              child: Chip(
                avatar: Icon(icon, color: color, size: 16),
                label: Text(mod, style: textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w500)),
                deleteIcon: Icon(Icons.close, size: 18),
                onDeleted: () => onDelete(mod),
                backgroundColor: color.withOpacity(0.1),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: color.withOpacity(0.25)),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
