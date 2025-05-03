import 'package:flutter/material.dart';
import 'package:hey_you/utils/constants/colors.dart';
import '../../Data/repositories/connections/ScheduledMatch.dart';
import '../../utils/constants/sizes.dart';
import '../../utils/constants/text_string.dart';

class ScheduledConnections extends StatefulWidget {
  const ScheduledConnections({super.key});

  @override
  State<ScheduledConnections> createState() => _PreviousConnection();
}

class _PreviousConnection extends State<ScheduledConnections> {

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [


        ListView.builder(
          shrinkWrap: true,
          physics:
          NeverScrollableScrollPhysics(), // Prevents scrolling inside a Column
          itemCount: scheduledMatches.length, // Previous matches from data section
          itemBuilder: (context, index) {
            return _ConnectionRow(match: scheduledMatches[index]);
          },
        ),
      ],
    );
  }
}

class _ConnectionRow extends StatelessWidget {
  final ScheduledMatch match;

  const _ConnectionRow({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          connectionTitle(TTexts.scheduledConnectionDateDetails(match.createdOn), context),
          previousCard(TTexts.scheduledConnectionUserDetails(match), context),
          SizedBox(height: TSizes.spaceBtwItems)
        ]
    );
  }


  Widget connectionTitle(String text, BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall,
    );
  }

  Widget previousCard(String text, BuildContext context) {
    return Card(
      color: TColors.secondary,
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
