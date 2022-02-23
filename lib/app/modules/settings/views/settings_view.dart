import 'package:flutter/material.dart';

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Vodafone Credintials",
                  style: Get.textTheme.headline6,
                ),
                TextFormField(
                  controller: TextEditingController(text: _.username),
                  onSaved: (newValue) {
                    controller.username = newValue;
                  },
                  validator: (value) {
                    if (value.isEmpty) return "Required";
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: "Username",
                  ),
                ),
                TextFormField(
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
                    labelText: "Password",
                  ),
                ),
                TextFormField(
                  controller: TextEditingController(text: _.sid),
                  onSaved: (newValue) {
                    controller.sid = newValue;
                  },
                  validator: (value) {
                    if (value.isEmpty) return "Required";
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: "Sid",
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Text(
                  "Etisalat Credintials",
                  style: Get.textTheme.headline6,
                ),
                TextFormField(
                  controller: TextEditingController(text: _.etisalatUsername),
                  onSaved: (newValue) {
                    controller.etisalatUsername = newValue;
                  },
                  validator: (value) {
                    if (value.isEmpty) return "Required";
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: "Username",
                  ),
                ),
                TextFormField(
                  controller:
                      TextEditingController(text: controller.etisalatPassword),
                  obscureText: true,
                  onSaved: (newValue) {
                    controller.etisalatPassword = newValue;
                  },
                  validator: (value) {
                    if (value.isEmpty) return "Required";
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: "Password",
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_key.currentState.validate()) {
                      _key.currentState.save();
                      controller.saveSettings();
                    }
                  },
                  child: Text("Save"),
                )
              ],
            ),
          ),
        ),
      );
    });
  }
}
