import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'Common/location_services.dart';
import 'Data/repositories/authentication/authentication_repository.dart';
import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {

  /// Widgets Binding
  final WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  /// Init Local Storage
  await GetStorage.init();

  /// Await Splash Until Other Items Load
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform).then(
      (FirebaseApp value) => Get.put(AuthenticationRepository()),
  );

  Get.put(LocationController());

  runApp(const MyApp());
}


