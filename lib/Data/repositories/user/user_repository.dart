
import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:hey_you/Data/models/NearbyUser.dart';
import 'package:hey_you/Data/repositories/matching/match_repository.dart';
import 'package:hey_you/utils/constants/api_constants.dart';
import 'package:http/http.dart' as http;

import '../../models/LeaderboardData.dart';
import '../../models/UserModel.dart';

class UserRepository extends GetxController {
  static UserRepository get instance => Get.find();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  StreamSubscription<DocumentSnapshot>? _userListener;
  final Rx<UserModel> _currentUser = UserModel.initial().obs;

  // Getter for accessing current user
  UserModel get currentUser => _currentUser.value;
  Rx<UserModel> get currentUserRx => _currentUser;

  Rx<bool> successfulMatch = false.obs;

  RxList<NearbyUser> nearbyUsers = <NearbyUser>[].obs;

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onClose() {
    _userListener?.cancel();
    super.onClose();
  }

  /// Call this method when user logs in to start listening to their data
  void startListeningToUser() {
    // Cancel existing listener
    _userListener?.cancel();

    print('Starting user listener');
    print('Looking for: ${FirebaseAuth.instance.currentUser!.uid}');

    _userListener = _db
        .collection('Users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .snapshots()
        .listen(
          (DocumentSnapshot snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          try {
            // Checks if the new user data includes a new connections
            UserModel nextUser = UserModel.fromJson(snapshot.data() as Map<String, dynamic>);
            if (nextUser.totalConnections != _currentUser.value.totalConnections) {
              successfulMatch.value = true;
            }
            if (nextUser.currentMatch.isNotEmpty && nextUser.currentMatch != _currentUser.value.currentMatch) {
              MatchRepository.instance.newMatchSeen = true;
            }
            // Update the current user
            _currentUser.value = nextUser;

            MatchRepository.instance.startCurrentMatchListener();
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

  Future<void> createNewUser(UserModel user) async {
    final url = Uri.parse(APIConstants.createNewUser);

    var payload = user.toJson();
    
    await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
  }

  Future<void> updateQuestionAnswers({var quizAnswers=null}) async {
    final url = Uri.parse(APIConstants.updateQuestionAnswers);

    Map<String, dynamic> payload;
    if(quizAnswers == null){
      payload = {
        'user_id': currentUser.id,
        'question_answers': currentUser.quizAnswers,
      };
    } else {
      payload = {
        'user_id': currentUser.id,
        'question_answers': quizAnswers
      };
    }

    print('Update question answers payload: $payload');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw TimeoutException('Request timed out after 20 seconds');
        },
      );
      print(response.statusCode);
      if (response.statusCode != 200) {
        print('Error 134 User Repo');
        throw Exception('Failed to update: ${response.body}');
      }

      print('138 User Repo Response Body: ${response.body}');
      final body = json.decode(response.body);
      if (body['error'] != null) {
        print('Error: ${body['error']}, 139 User Repo');
        throw Exception(body['error']);
      }
    } catch (e) {
      print('Error: 143 User Repo');
      throw Exception('Something went wrong: $e');
    }
  }

  Future<void> updateUserField(String field, dynamic value) async {

    final url = Uri.parse(APIConstants.updateUserField);

    print('Current User: ');
    print(FirebaseAuth.instance.currentUser!.uid);

    var payload = {
      'user_id': FirebaseAuth.instance.currentUser!.uid,
      'field': field,
      'value': value
    };

    await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
  }

  Future<void> updateUserSearchFilters() async {
    final url = Uri.parse(APIConstants.updateSearchFilters);

    final payload = {
      'user_id': currentUser.id,
      'temporary_modifications': currentUser.temporaryModifications,
      'permanent_modifications': currentUser.permanentModifications
    };

    await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload),
    );
  }

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
  }

  Future<LBRankings> fetchRankings() async {
    final uri = Uri.parse('${APIConstants.getBucketRankings}?bucket_id=${currentUser.bucketName}');

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Failed to load leaderboard: ${res.statusCode}');
    }
    final Map<String, dynamic> data = json.decode(res.body);
    if (data['error'] != null) throw Exception(data['error']);
    return LBRankings.fromJson(data);
  }

  Future<void> updateUsersNearMe() async {
    final uri = Uri.parse('${APIConstants.getUserNearMe}?user_id=${FirebaseAuth.instance.currentUser!.uid}');

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Failed to load names: ${res.statusCode}');
    }

    final data = json.decode(res.body);

    final List<String> users = List<String>.from(data['users']);
    final List<double> distances = List<double>.from(data['distances']);

    final List<NearbyUser> userList = [];

    for (int i = 0; i < users.length; i++) {
      userList.add(NearbyUser(
        username: users[i],
        distance: distances[i],
      ));
    }

    nearbyUsers.value = userList;

  }
}
