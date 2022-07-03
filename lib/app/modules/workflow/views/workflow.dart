import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:get/get.dart';

import '../controllers/workflow_controller.dart';

class WorkflowView extends GetView<WorkflowController> {
  final _key = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return GetBuilder<WorkflowController>(
      builder: (_) {
        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 50,
            title: Text('Workflow'),
            centerTitle: false,
          ),
          floatingActionButton: FloatingActionButton(
            child: Icon(
              Icons.play_arrow_outlined,
            ),
            onPressed:
                controller.workflow != null ? controller.startWorkflow : null,
            backgroundColor: controller.workflow == null ? Colors.grey : null,
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
                        SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              GetBuilder<WorkflowController>(
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
                              SizedBox(height: 8),
                              GetBuilder<WorkflowController>(
                                initState: (_) {},
                                builder: (_) => Column(children: buildJobs(context)),
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
        );
      },
    );
  }

  List<Widget> buildJobs(BuildContext context) {
    if (controller.workflow == null) {
      return [];
    }
    return controller.workflow['jobs']
        .asMap()
        .entries
        .map<Widget>((jobEntry) => buildJob(context, jobEntry.key, jobEntry.value))
        .toList();
  }

  Widget buildJob(BuildContext context, int jobIndex, job) {
    var textColor = Colors.green; // past job
    final runningIndex = controller.currentJobIndex.value;
    print("building job index $jobIndex and running index is $runningIndex");
    if(jobIndex == runningIndex) {
      // current running job
      textColor = Colors.yellow;
    } else if (jobIndex > runningIndex) {
      // future job
      textColor = null;
    }
    return Text(job['name'], style: TextStyle(color: textColor),);
  }
}
