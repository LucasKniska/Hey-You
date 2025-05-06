import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hey_you/Common/topbar.dart';
import 'package:hey_you/Data/models/CurrentMatch.dart';
import 'package:hey_you/Data/repositories/user/user_repository.dart';
import 'BottomSheet.dart';
import 'MatchPopup.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {


  Future<CurrentMatch?> loadCurrentMatch(String matchId) async {
    final doc = await FirebaseFirestore.instance
        .collection('Matches')
        .doc(matchId)
        .get();

    if (doc.exists) {
      CurrentMatch current = CurrentMatch.fromJson(doc.data()!);

      return current;
    }

    return null;
  }

  Timer? matchTimer;

  Future<void> _openModificationSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom, // fixes keyboard overlap
          ),
          child: const ModificationBottomSheet(), // No need to change your widget
        );
      },
    );
    Get.put(UserRepository());
    UserRepository.instance.saveUserRecord(currentUser);
  }

  @override
  Widget build(BuildContext context) {

    FirebaseFirestore.instance.collection('Users').doc(currentUser.id).snapshots().listen((snapshot) async {

      final currentMatch = snapshot.data()?['CurrentMatch'];
      if (currentMatch != null && currentMatch != '') {

        CurrentMatch? current = await loadCurrentMatch(currentMatch);

        if(current == null) return;

        int user = 0;

        if(current.userData[user].id == currentUser.id) {
          user = 1;
        }

        final expiration = current.expirationTime;
        final Rx<Duration> countdown = expiration.difference(DateTime.now()).obs;
        matchTimer?.cancel(); // Cancel any existing timer
        matchTimer = Timer.periodic(Duration(seconds: 1), (t) {
          final newRemaining = expiration.difference(DateTime.now());
          countdown.value = newRemaining;
          if (newRemaining <= Duration.zero) {
            t.cancel();
            matchTimer = null;
          }
        });

        Get.snackbar(
            'New Match!',
            'You matched with ${current.userData[user].userName} Tap to view.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.blue,
            colorText: Colors.white,
            duration: const Duration(seconds: 8),
            onTap: (snack) {

              try{
                if(current.id != ''){
                  Get.dialog(
                    MatchPopup(
                      current: current,
                    ),
                  );
                }

              } catch(e){}


            }
        );
      }
    });



  return Scaffold(
      appBar: const TopBar(),
      body: Container(
        color: Colors.black12,
        alignment: Alignment.center,
        child: const Text('Waiting for new connections...'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openModificationSheet,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.settings),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
