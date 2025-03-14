import 'package:flutter/material.dart';
import 'package:hey_you/topbar.dart';
import 'bottombar.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPage();
}

class _MapPage extends State<MapPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopBar(),
      body: Center(

        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[

                Expanded(
                    child: Container(
                        height: 1000,
                        color: Colors.black12,
                        alignment: Alignment.center,
                        child: Text(
                            "Map Area"
                        )
                    )
                )

              ],
            ),
            Positioned(
              right: 16, // Position FAB to the right
              bottom: 16, // Position FAB to the bottom
              child: FloatingActionButton(
                onPressed: () {
                  // Action when FAB is pressed
                },
                backgroundColor: Colors.blue,
                child: Icon(Icons.settings),
              ),
            ),
          ]
        )
      ),

      bottomNavigationBar: BottomBar(),

    );
  }
}