import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../Data/repositories/user/user_repository.dart';

class ProfileController extends GetxController {
  static ProfileController get instance => Get.find();

  final currentUser = UserRepository.instance.currentUser;
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
    biography.text = currentUser.biography;
    permanentMods.assignAll(currentUser.permanentModifications);
    temporaryMods.assignAll(currentUser.temporaryModifications.map((e) => e.modification));
  }

  void saveBiography() {
    if (!editBiography.value) {
      currentUser.biography = biography.text;
      UserRepository.instance.updateUserField('Biography', currentUser.biography);
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

  }
}
