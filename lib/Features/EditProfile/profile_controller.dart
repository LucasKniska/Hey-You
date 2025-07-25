import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

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

    final currentUser = UserRepository.instance.currentUser;

    biography.text = currentUser.biography;
    permanentMods.assignAll(currentUser.permanentModifications);
    temporaryMods.assignAll(currentUser.temporaryModifications.map((e) => e.modification));
  }

  void updateMods() {
    final currentUser = UserRepository.instance.currentUser;
    biography.text = currentUser.biography;
    permanentMods.assignAll(currentUser.permanentModifications);
    temporaryMods.assignAll(currentUser.temporaryModifications.map((e) => e.modification));
  }

  void saveBiography() {
    final currentUser = UserRepository.instance.currentUser;
    if (!editBiography.value) {
      currentUser.biography = biography.text;
      UserRepository.instance.updateUserField('Biography', currentUser.biography);
    }
  }

  void deleteModification({required String description, required bool permanent}) {
    final currentUser = UserRepository.instance.currentUser;
    if (permanent) {
      permanentMods.remove(description);
      currentUser.permanentModifications.remove(description);
    } else {
      temporaryMods.remove(description);
      currentUser.temporaryModifications.removeWhere((e) => e.modification == description);
    }

  }
}
