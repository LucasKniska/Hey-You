
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../models/UserModel.dart';

/// Global Current user Variable
UserModel currentUser = UserModel.initial();

class UserRepository extends GetxController{
  static UserRepository get instance => Get.find();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveUserRecord(UserModel user) async {
    try{
      await _db.collection('Users').doc(user.id).set(user.toJson());
    } catch (e) {
      throw 'Something went wrong. Please try again.';
    }
  }

  Future<UserModel> getUserById(String id) async {
    try{

      DocumentSnapshot<Map<String, dynamic>> user = await _db.collection('Users').doc(id).get();

      return UserModel.fromJson(user.data()!);

    } catch (e) {
      throw 'Please try again.';
    }
  }


}