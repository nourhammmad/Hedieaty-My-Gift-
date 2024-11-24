import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  static const String _userIdKey = 'userId'; // Store user ID (String for Firebase UID)
  static const String _userNameKey = 'userName';

  // Save user info in shared preferences
  static Future<void> saveUserSession(String userId, String userName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(_userIdKey, userId); // Store userId as String
    prefs.setString(_userNameKey, userName);
  }

  // Retrieve user ID from shared preferences
  static Future<String?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey); // Retrieve as String
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
