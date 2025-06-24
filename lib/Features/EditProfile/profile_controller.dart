import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

import '../../Data/repositories/user/user_repository.dart';

class ProfileController extends GetxController {
  static ProfileController get instance => Get.find();

  final biography = TextEditingController();
  final editBiography = false.obs;

  final permanentMods = <String>[].obs;
  final temporaryMods = <String>[].obs;

  @override
  void onInit() {
    super.onInit();

    biography.text = currentUser.biography;

    permanentMods.assignAll(currentUser.permanentModifications);
    temporaryMods.assignAll(currentUser.temporaryModifications.map((e) => e.modification));
  }

  void updateMods() {
    print('updating modifications');
    biography.text = currentUser.biography;
    permanentMods.assignAll(currentUser.permanentModifications);
    temporaryMods.assignAll(currentUser.temporaryModifications.map((e) => e.modification));
    print(temporaryMods);
  }

  void saveBiography() {
    if (!editBiography.value) {
      currentUser.biography = biography.text;
      UserRepository.instance.updateUserField(currentUser, 'Biography', currentUser.biography);
    }
  }

  void deleteModification({required String description, required bool permanent}) {
    if (permanent) {
      permanentMods.remove(description);
      currentUser.permanentModifications.remove(description);
    } else {
      temporaryMods.remove(description);
      currentUser.temporaryModifications.removeWhere((e) => e.modification == description);
    }

    // Optional: persist user
    UserRepository.instance.saveUserRecord(currentUser);
  }
}
