import 'package:get/get.dart';

import '../controllers/workflow_controller.dart';

class WorkflowBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WorkflowController>(
      () => WorkflowController(),
    );
  }
}
