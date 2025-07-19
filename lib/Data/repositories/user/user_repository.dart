
import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:hey_you/utils/constants/api_constants.dart';
import 'package:http/http.dart' as http;

import '../../models/UserModel.dart';


class UserRepository extends GetxController {
  static UserRepository get instance => Get.find();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot>? _userListener;

  // Make currentUser a reactive field of the repository
  final Rx<UserModel> _currentUser = UserModel.initial().obs;

  // Getter for accessing current user
  UserModel get currentUser => _currentUser.value;

  // Reactive getter for widgets
  Rx<UserModel> get currentUserRx => _currentUser;

  @override
  void onInit() {
    super.onInit();
    // Start listening when the controller is initialized
    _startUserListener();
  }

  @override
  void onClose() {
    // Cancel the listener when the controller is disposed
    _userListener?.cancel();
    super.onClose();
  }

  /// Sets up a real-time listener for the current user
  void _startUserListener() {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null) {
      _userListener = _db
          .collection('Users')
          .doc(userId)
          .snapshots()
          .listen(
            (DocumentSnapshot snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            try {
              // Update the current user
              _currentUser.value = UserModel.fromJson(snapshot.data() as Map<String, dynamic>);

              print('Current user updated: ${_currentUser.value.id}');
            } catch (e) {
              print('Error updating current user: $e');
            }
          }
        },
        onError: (error) {
          print('Error listening to user changes: $error');
        },
      );
    }
  }

  /// Call this method when user logs in to start listening to their data
  void startListeningToUser(String userId) {
    // Cancel existing listener
    _userListener?.cancel();

    _userListener = _db
        .collection('Users')
        .doc(userId)
        .snapshots()
        .listen(
          (DocumentSnapshot snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          try {
            _currentUser.value = UserModel.fromJson(snapshot.data() as Map<String, dynamic>);
            _currentUser.value.id = FirebaseAuth.instance.currentUser!.uid;
            print('Current user updated: ${_currentUser.value.id}');
          } catch (e) {
            print('Error updating current user: $e');
          }
        }
      },
      onError: (error) {
        print('Error listening to user changes: $error');
      },
    );
  }

  /// Call this method when user logs out to stop listening
  void stopListeningToUser() {
    _userListener?.cancel();
    _userListener = null;
    _currentUser.value = UserModel.initial(); // Reset to initial state
  }

  /// Helper method to update current user locally (useful for immediate UI updates)
  void updateCurrentUser(UserModel user) {
    _currentUser.value = user;
  }

  Future<void> saveUserRecord(UserModel user) async {
    print('Printing user: $user');
    try {
      await _db.collection('Users').doc(user.id).set(user.toJson());
      // Optionally update current user if it's the same user
      if (user.id == currentUser.id) {
        _currentUser.value = user;
      }
    } catch (e) {
      throw Exception('Something went wrong: $e');
    }
  }

  Future<void> updateQuestionAnswers() async {
    final url = Uri.parse(APIConstants.updateQuestionAnswers);

    final payload = {
      'user_id': currentUser.id,
      'question_answers': currentUser.quizAnswers,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timed out after 10 seconds');
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update: ${response.body}');
      }
      final body = json.decode(response.body);
      if (body['error'] != null) {
        throw Exception(body['error']);
      }
    } catch (e) {
      throw Exception('Something went wrong: $e');
    }
  }

  Future<UserModel> getUserById(String id) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> user =
      await _db.collection('Users').doc(id).get();
      return UserModel.fromJson(user.data()!);
    } catch (e) {
      print(e);
      throw 'Please try again.';
    }
  }

  Future<void> updateUserField(String field, dynamic value) async {

    try {
      await _db.collection('Users').doc(currentUser.id).update({
        field: value
      });
      // Note: The listener will automatically update currentUser when this change occurs
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
          'user_id': currentUser.id, // Now using the repository's currentUser
          'geolocation': {
            'lat': pos.latitude,
            'long': pos.longitude
          }
        }));

    print("update location response");
    print(response.body);
  }
}
