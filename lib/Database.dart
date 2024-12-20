import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'UserSession.dart';

class Databaseclass {
  static Database? _MyDataBase;
  final int Version = 1;

  Future<Database> get MyDataBase async {
    if (_MyDataBase == null) {
      _MyDataBase = await initialize();
    }
    return _MyDataBase!;
  }


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
              category TEXT,
              dueTo TEXT,
              giftValue TEXT,
              FIRESTORE_EVENT_ID TEXT NOT NULL,
              FOREIGN KEY (FIRESTORE_EVENT_ID) REFERENCES Events(FIRESTORE_EVENT_ID)
              )
              ''');

    });
    return mydb;
  }

  Future<void> deleteFriendsNotInFirestore(String userId, List<String> firestoreFriendIds) async {
    final Database db = await MyDataBase;
    List<Map<String, dynamic>> localFriends = await db.query(
      'Friends',
      where: 'USER_FIREBASE_ID = ?',
      whereArgs: [userId],
    );

    for (var localFriend in localFriends) {
      if (!firestoreFriendIds.contains(localFriend['FRIEND_FIREBASE_ID']))
      {
         await db.delete(
          'Friends',
          where: 'USER_FIREBASE_ID = ? AND FRIEND_FIREBASE_ID = ?',
          whereArgs: [userId, localFriend['FRIEND_FIREBASE_ID']],
        );
        print("Deleted friend ${localFriend['FRIEND_FIREBASE_ID']} for user $userId");
      }
    }
  }

  Future<void> insertOrUpdateUser(Map<String, dynamic> userData) async {
    final Database db = await MyDataBase;

    try {
       var existingUser = await db.rawQuery(
        "SELECT * FROM Users WHERE FIREBASE_ID = ?",
        [userData['FIREBASE_ID']],
      );

      if (existingUser.isNotEmpty) {
         print("User exists, updating record...");
        await db.update(
          'Users',
          userData,
          where: "FIREBASE_ID = ?",
          whereArgs: [userData['FIREBASE_ID']],
        );
      } else {
         print("User does not exist, inserting new record...");
        await db.insert('Users', userData);
      }
    } catch (e) {
      print("Error inserting or updating user: $e");
    }
  }

  Future<void> deleteEventsNotInFirestore(String userId, List<String> firestoreEventIds) async {
    final Database db = await MyDataBase;
    List<Map<String, dynamic>> localEvents = await db.query(
      'Events',
      where: 'FIRESTORE_USER_ID = ?',
      whereArgs: [userId],
    );
    for (var localEvent in localEvents) {
      if (!firestoreEventIds.contains(localEvent['FIRESTORE_EVENT_ID'])) {
         await db.delete(
          'Events',
          where: 'FIRESTORE_USER_ID = ? AND FIRESTORE_EVENT_ID = ?',
          whereArgs: [userId, localEvent['FIRESTORE_EVENT_ID']],
        );
        print("Deleted event ${localEvent['FIRESTORE_EVENT_ID']} for user $userId");
      }
    }
  }

  Future<void> insertEvent(String currentUserId, Map<String, String> eventData) async {
    final Database db = await MyDataBase;

     var existingEvent = await db.query(
        'Events',
        where: 'FIRESTORE_USER_ID = ? AND FIRESTORE_EVENT_ID = ?',
        whereArgs: [currentUserId, eventData['eventId']]
    );

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
       bool needsUpdate = false;
      if (existingEvent[0]['name'] != eventData['title'] ||
          existingEvent[0]['type'] != eventData['type'] ||
          existingEvent[0]['status'] != eventData['status']) {
        needsUpdate = true;
      }
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
    var existingGift = await db.query(
        'Gifts',
        where: 'FIRESTORE_EVENT_ID = ? AND FIRESTORE_GIFT_ID = ?',
        whereArgs: [eventId, giftData['FIRESTORE_GIFT_ID']]
    );
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
          'category':giftData['category']!,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,  // Avoid inserting duplicates
      );
      print("Gift inserted for event $eventId");
    } else {
       bool needsUpdate = false;

      if (existingGift[0]['giftName'] != giftData['giftName'] ||
          existingGift[0]['dueTo'] != giftData['dueTo'] ||
          existingGift[0]['status'] != giftData['status']||
          existingGift[0]['giftValue'] != giftData['giftValue']) {
        needsUpdate = true;
      }

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

  Future<void> deleteRemovedGifts(String eventId, List<String> firestoreGiftIds) async {
    final Database db = await MyDataBase;
    List<Map<String, dynamic>> localGifts = await db.query(
      'Gifts',
      where: 'FIRESTORE_EVENT_ID = ?',
      whereArgs: [eventId],
    );
    for (var localGift in localGifts) {
      if (!firestoreGiftIds.contains(localGift['FIRESTORE_GIFT_ID'])) {
        await db.delete(
          'Gifts',
          where: 'FIRESTORE_EVENT_ID = ? AND FIRESTORE_GIFT_ID = ?',
          whereArgs: [eventId, localGift['FIRESTORE_GIFT_ID']],
        );
        print("Deleted gift ${localGift['FIRESTORE_GIFT_ID']} from local database.");
      }
    }
  }

  Future<void> insertFriend(String currentUserId, Map<String, String> friendData) async {
    final Database db = await MyDataBase;
    var existingFriend = await db.query(
        'Friends',
        where: 'USER_FIREBASE_ID = ? AND FRIEND_FIREBASE_ID = ?',
        whereArgs: [currentUserId, friendData['friendId']]
    );
    if (existingFriend.isEmpty) {
      await db.insert(
        'Friends',
        {
          'USER_FIREBASE_ID': currentUserId,
          'FRIEND_FIREBASE_ID': friendData['friendId']!,
          'displayName': friendData['displayName']!,
          'phoneNumber': friendData['phoneNumber']!,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      var x=friendData['friendId'];
      print("Friend $x inserted for user $currentUserId");
    } else {
       bool needsUpdate = false;
      if (existingFriend[0]['displayName'] != friendData['displayName'] ||
          existingFriend[0]['phoneNumber'] != friendData['phoneNumber']) {
        needsUpdate = true;
      }

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


  Future<List<Map<String, dynamic>>> readData(String sql, List<dynamic> parameters) async {
    Database? mydata = await MyDataBase;
    return await mydata!.rawQuery(sql, parameters);
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
      return true;
    } else {
      return false;
    }
  }

  Future<List<Map<String, Object?>>> getFriendsByUserId(String currentUserId) async {
    final Database db = await MyDataBase;

     var result = await db.query(
      'Friends',
      where: 'USER_FIREBASE_ID = ?',
      whereArgs: [currentUserId],
    );

     return result.map((friend) {
      return {
        'friendId': friend['FRIEND_FIREBASE_ID'],
        'displayName': friend['displayName'],
        'phoneNumber': friend['phoneNumber'],
      };
    }).toList();
  }

  Future<List<Map<String, Object?>>> getGiftsByEventId(String eventId) async {
    final Database db = await MyDataBase;

     var result = await db.query(
      'Gifts',
      where: 'FIRESTORE_EVENT_ID = ?',
      whereArgs: [eventId],
    );

     return result.map((gift) {
      return {
        'giftName': gift['giftName']!,
        'status': gift['status']!,
        'category':gift['category'],
        'dueTo': gift['dueTo']!,
        'giftValue': gift['giftValue']!,
      };
    }).toList();
  }

  Future<List<Map<String, Object?>>> getEventsByUserId(String currentUserId) async {
    final Database db = await MyDataBase;

     var result = await db.query(
      'Events',
      where: 'FIRESTORE_USER_ID = ?',
      whereArgs: [currentUserId],
    );

     return result.map((event) {
      return {
        'title': event['name']!,
        'type': event['type']!,
        'status': event['status']!,
        'eventId': event['FIRESTORE_EVENT_ID']!,
      };
    }).toList();
  }
}
