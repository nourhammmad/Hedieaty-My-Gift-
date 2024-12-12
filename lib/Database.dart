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
          phoneNumber INT,
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
      await db.execute('''
      CREATE TABLE Events (
              eventId INTEGER PRIMARY KEY AUTOINCREMENT,
              FIRESTORE_EVENT_ID TEXT NOT NULL UNIQUE,
              name TEXT NOT NULL,
              type TEXT NOT NULL,
              status TEXT NOT NULL,
              FIRESTORE_USER_ID TEXT NOT NULL,
              FOREIGN KEY (FIRESTORE_USER_ID) REFERENCES Users(FIREBASE_ID) 
              )
              ''');
      await db.execute('''
      CREATE TABLE Gifts (
              giftId INTEGER PRIMARY KEY AUTOINCREMENT,
              FIRESTORE_GIFT_ID TEXT NOT NULL UNIQUE,
              giftName TEXT NOT NULL,
              status TEXT,
              dueTo TEXT,
              giftValue TEXT,
              FIRESTORE_EVENT_ID TEXT NOT NULL,
              FOREIGN KEY (FIRESTORE_EVENT_ID) REFERENCES Events(FIRESTORE_EVENT_ID)
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

  Future<void> insertOrUpdateUser(Map<String, dynamic> userData) async {
    final Database db = await MyDataBase;

    try {
      // Check if the user already exists using FIREBASE_ID or another unique identifier (e.g., EMAIL)
      var existingUser = await db.rawQuery(
        "SELECT * FROM Users WHERE FIREBASE_ID = ?",
        [userData['FIREBASE_ID']],
      );

      if (existingUser.isNotEmpty) {
        // Update the existing user record
        print("User exists, updating record...");
        await db.update(
          'Users',
          userData,
          where: "FIREBASE_ID = ?",
          whereArgs: [userData['FIREBASE_ID']],
        );
      } else {
        // Insert a new user record
        print("User does not exist, inserting new record...");
        await db.insert('Users', userData);
      }
    } catch (e) {
      print("Error inserting or updating user: $e");
    }
  }
  Future<void> insertEvent(String currentUserId, Map<String, String> eventData) async {
    final Database db = await MyDataBase;

    // Check if the friend already exists for the current user
    var existingEvent = await db.query(
        'Events',
        where: 'FIRESTORE_USER_ID = ? AND FIRESTORE_EVENT_ID = ?',
        whereArgs: [currentUserId, eventData['eventId']]
    );

    // If the friend does not exist, insert the friend into the database
    if (existingEvent.isEmpty) {
      await db.insert(
        'Events',
        {
          'FIRESTORE_USER_ID': currentUserId!,  // Logged-in user's Firebase ID
          'FIRESTORE_EVENT_ID': eventData['eventId']!, // The friend's Firebase ID
          'name': eventData['title']!,
          'type': eventData['type']!,
          'status': eventData['status']!,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,  // Avoid inserting duplicates
      );
      print("Event inserted for user $currentUserId");
    } else {
      // If the friend already exists, check if there are updates required (e.g., displayName, phoneNumber)
      bool needsUpdate = false;

      if (existingEvent[0]['name'] != eventData['title'] ||
          existingEvent[0]['type'] != eventData['type'] ||
          existingEvent[0]['status'] != eventData['status']) {
        needsUpdate = true;
      }

      // Update if necessary
      if (needsUpdate) {
        await db.update(
            'Events',
            {
              'name': eventData['title']!,
              'type': eventData['type']!,
              'status': eventData['status']!,
            },
            where: 'FIRESTORE_USER_ID = ? AND FIRESTORE_EVENT_ID = ?',
            whereArgs: [currentUserId, eventData['eventId']]
        );
        print("Event updated for user $currentUserId");
      } else {
        print("No update needed for user $currentUserId");
      }
    }
  }
  Future<void> insertGift(String eventId, Map<String, String> giftData) async {
    final Database db = await MyDataBase;

    // Check if the friend already exists for the current user
    var existingGift = await db.query(
        'Gifts',
        where: 'FIRESTORE_EVENT_ID = ? AND FIRESTORE_GIFT_ID = ?',
        whereArgs: [eventId, giftData['FIRESTORE_GIFT_ID']]
    );

    // If the friend does not exist, insert the friend into the database
    if (existingGift.isEmpty) {
      await db.insert(
        'Gifts',
        {
          'FIRESTORE_GIFT_ID': giftData['FIRESTORE_GIFT_ID']!,
          'FIRESTORE_EVENT_ID': eventId, // The friend's Firebase ID
          'giftName': giftData['giftName']!,
          'status': giftData['status']!,
          'dueTo': giftData['dueTo']!,
          'giftValue': giftData['giftValue']!,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,  // Avoid inserting duplicates
      );
      print("Gift inserted for event $eventId");
    } else {
      // If the friend already exists, check if there are updates required (e.g., displayName, phoneNumber)
      bool needsUpdate = false;

      if (existingGift[0]['giftName'] != giftData['giftName'] ||
          existingGift[0]['dueTo'] != giftData['dueTo'] ||
          existingGift[0]['status'] != giftData['status']||
          existingGift[0]['giftValue'] != giftData['giftValue']) {
        needsUpdate = true;
      }

      // Update if necessary
      if (needsUpdate) {
        await db.update(
            'Gifts',
            {
              'giftName': giftData['giftName']!,
              'status': giftData['status']!,
              'dueTo': giftData['dueTo']!,
              'giftValue': giftData['giftValue']!,
            },
            where: 'FIRESTORE_EVENT_ID = ? AND FIRESTORE_GIFT_ID = ?',
            whereArgs: [eventId, giftData['FIRESTORE_GIFT_ID']]
        );
        print("Gift updated for user $eventId");
      } else {
        print("No update needed for user $eventId");
      }
    }
  }


  Future<void> insertFriend(String currentUserId, Map<String, String> friendData) async {
    final Database db = await MyDataBase;

    // Check if the friend already exists for the current user
    var existingFriend = await db.query(
        'Friends',
        where: 'USER_FIREBASE_ID = ? AND FRIEND_FIREBASE_ID = ?',
        whereArgs: [currentUserId, friendData['friendId']]
    );

    // If the friend does not exist, insert the friend into the database
    if (existingFriend.isEmpty) {
      await db.insert(
        'Friends',
        {
          'USER_FIREBASE_ID': currentUserId,  // Logged-in user's Firebase ID
          'FRIEND_FIREBASE_ID': friendData['friendId']!, // The friend's Firebase ID
          'displayName': friendData['displayName']!,
          'phoneNumber': friendData['phoneNumber']!,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,  // Avoid inserting duplicates
      );
      print("Friend inserted for user $currentUserId");
    } else {
      // If the friend already exists, check if there are updates required (e.g., displayName, phoneNumber)
      bool needsUpdate = false;

      if (existingFriend[0]['displayName'] != friendData['displayName'] ||
          existingFriend[0]['phoneNumber'] != friendData['phoneNumber']) {
        needsUpdate = true;
      }

      // Update if necessary
      if (needsUpdate) {
        await db.update(
            'Friends',
            {
              'displayName': friendData['displayName'],
              'phoneNumber': friendData['phoneNumber'],
            },
            where: 'USER_FIREBASE_ID = ? AND FRIEND_FIREBASE_ID = ?',
            whereArgs: [currentUserId, friendData['friendId']]
        );
        print("Friend updated for user $currentUserId");
      } else {
        print("No update needed for friend $currentUserId");
      }
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
  Future<List<Map<String, String>>> getUsers() async {
    final Database db = await MyDataBase;

    // Query all users from the 'Users' table
    List<Map<String, dynamic>> userList = await db.query('Users');

    // Convert the result to List<Map<String, String>> format
    List<Map<String, String>> users = [];

    for (var user in userList) {
      users.add({
        'id': user['ID'].toString(),
        'firebaseId': user['FIREBASE_ID'] ?? 'No Firebase ID',
        'displayName': user['displayName'] ?? 'No Display Name',
        'email': user['EMAIL'] ?? 'No Email',
        'password': user['PASSWORD'] ?? 'No Password',
        'phone': user['PHONE'] ?? 'No Phone',
        'friends': user['FRIENDS'] ?? 'No Friends',
      });
    }

    return users;
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
  Future<List<Map<String, Object?>>> getFriendsByUserId(String currentUserId) async {
    final Database db = await MyDataBase;

    // Query to get all friends of the current user based on USER_FIREBASE_ID
    var result = await db.query(
      'Friends',
      where: 'USER_FIREBASE_ID = ?',
      whereArgs: [currentUserId],
    );

    // Return a list of friends data from the query result
    return result.map((friend) {
      return {
        'friendId': friend['FRIEND_FIREBASE_ID'],
        'displayName': friend['displayName'],
        'phoneNumber': friend['phoneNumber'],
      };
    }).toList();
  }
  Future<List<Map<String, Object?>>> getEventsByUserId(String currentUserId) async {
    final Database db = await MyDataBase;

    // Query to get all friends of the current user based on USER_FIREBASE_ID
    var result = await db.query(
      'Events',
      where: 'FIRESTORE_USER_ID = ?',
      whereArgs: [currentUserId],
    );

    // Return a list of friends data from the query result
    return result.map((event) {
      return {
        'title': event['name']!,
        'type': event['type']!,
        'status': event['status']!,
      };
    }).toList();
  }


  Future<List<Map<String, String>>> getFriends() async {
    Database? mydata = await MyDataBase;

    // Query all the rows from the Friends table
    final List<Map<String, dynamic>> maps = await mydata.query('Friends');

    // Convert the List<Map<String, dynamic>> to List<Map<String, String>>
    return List.generate(maps.length, (i) {
      return {
        'userId':maps[i]['USER_FIREBASE_ID'],
        'friendId': maps[i]['FRIEND_FIREBASE_ID'],
        'displayName': maps[i]['displayName'],
        'phoneNumber': maps[i]['phoneNumber'],
      };
    });
  }






}
