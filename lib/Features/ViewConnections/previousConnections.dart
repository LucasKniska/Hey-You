import 'package:flutter/material.dart';

import '../../Data/repositories/connections/PreviousMatch.dart';
import '../../utils/constants/sizes.dart';
import '../../utils/constants/text_string.dart';

class PreviousConnection extends StatefulWidget {
  const PreviousConnection({super.key});

  @override
  State<PreviousConnection> createState() => _PreviousConnection();
}

class _PreviousConnection extends State<PreviousConnection> {

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [


        ListView.builder(
          shrinkWrap: true,
          physics:
              NeverScrollableScrollPhysics(), // Prevents scrolling inside a Column
          itemCount: previousMatches.length, // Previous matches from data section
          itemBuilder: (context, index) {
            return _ConnectionRow(match: previousMatches[index]);
          },
        ),
      ],
    );
  }
}

class _ConnectionRow extends StatelessWidget {
  final PreviousMatch match;

  const _ConnectionRow({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        connectionTitle(TTexts.previousConnectionDateDetails(match.connectedOn, match.location['title']!), context),
        previousCard(TTexts.previousConnectionUserDetails(match), context),
        SizedBox(height: TSizes.spaceBtwItems)
      ]
    );
  }


  Widget connectionTitle(String text, BuildContext context) {
    return Text(
      text,
        style: Theme.of(context).textTheme.bodySmall
    );
  }

  Widget previousCard(String text, BuildContext context) {
    return Card(
      color: Colors.grey,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(
          text,
            style: Theme.of(context).textTheme.bodyMedium
        ),
        trailing: Icon(Icons.arrow_drop_down, color: Colors.white),
      ),
    );
  }
}
