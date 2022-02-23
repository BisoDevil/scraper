import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:scraper/app/routes/app_pages.dart';

import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 50,
        title: Text('Landline Scrapper by innovationcodes'),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () {
              Get.toNamed(Routes.SETTINGS);
            },
            icon: Icon(
              Icons.settings,
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(
          Icons.play_arrow_outlined,
        ),
        onPressed: () async {
          controller.startWeb();
          // for (var i = 0; i < 10; i++) {
          //   Scrapper.scraperWe("code", "phone");
          // }
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: GetBuilder<HomeController>(
                        initState: (_) {},
                        builder: (_) {
                          return TextFormField(
                            expands: true,
                            maxLines: null,
                            minLines: null,
                            controller: TextEditingController(
                                text: controller.phoneText),
                            textAlign: TextAlign.start,
                            textAlignVertical: TextAlignVertical.top,
                            onChanged: (value) {
                              controller.phoneText = value;
                            },
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          GetBuilder<HomeController>(
                            initState: (_) {},
                            builder: (_) {
                              return TextFormField(
                                readOnly: true,
                                controller: TextEditingController(
                                    text: controller.file?.path),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  suffixIcon: TextButton.icon(
                                    onPressed: () {
                                      controller.pickFile();
                                    },
                                    icon: Icon(Icons.file_upload),
                                    label: Text(
                                      "Load File",
                                      style: Get.textTheme.button.copyWith(
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          SizedBox(
                            height: 8,
                          ),
                          GetBuilder<HomeController>(
                            builder: (_) {
                              return CheckboxListTile(
                                value: controller.allowWe,
                                title: Text("We"),
                                onChanged: (value) {
                                  controller.allowWe = value;
                                  controller.update();
                                },
                              );
                            },
                          ),
                          GetBuilder<HomeController>(
                            builder: (_) {
                              return CheckboxListTile(
                                value: controller.allowVodafone,
                                title: Text("Vodafone"),
                                onChanged: (value) {
                                  controller.allowVodafone = value;
                                  controller.update();
                                },
                              );
                            },
                          ),
                          GetBuilder<HomeController>(
                            builder: (_) {
                              return CheckboxListTile(
                                value: controller.allowVodafoneSecondStep,
                                title: Text("Vodafone Second Step"),
                                onChanged: (value) {
                                  controller.allowVodafoneSecondStep = value;
                                  controller.update();
                                },
                              );
                            },
                          ),
                          GetBuilder<HomeController>(
                            builder: (_) {
                              return CheckboxListTile(
                                value: controller.allowEtisalat,
                                title: Text("Etisalat"),
                                onChanged: (value) {
                                  controller.allowEtisalat = value;
                                  controller.update();
                                },
                              );
                            },
                          ),
                          GetBuilder<HomeController>(
                            builder: (_) {
                              return CheckboxListTile(
                                value: controller.allowOrange,
                                title: Text("Orange"),
                                onChanged: (value) {
                                  controller.allowOrange = value;
                                  controller.update();
                                },
                              );
                            },
                          ),
                          GetBuilder<HomeController>(
                            builder: (_) {
                              return CheckboxListTile(
                                value: controller.allowArdy,
                                title: Text("Ardy"),
                                onChanged: (value) {
                                  controller.allowArdy = value;
                                  controller.update();
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Row(
              children: [
                Expanded(
                  child: Obx(
                    () => LinearProgressIndicator(
                      minHeight: 10,
                      value: controller.progress.value,
                      backgroundColor: Colors.grey[300],
                      color: Colors.blue,
                    ),
                  ),
                ),
                Obx(
                  () => Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(controller.current.value),
                  ),
                )
              ],
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: SingleChildScrollView(
                  reverse: true,
                  padding: const EdgeInsets.all(4.0),
                  child: Obx(
                    () => Text(
                      controller.log.value,
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
