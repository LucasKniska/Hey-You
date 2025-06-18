import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hey_you/Features/ViewConnections/controllers/previousConnections_controller.dart';

import '../../Data/models/PreviousMatch.dart';
import '../../utils/constants/sizes.dart';

class PreviousConnection extends StatefulWidget {
  const PreviousConnection({super.key});

  @override
  State<PreviousConnection> createState() => _PreviousConnection();
}

class _PreviousConnection extends State<PreviousConnection> {

  final PreviousConnectionController controller = PreviousConnectionController();
  List<PreviousMatch> previousMatches = [];

  @override
  void initState() {
    super.initState();
    fetchPreviousMatches(); // Call async function
  }

  Future<void> fetchPreviousMatches() async {
    try {
      final matches = await controller.getPreviousMatches();
      setState(() {
        previousMatches = matches;
      });
    } catch (e) {
      print("Error fetching previous matches: $e");
    }
  }

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
        connectionTitle(match.previousConnectionDateDetails(), context),
        previousCard(match.previousConnectionUserDetails(), context),
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
