
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:hey_you/utils/constants/api_constants.dart';
import 'package:http/http.dart' as http;

import '../../models/UserModel.dart';

/// Global Current user Variable
UserModel currentUser = UserModel.initial();

class UserRepository extends GetxController{
  static UserRepository get instance => Get.find();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveUserRecord(UserModel user) async {
    print('Printing user: $user');
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
      print(e);
      throw 'Please try again.';
    }
  }

  Future<void> updateUserField(UserModel user, String field, dynamic value) async {
    try{
      await _db.collection('Users').doc(user.id).update({
        field: value
      });
    } catch (e) {
      print('Could not update: $field');
    }
  }

  /// Sends API Call to update the current location of the user
  Future<void> updateLocation(Position pos) async {

    final url = Uri.parse(APIConstants.updateLocation);

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'user_id': FirebaseAuth.instance.currentUser!.uid,
        'geolocation': {
          'lat': pos.latitude,
          'long': pos.longitude
        }
      })
    );

    print("update location response");
    print(response.body);
  }
}