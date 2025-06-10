import 'package:flutter/material.dart';
import 'package:hey_you/Common/styles/spacing_styles.dart';
import 'package:hey_you/Data/TemporaryModifications.dart';
import 'package:hey_you/Data/repositories/user/user_repository.dart';
import 'package:hey_you/utils/constants/sizes.dart';
import 'package:hey_you/utils/theme/snackbars.dart';

class ModificationBottomSheet extends StatefulWidget {
  const ModificationBottomSheet({super.key});

  @override
  _ModificationBottomSheetState createState() => _ModificationBottomSheetState();
}

class _ModificationBottomSheetState extends State<ModificationBottomSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode(); // For tracking focus
  bool _isPermanent = true; // Toggle between Temporary and Permanent

  void _addModification() {
    String text = _controller.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        if (!_isPermanent) {

          if(currentUser.temporaryModifications.length < 5) {
            currentUser.temporaryModifications.add(TemporaryModification(start: DateTime.now(), modification: text));
          } else {
            TSnackBars.errorSnackBar(title: 'Can only have 5 temporary modifications.');
          }

        } else {

          if(currentUser.permanentModifications.length < 5){
            currentUser.permanentModifications.add(text);
          } else{
            TSnackBars.errorSnackBar(title: 'Can only have 5 permanent modifications.');
          }

        }
        _controller.clear();
      });
    }
  }

  void _removeModification(String text, bool isTemporary) {
    setState(() {
      if (isTemporary) {
        currentUser.temporaryModifications.removeWhere((mod) => mod.modification==text);
      } else {
        currentUser.permanentModifications.remove(text);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose(); // Important: clean up
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: TSpacingStyle.normalPadding,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    maxLength: 40, // Set maximum characters
                    buildCounter: (BuildContext context, {int? currentLength, int? maxLength, bool? isFocused}) {
                      if (isFocused ?? false) {
                        return Text(
                          '${currentLength ?? 0}/${maxLength ?? 0}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        );
                      } else {
                        return null; // Hide counter when not focused
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Enter modification',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addModification,
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Temporary'),
                Switch(
                  value: _isPermanent,
                  onChanged: (val) {
                    setState(() {
                      _isPermanent = val;
                    });
                  },
                ),
                const Text('Permanent'),
              ],
            ),
            const SizedBox(height: 20),

            /// Temporary Modifications Section
            if (currentUser.temporaryModifications.isNotEmpty) ...[
              const Text(
                'Temporary Modifications',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 8,
                children: currentUser.temporaryModifications.map((mod) {
                  return Chip(
                    label: Text(mod.modification),
                    deleteIcon: const Icon(Icons.close),
                    onDeleted: () => _removeModification(mod.modification, true),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 20),

            /// Permanent Modifications Section
            if (currentUser.permanentModifications.isNotEmpty) ...[
              const Text(
                'Permanent Modifications',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 8,
                children: currentUser.permanentModifications.map((mod) {
                  return Chip(
                    label: Text(mod),
                    deleteIcon: const Icon(Icons.close),
                    onDeleted: () => _removeModification(mod, false),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
