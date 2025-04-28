import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hey_you/Common/topbar.dart';
import 'package:hey_you/Data/repositories/user/user_repository.dart';
import 'BottomSheet.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {


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
    return Scaffold(
      appBar: const TopBar(),
      body: Container(
        color: Colors.black12,
        alignment: Alignment.center,
        child: const Text("Map Area"),
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
