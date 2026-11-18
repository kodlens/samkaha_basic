import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  Future<Map<String, dynamic>?> loadUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');

    if (userJson != null) {
      final userMap = json.decode(userJson);
      return {
        'id': userMap['id'],
        'username': userMap['username'],
        'fname': userMap['fname'],
        'mname': userMap['mname'],
        'lname': userMap['lname'],
        'role': userMap['role'],
        'sex': userMap['sex'],
      };
    }
    return null;
  }

  Future<void> clearUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
  }
}
