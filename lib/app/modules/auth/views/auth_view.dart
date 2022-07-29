import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/auth_controller.dart';

class AuthView extends GetView<AuthController> {
  final _key = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(builder: (_) {
      return Scaffold(
        appBar: AppBar(
          toolbarHeight: 50,
          title: Text('Log in'),
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
                  Text("Enter your credentials to sign in",
                      style: Get.textTheme.headline6),
                  SizedBox(height: 20),
                  Row(
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
                          controller:
                              TextEditingController(text: controller.password),
                          obscureText: true,
                          onSaved: (newValue) {
                            controller.password = newValue;
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
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_key.currentState.validate()) {
                          _key.currentState.save();
                          controller.login();
                        }
                      },
                      child: Text("Login"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
