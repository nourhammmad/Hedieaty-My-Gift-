import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  static const String _userIdKey = 'userId'; // Store user ID or email
  static const String _userNameKey = 'userName';

  // Save user info in shared preferences
  static Future<void> saveUserSession(int userId, String userName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt(_userIdKey, userId);
    prefs.setString(_userNameKey, userName);
  }

  // Retrieve user ID from shared preferences
  static Future<int?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  // Retrieve user name from shared preferences
  static Future<String?> getUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  // Clear user session (logout)
  static Future<void> clearUserSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove(_userIdKey);
    prefs.remove(_userNameKey);
  }
}
