import 'package:flutter/material.dart';

class WantsMatch extends StatefulWidget {
  const WantsMatch({super.key});

  @override
  State<WantsMatch> createState() => _wantsMatch();
}

class _wantsMatch extends State<WantsMatch> {
  List<String> names = ['Carmelo Kniska'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        Text(
            "Possible Match: ",
            style: TextStyle(
              fontSize: 24,
            )
        ),

        ListView.builder(
          shrinkWrap: true,
          physics:
          NeverScrollableScrollPhysics(), // Prevents scrolling inside a Column
          itemCount: names.length,
          itemBuilder: (context, index) {
            return _wantsMatchRow(name: names[index]);
          },
        ),
      ],
    );
  }
}

class _wantsMatchRow extends StatelessWidget {
  final String name;

  const _wantsMatchRow({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        border: Border.all(color: Colors.blueGrey, width: 2),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(name, style: TextStyle(fontSize: 24))),
          Container(
            width: 6, // Set the width to 2 pixels
            color: Color(
              0xFF607D8B,
            ), // Gray-blue color (you can customize the hex color)
            height: 24,
          ),
          Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.center,
                child: Text("93% Match", style: TextStyle(fontSize: 24)),

              )
          )

        ],
      ),
    );
  }
}