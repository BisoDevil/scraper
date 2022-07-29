import 'package:flutter/cupertino.dart';
import 'package:scraper/utils/preferences.dart';

class User {
  String username;
  String password;
  String displayName;
  String role;
  List<String> permissions;
  User({
    @required this.username,
    @required this.password,
    @required this.displayName,
    this.role,
    this.permissions = const [],
  });

  bool haveScope(String scope) {
    return AuthService.getInstance().haveScope(scope, user: this);
  }
}

final _usersDict = {
  "kareem@admin.eg.landline": User(
    username: "kareem@admin.eg.landline",
    displayName: "Kareem",
    password: "saP@ssw0rd123",
    role: "admin"
  ),
  "user@cs.eg.landline":  User(
    username: "user@cs.eg.landline",
    displayName: "Default User",
    password: "user123",
    role: "default",
    permissions: [
      "vodafone",
    ],
  ),
};

class AuthService {
  static AuthService instance = AuthService._internal();
  static AuthService getInstance() {
    instance ??= AuthService._internal();
    return instance;
  }

  AuthService._internal();

  User currentUser;

  User getUser(String username, String pass) {
    if(!_usersDict.containsKey(username)) return null;
    final user = _usersDict[username];
    if(user.password != pass) {
      return null;
    }
    return user;
  }

  Future<void> logout() async {
    currentUser = null;
    final prefs = await AppPreferences.getInstance();
    await prefs.removeAppPassword();
    await prefs.removeAppUsername();
  }

  void setCurrentUser(User user) async {
    currentUser = user;
    final prefs = await AppPreferences.getInstance();
    await prefs.setAppUsername(user.username);
    await prefs.setAppPassword(user.password);
  }

  bool haveScope(String scope, {User user}) {
    user ??= currentUser;
    if(user == null) return false;
    return user.permissions.contains(scope) || user.role == 'admin';
  }
}