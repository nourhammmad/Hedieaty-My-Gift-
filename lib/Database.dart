import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
          PHONE TEXT,
          FRIENDS TEXT
        )
      ''');

      // Create the Friends table to track friendships between users
      await db.execute('''
        CREATE TABLE Friends (
    ID INTEGER PRIMARY KEY AUTOINCREMENT,
    USER_FIREBASE_ID TEXT NOT NULL,
    FRIEND_FIREBASE_ID TEXT NOT NULL,
    displayName TEXT,
    phoneNumber TEXT, 
    ADDED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (USER_FIREBASE_ID) REFERENCES Users(FIREBASE_ID),
    FOREIGN KEY (FRIEND_FIREBASE_ID) REFERENCES Users(FIREBASE_ID)
  )
      ''');
    });
    return mydb;
  }
  Future<List<Map<String, dynamic>>> getFriendsFromLocal(String userId) async {
    final db = await MyDataBase;
    var result = await db.query('Friends', where: 'USER_FIREBASE_ID = ?', whereArgs: [userId]);
    return result;
  }

  // Method to insert friends into the database
  Future<void> insertFriendsToLocal(String userId, List<Map<String, dynamic>> friendsData) async {
    final db = await MyDataBase;
    Batch batch = db.batch();

    // Remove existing friends of the user before inserting
    batch.delete('Friends', where: 'USER_FIREBASE_ID = ?', whereArgs: [userId]);

    // Insert new friends data
    for (var friend in friendsData) {
      batch.insert('Friends', friend);
    }

    await batch.commit();
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

  Future<void> insertUser(String displayName, String email, String password, String phone) async {
    Database? mydata = await MyDataBase;
    await mydata!.insert('Users', {
      'displayName': displayName,
      'EMAIL': email,
      'PASSWORD': password,  // Handle password securely, might need encryption
      'PHONE': phone,
      'FRIENDS': jsonEncode([]), // Start with an empty friends list
    });
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


  Future<List<Map<String, dynamic>>> getFriends(String firebaseId) async {
    Database? mydata = await MyDataBase;

    return await mydata!.rawQuery(
      "SELECT u.displayName, u.EMAIL "
          "FROM Users u "
          "JOIN Friends f ON u.FIREBASE_ID = f.FRIEND_FIREBASE_ID "
          "WHERE f.USER_FIREBASE_ID = ?",
      [firebaseId],
    );
  }





}
