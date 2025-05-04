
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../models/CurrentMatch.dart';

class MatchRepository extends GetxController {
  static MatchRepository get instance => Get.find();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveCurrentMatchRecord(CurrentMatch current) async {
    try{
      await _db.collection('Matches').doc(current.id).set(current.toJson());
    } catch (e) {
      throw 'Something went wrong saving current match.';
    }
  }
}