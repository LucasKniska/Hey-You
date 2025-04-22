import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../Data/repositories/user/user_repository.dart';


class ProfileController extends GetxController{

  static ProfileController get instance => Get.find();


  final biography = new TextEditingController();
  final editBiography = false.obs;

  GlobalKey<FormState> changeBioKey = GlobalKey<FormState>();

  final obsForChips = false.obs;

  @override
  void onInit() {
    // Set biography value
    try{
      biography.text = currentUser.biography!;
    } catch (e) {
      biography.text = '';
    }
  }

  void saveBiography(){
    if(editBiography.value){
      currentUser.biography = biography.text;
    }
  }



  void deleteModification({required String description, required bool permanent}){
    if(permanent){
      currentUser.permanentModifications!.remove(description);
    } else {
      currentUser.temporaryModifications!.removeWhere((e) => e['modifications'] == description);
    }
  }


}