import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:scraper/app/modules/home/controllers/home_controller.dart';

import 'app/routes/app_pages.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // if (!kIsWeb) {
  //   await DesktopWindow.setWindowSize(Size(700, 500));
  //   await DesktopWindow.setMinWindowSize(Size(600, 400));
  //   await DesktopWindow.setMaxWindowSize(Size(800, 600));
  // }

  runApp(
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
      onInit: () {
        Get.lazyPut(() => HomeController(), fenix: true);
      },
      initialRoute: AppPages.INITIAL,
      defaultTransition: Transition.cupertino,
      getPages: AppPages.routes,
    ),
  );
}
