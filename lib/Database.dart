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
          ADDED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (USER_FIREBASE_ID) REFERENCES Users(FIREBASE_ID),
          FOREIGN KEY (FRIEND_FIREBASE_ID) REFERENCES Users(FIREBASE_ID)
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
  //
  // Future<void> addFriendByPhoneNumber(int userId, String friendPhoneNumber) async {
  //   Database? mydata = await MyDataBase;
  //
  //   var result = await mydata!.rawQuery(
  //     "SELECT ID FROM Users WHERE PHONE = ?",
  //     [friendPhoneNumber],
  //   );
  //
  //   if (result.isNotEmpty) {
  //     int friendId = result[0]['ID'] as int;
  //
  //     var friendCheck = await mydata.rawQuery(
  //       "SELECT * FROM Friends WHERE USER_ID = ? AND FRIEND_ID = ?",
  //       [userId, friendId],
  //     );
  //
  //     if (friendCheck.isEmpty) {
  //       await mydata.insert('Friends', {
  //         'USER_ID': userId,
  //         'FRIEND_ID': friendId,
  //       });
  //     }
  //   } else {
  //     throw Exception('Friend with phone number $friendPhoneNumber not found');
  //   }
  // }

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

  Future<bool> doesPhoneNumberExist(String phoneNumber) async {
    // Query Firestore's 'users' collection to check if the phone number exists
    var result = await FirebaseFirestore.instance
        .collection('users')
        .where('phone', isEqualTo: phoneNumber) // Ensure the field name matches the schema
        .get();

    // Return true if at least one document exists with the given phone number
    return result.docs.isNotEmpty;
  }


  // Method to add a friend by phone number
  Future<void> addFriendByPhoneNumber(String userFirebaseId, String friendPhoneNumber) async {
    Database? mydata = await MyDataBase;

    // Step 1: Check if the phone number exists in the local database (Users table)
    var result = await mydata!.rawQuery(
      "SELECT FIREBASE_ID, PHONE, FRIENDS FROM Users WHERE PHONE = ?",
      [friendPhoneNumber],
    );

    if (result.isNotEmpty) {
      // Friend exists in the local database
      Object? friendFirebaseId = result[0]['FIREBASE_ID'];
      String? friendsList = result[0]['FRIENDS'] as String?; // Get current friends list

      // Step 2: Check if the user is already friends with this person
      var friendCheck = await mydata.rawQuery(
        "SELECT * FROM Friends WHERE USER_FIREBASE_ID = ? AND FRIEND_FIREBASE_ID = ?",
        [userFirebaseId, friendFirebaseId],
      );

      if (friendCheck.isEmpty) {
        // Step 3: Add friend to the friends list if not already present
        await mydata.insert('Friends', {
          'USER_FIREBASE_ID': userFirebaseId,
          'FRIEND_FIREBASE_ID': friendFirebaseId,
        });

        // Step 4: Update the user's friends list
        List<String> updatedFriendsList = [];

        // If there's already a friends list, add the new friend
        if (friendsList != null && friendsList.isNotEmpty) {
          updatedFriendsList = List<String>.from(jsonDecode(friendsList)); // Deserialize JSON
        }

        // Add the new friend's Firebase ID to the list
        updatedFriendsList.add(friendFirebaseId as String);

        // Update the friends field in the Users table
        await mydata.rawUpdate(
          "UPDATE Users SET FRIENDS = ? WHERE FIREBASE_ID = ?",
          [jsonEncode(updatedFriendsList), userFirebaseId], // Serialize to JSON
        );

        print("Friend added successfully!");
      } else {
        print("This user is already your friend.");
      }
    } else {
      // Step 5: If the phone number doesn't exist in the local database, sync with Firebase
      try {
        // Syncing Firebase data
        var firebaseDoc = await FirebaseFirestore.instance
            .collection('users')
            .where('phoneNumber', isEqualTo: friendPhoneNumber)
            .get();

        if (firebaseDoc.docs.isNotEmpty) {
          // Sync the Firebase user with the local database
          var friendData = firebaseDoc.docs.first.data();
          await insertUser(
            friendData['displayName'] ?? 'Unknown', // Use a default if null
            friendData['email'] ?? '', // Default to empty string if null
            friendData['password'] ?? '',  // Default to empty string or handle password securely
            friendPhoneNumber,
          );

          // Add the friend after syncing
          String? friendFirebaseId = firebaseDoc.docs.first.id;

          if (friendFirebaseId != null) {
            // Add the friend to the 'Friends' table
            await mydata.insert('Friends', {
              'USER_FIREBASE_ID': userFirebaseId,
              'FRIEND_FIREBASE_ID': friendFirebaseId,
            });

            // Update the user's friends list
            List<String> updatedFriendsList = [];

            // Retrieve the user's current friends list from the database
            var userFriendsListResult = await mydata.rawQuery(
              "SELECT FRIENDS FROM Users WHERE FIREBASE_ID = ?",
              [userFirebaseId],
            );
            if (userFriendsListResult.isNotEmpty) {
              String? currentFriendsList = userFriendsListResult[0]['FRIENDS'] as String?;
              if (currentFriendsList != null && currentFriendsList.isNotEmpty) {
                updatedFriendsList = List<String>.from(jsonDecode(currentFriendsList)); // Deserialize
              }
            }

            // Add the new friend's Firebase ID to the list
            updatedFriendsList.add(friendFirebaseId);

            // Update the friends field in the Users table
            await mydata.rawUpdate(
              "UPDATE Users SET FRIENDS = ? WHERE FIREBASE_ID = ?",
              [jsonEncode(updatedFriendsList), userFirebaseId], // Serialize to JSON
            );

            print("Friend added successfully!");
          } else {
            // Handle error if Firebase ID is null
            throw Exception('Failed to retrieve friend Firebase ID');
          }
        } else {
          // Handle error if the phone number is not found in Firebase
          throw Exception('Friend with this phone number not found in Firebase');
        }
      } catch (e) {
        // Catch any errors during Firebase syncing
        print("Error syncing with Firebase: $e");
      }
    }
  }


  Future<void> removeFriend(int userId, int friendId) async {
    Database? mydata = await MyDataBase;
    await mydata!.rawDelete(
      "DELETE FROM Friends WHERE USER_ID = ? AND FRIEND_ID = ?",
      [userId, friendId],
    );
  }

}
