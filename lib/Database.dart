import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'UserSession.dart';

class Databaseclass {
  static Database? _MyDataBase;

  Future<Database> get MyDataBase async {
    if (_MyDataBase == null) {
      _MyDataBase = await initialize();
    }
    return _MyDataBase!;
  }

  final int Version = 1;

  Future<Database> initialize() async {
    String mypath = await getDatabasesPath();
    String path = join(mypath, 'Hedeaty.db');
    Database mydb = await openDatabase(path, version: Version, onCreate: (db, Version) async {
      // Enable foreign keys
      await db.execute('PRAGMA foreign_keys = ON');

      // Create the Users table
      await db.execute('''
        CREATE TABLE Users (
          ID INTEGER PRIMARY KEY AUTOINCREMENT,
          FIREBASE_ID TEXT NOT NULL,
          displayName TEXT,
          EMAIL TEXT NOT NULL UNIQUE,
          PASSWORD TEXT NOT NULL,
          PHONE TEXT
        )
      ''');

      // Create the Friends table to track friendships between users
      await db.execute('''
        CREATE TABLE Friends (
          USER_ID INTEGER NOT NULL,
          FRIEND_ID INTEGER NOT NULL,
          PRIMARY KEY (USER_ID, FRIEND_ID),
          FOREIGN KEY (USER_ID) REFERENCES Users(ID) ON DELETE CASCADE,
          FOREIGN KEY (FRIEND_ID) REFERENCES Users(ID) ON DELETE CASCADE
        )
      ''');
    });
    return mydb;
  }

  Future<void> insertOrUpdateUser(Map<String, dynamic> userData) async {
    final Database db = await MyDataBase;

    // Check if a user with the given ID already exists
    var existingUser = await db.rawQuery(
      "SELECT * FROM Users WHERE ID = ?",
      [userData['ID']],
    );

    if (existingUser.isNotEmpty) {
      // Update the existing user record
      await db.update(
        'Users',
        userData,
        where: "ID = ?",
        whereArgs: [userData['ID']],
      );
    } else {
      // Insert a new user record
      await db.insert('Users', userData);
    }
  }

  String hashPassword(String password) {
    var bytes = utf8.encode(password); // Convert password to bytes
    var hashed = sha256.convert(bytes); // Hash the bytes using SHA-256
    return hashed.toString(); // Return the hash as a string
  }

  Future<int> insertUser(String displayName, String email, String password, String phoneNumber) async {
    Database mydata = await MyDataBase;
    return await mydata.insert(
      'Users',
      {
        'displayName': displayName,
        'EMAIL': email,
        'PASSWORD': password,
        'PHONE': phoneNumber,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> userExists(String email) async {
    Database db = await MyDataBase;
    var result = await db.rawQuery(
      "SELECT * FROM Users WHERE EMAIL = ?", [email],
    );
    return result.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> readData(String sql, List<dynamic> parameters) async {
    Database? mydata = await MyDataBase;
    return await mydata!.rawQuery(sql, parameters);
  }

  Future<int> deleteData(String SQL) async {
    Database? mydata = await MyDataBase;
    return await mydata!.rawDelete(SQL);
  }

  Future<void> mydeletedatabase() async {
    String database = await getDatabasesPath();
    String path = join(database, 'Hedeaty.db');
    if (await databaseExists(path)) {
      await deleteDatabase(path);
      print("Database has been deleted");
    } else {
      print("Database doesn't exist");
    }
  }

  Future<bool> validateLogin(String email, String password) async {
    Database? mydata = await MyDataBase;

    String hashedPassword = password;
    var result = await mydata!.rawQuery(
      "SELECT * FROM Users WHERE EMAIL = ? AND PASSWORD = ?",
      [email, hashedPassword],
    );

    if (result.isNotEmpty) {
      //String userId = result[0]['ID'].toString();
      //String userName = result[0]['displayName'] as String;
      //await UserSession.saveUserSession(userId, userName);
      return true;
    } else {
      return false;
    }
  }

  Future<int> updateData(String query, List<dynamic> args) async {
    Database? mydata = await MyDataBase;
    return await mydata!.rawUpdate(query, args);
  }

  Future<void> addFriendByPhoneNumber(int userId, String friendPhoneNumber) async {
    Database? mydata = await MyDataBase;

    var result = await mydata!.rawQuery(
      "SELECT ID FROM Users WHERE PHONE = ?",
      [friendPhoneNumber],
    );

    if (result.isNotEmpty) {
      int friendId = result[0]['ID'] as int;

      var friendCheck = await mydata.rawQuery(
        "SELECT * FROM Friends WHERE USER_ID = ? AND FRIEND_ID = ?",
        [userId, friendId],
      );

      if (friendCheck.isEmpty) {
        await mydata.insert('Friends', {
          'USER_ID': userId,
          'FRIEND_ID': friendId,
        });
      }
    } else {
      throw Exception('Friend with phone number $friendPhoneNumber not found');
    }
  }

  Future<List<Map<String, dynamic>>> getFriends(int userId) async {
    Database? mydata = await MyDataBase;

    return await mydata!.rawQuery(
      "SELECT u.displayName, u.EMAIL FROM Users u "
          "JOIN Friends f ON u.ID = f.FRIEND_ID WHERE f.USER_ID = ?",
      [userId],
    );
  }

  Future<void> removeFriend(int userId, int friendId) async {
    Database? mydata = await MyDataBase;
    await mydata!.rawDelete(
      "DELETE FROM Friends WHERE USER_ID = ? AND FRIEND_ID = ?",
      [userId, friendId],
    );
  }
}
