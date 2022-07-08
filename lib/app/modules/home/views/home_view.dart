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
          ),
          IconButton(
            onPressed: () {
              Get.toNamed(Routes.WORKFLOW);
            },
            icon: Icon(
              Icons.workspaces,
            ),
          ),
        ],
      ),
      floatingActionButton: GetBuilder<HomeController>(
        initState: (_) => {},
        builder: (context) {
          final disabled =
              controller.isRunning.value || !controller.isConnected.value;
          return FloatingActionButton(
            child: Icon(Icons.play_arrow_outlined),
            backgroundColor: disabled ? Colors.grey : null,
            onPressed: disabled ? null : controller.testInputFile,
          );
        },
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GetBuilder<HomeController>(
            initState: (_) => {},
            builder: (context) =>
                _ConnectionStatusBar(isConnected: controller.isConnected.value),
          ),
          Expanded(
            child: Padding(
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
                          /// log
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
                          SizedBox(width: 10),
                          // input fields
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
                                            style:
                                                Get.textTheme.button.copyWith(
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                SizedBox(height: 8),
                                GetBuilder<HomeController>(
                                  initState: (_) {},
                                  builder: (_) {
                                    return TextFormField(
                                      readOnly: controller.isRunning.value,
                                      initialValue:
                                          controller.singleLandline.value,
                                      onChanged: controller.singleLandline,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(),
                                        suffixIcon: TextButton.icon(
                                          onPressed: () {
                                            controller.testSingleLine();
                                          },
                                          icon: Icon(Icons.play_arrow_outlined),
                                          label: Text(
                                            "test single landline",
                                            style:
                                                Get.textTheme.button.copyWith(
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                GetBuilder<HomeController>(
                                  builder: (_) {
                                    return CheckboxListTile(
                                      value: controller.allowArdy,
                                      title: Text("Billing"),
                                      onChanged: (value) {
                                        controller.allowArdy = value;
                                        controller.update();
                                      },
                                    );
                                  },
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
                                      value: controller.allowVodafone,
                                      title: Text("Vodafone"),
                                      onChanged: (value) {
                                        controller.allowVodafone = value;
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
                  SizedBox(height: 20),
                  // progressbar
                  Padding(
                    padding: const EdgeInsets.only(right: 80),
                    child: Row(
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
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionStatusBar extends StatelessWidget {
  const _ConnectionStatusBar({
    Key key,
    @required this.isConnected,
  }) : super(key: key);

  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isConnected ? Colors.green : Colors.red,
      height: 30,
      alignment: Alignment.center,
      child: Text(isConnected ? "connected" : "not connected"),
    );
  }
}
