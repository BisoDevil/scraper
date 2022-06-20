import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:get/get.dart';

import '../controllers/settings_controller.dart';

class SettingsView extends GetView<SettingsController> {
  final _key = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return GetBuilder<SettingsController>(builder: (_) {
      return Scaffold(
        appBar: AppBar(
          toolbarHeight: 50,
          title: Text('Settings'),
          centerTitle: false,
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Form(
            key: _key,
            child: SingleChildScrollView(
              child: Column(
                // crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Vodafone Credintials", style: Get.textTheme.headline6),
                  SizedBox(height: 20),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: TextEditingController(text: _.username),
                          onSaved: (newValue) {
                            controller.username = newValue;
                          },
                          validator: (value) {
                            if (value.isEmpty) return "Required";
                            return null;
                          },
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "Username",
                          ),
                        ),
                      ),
                      SizedBox(width: 18),
                      Expanded(
                        child: TextFormField(
                          controller: TextEditingController(text: _.password),
                          onSaved: (newValue) {
                            controller.password = newValue;
                          },
                          obscureText: true,
                          validator: (value) {
                            if (value.isEmpty) return "Required";
                            return null;
                          },
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "Password",
                          ),
                        ),
                      ),
                      SizedBox(width: 18),
                      Expanded(
                        child: TextFormField(
                          controller: TextEditingController(text: _.sid),
                          onSaved: (newValue) {
                            controller.sid = newValue;
                          },
                          validator: (value) {
                            if (value.isEmpty) return "Required";
                            return null;
                          },
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "Sid",
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Text("Etisalat Credintials", style: Get.textTheme.headline6),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller:
                              TextEditingController(text: _.etisalatUsername),
                          onSaved: (newValue) {
                            controller.etisalatUsername = newValue;
                          },
                          validator: (value) {
                            if (value.isEmpty) return "Required";
                            return null;
                          },
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "Username",
                          ),
                        ),
                      ),
                      SizedBox(width: 18),
                      Expanded(
                        child: TextFormField(
                          controller: TextEditingController(
                              text: controller.etisalatPassword),
                          obscureText: true,
                          onSaved: (newValue) {
                            controller.etisalatPassword = newValue;
                          },
                          validator: (value) {
                            if (value.isEmpty) return "Required";
                            return null;
                          },
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "Password",
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Text("Billing Settings", style: Get.textTheme.headline6),
                  Row(
                    children: [
                      Expanded(
                        child: _intField(
                          labelText: "Grace Period",
                          initialValue: controller.gracePeriodDays,
                          onSaved: (newValue) {
                            controller.gracePeriodDays = newValue;
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Text("Advanced", style: Get.textTheme.headline6),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _intField(
                          initialValue: controller.maxPooling,
                          labelText: "Max pooling",
                          onSaved: (v) => controller.maxPooling = v,
                        ),
                      ),
                      SizedBox(width: 18),
                      Expanded(
                        child: _intField(
                          initialValue: controller.logMaxCharCount,
                          labelText: "Max log char count",
                          onSaved: (v) => controller.logMaxCharCount = v,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  _intField(
                    initialValue: controller.batchCapacity,
                    labelText: "one batch capacity (each batch we write the result to the file)",
                    onSaved: (v) => controller.batchCapacity = v,
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _intField(
                          initialValue: controller.numTrialsOnError,
                          labelText: "Number of trials on error",
                          onSaved: (v) => controller.numTrialsOnError = v,
                        ),
                      ),
                      SizedBox(width: 18),
                      Expanded(
                        child: _intField(
                          initialValue: controller.minWaitAfterErrorMills,
                          labelText: "min wait time after error (ms)",
                          onSaved: (v) => controller.minWaitAfterErrorMills = v,
                        ),
                      ),
                      SizedBox(width: 18),
                      Expanded(
                        child: _intField(
                          initialValue: controller.maxWaitAfterErrorMills,
                          labelText: "max wait time after error (ms)",
                          onSaved: (v) => controller.maxWaitAfterErrorMills = v,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (_key.currentState.validate()) {
                        _key.currentState.save();
                        controller.saveSettings();
                      }
                    },
                    child: Text("Save"),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _intField({
    @required int initialValue,
    @required void Function(int) onSaved,
    @required String labelText,
  }) {
    return TextFormField(
      controller: TextEditingController(text: initialValue.toString()),
      // initialValue: initialValue.toString(),
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onSaved: (newValue) => onSaved(int.parse(newValue)),
      validator: (value) {
        if (value.isEmpty) return "Required";
        return null;
      },
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        labelText: labelText,
      ),
    );
  }
}
