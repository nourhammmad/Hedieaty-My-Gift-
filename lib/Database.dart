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

    int Version = 1;

    initialize() async {
      String mypath = await getDatabasesPath();
      String path = join(mypath, 'Hedeaty.db');
      Database mydb = await openDatabase(path, version: Version,
          onCreate: (db, Version) async {
            // Create the Users table
            await db.execute(''' 
            CREATE TABLE IF NOT EXISTS 'Users' (
              'ID' INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              'FIRSTNAME' TEXT NOT NULL,
              'LASTNAME' TEXT NOT NULL,
              'EMAIL' TEXT NOT NULL,
              'PASSWORD' TEXT NOT NULL,
              'PHONENUMBER' TEXT
            )
          ''');

            // Create the Friends table to track friendships between users
            await db.execute(''' 
            CREATE TABLE IF NOT EXISTS 'Friends' (
              'USER_ID' INTEGER NOT NULL,
              'FRIEND_ID' INTEGER NOT NULL,
              PRIMARY KEY ('USER_ID', 'FRIEND_ID'),
              FOREIGN KEY ('USER_ID') REFERENCES 'Users'('ID') ON DELETE CASCADE,
              FOREIGN KEY ('FRIEND_ID') REFERENCES 'Users'('ID') ON DELETE CASCADE
            )
          ''');

            await db.execute('PRAGMA foreign_keys = ON');

          });
      return mydb;
    }

    String hashPassword(String password) {
      // Generate a hashed password using SHA-256
      var bytes = utf8.encode(password); // Convert password to bytes
      var hashed = sha256.convert(bytes); // Hash the bytes using SHA-256
      return hashed.toString(); // Return the hash as a string
    }

    // Insert a user with phone number
    Future<int> insertUser(String firstname, String lastname, String email, String password, String phoneNumber) async {
      Database? mydata = await MyDataBase;

      // Hash the password before inserting
      String hashedPassword = hashPassword(password);

      int response = await mydata!.insert('Users', {
        'FIRSTNAME': firstname,
        'LASTNAME': lastname,
        'EMAIL': email,
        'PASSWORD': hashedPassword,
        'PHONENUMBER': phoneNumber, // Include phone number in the insert
      });

      return response;
    }

    Future<List<Map<String, dynamic>>> readData(String sql, List<dynamic> parameters) async {
      Database? mydata = await MyDataBase;
      var response = await mydata!.rawQuery(sql, parameters);
      return response;
    }

    deleteData(String SQL) async {
      Database? mydata = await MyDataBase;
      int response = await mydata!.rawDelete(SQL);
      return response;
    }

    mydeletedatabase() async {
      String database = await getDatabasesPath();
      String Path = join(database, 'Hedeaty.db');
      bool ifitexist = await databaseExists(Path);
      if (ifitexist == true) {
        print('it exists');
      } else {
        print("it doesn't exist");
      }
      await deleteDatabase(Path);
      print("Database has been deleted");
    }

    // Method to validate user login
    Future<bool> validateLogin(String email, String password) async {
      Database? mydata = await MyDataBase;

      // Hash the entered password
      String hashedPassword = hashPassword(password);

      // Query the database to find a user with the matching email and password
      var result = await mydata!.rawQuery(
        "SELECT * FROM Users WHERE EMAIL = ? AND PASSWORD = ?",
        [email, hashedPassword],
      );

      if (result.isNotEmpty) {
        // Assuming user ID is the primary key (ID) and user name is 'FIRSTNAME'
        int userId = result[0]['ID'] as int;
        String userName = result[0]['FIRSTNAME'] as String;

        // Save user session data
        await UserSession.saveUserSession(userId, userName);
        return true;
      } else {
        return false;
      }
    }

    // Update user data
    Future<int> updateData(String query, List<dynamic> args) async {
      Database? mydata = await MyDataBase;
      int response = await mydata!.rawUpdate(query, args);
      return response;
    }

    // Add a friend by phone number
    Future<void> addFriendByPhoneNumber(int userId, String friendPhoneNumber) async {
      Database? mydata = await MyDataBase;

      // Query to get the friend's user ID by phone number
      var result = await mydata!.rawQuery(
        "SELECT ID FROM Users WHERE PHONENUMBER = ?",
        [friendPhoneNumber],
      );

      if (result.isNotEmpty) {
        // Get the friend's user ID
        int friendId = result[0]['ID'] as int;

        // Check if the users are already friends
        var friendCheck = await mydata.rawQuery(
          "SELECT * FROM Friends WHERE USER_ID = ? AND FRIEND_ID = ?",
          [userId, friendId],
        );

        if (friendCheck.isEmpty) {
          // Add the friend if not already added
          await mydata.insert('Friends', {
            'USER_ID': userId,
            'FRIEND_ID': friendId,
          });
        }
      } else {
        throw Exception('Friend with phone number $friendPhoneNumber not found');
      }
    }

    // Get a list of friends for a user
    Future<List<Map<String, dynamic>>> getFriends(int userId) async {
      Database? mydata = await MyDataBase;

      // Query to fetch friends of a user
      var result = await mydata!.rawQuery(
        "SELECT u.FIRSTNAME, u.LASTNAME, u.EMAIL FROM Users u "
            "JOIN Friends f ON u.ID = f.FRIEND_ID WHERE f.USER_ID = ?",
        [userId],
      );
      return result;
    }

    // Remove a friend
    Future<void> removeFriend(int userId, int friendId) async {
      Database? mydata = await MyDataBase;

      // Delete the friend from the database
      await mydata!.rawDelete(
        "DELETE FROM Friends WHERE USER_ID = ? AND FRIEND_ID = ?",
        [userId, friendId],
      );
    }
  }
