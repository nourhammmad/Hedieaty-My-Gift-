import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

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
          db.execute('''
        CREATE TABLE IF NOT EXISTS 'Users' (
          'ID' INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          'NAME' TEXT NOT NULL,
          'EMAIL' TEXT NOT NULL,
          'PASSWORD' TEXT NOT NULL
        )
      ''');

          print("Database has been created .......");
        });
    return mydb;
  }

  String hashPassword(String password) {
    // Generate a hashed password using SHA-256
    var bytes = utf8.encode(password); // Convert password to bytes
    var hashed = sha256.convert(bytes); // Hash the bytes using SHA-256
    return hashed.toString(); // Return the hash as a string
  }

  Future<int> insertUser(String name, String email, String password) async {
    Database? mydata = await MyDataBase;

    // Hash the password before inserting
    String hashedPassword = hashPassword(password);

    int response = await mydata!.insert('Users', {
      'NAME': name,
      'EMAIL': email,
      'PASSWORD': hashedPassword,
    });

    return response;
  }

  readData(String SQL) async {
    Database? mydata = await MyDataBase;
    var response = await mydata!.rawQuery(SQL);
    return response;
  }

  deleteData(String SQL) async {
    Database? mydata = await MyDataBase;
    int response = await mydata!.rawDelete(SQL);
    return response;
  }

  updateData(String SQL) async {
    Database? mydata = await MyDataBase;
    int response = await mydata!.rawUpdate(SQL);
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

    // If the result is not empty, the login is successful
    return result.isNotEmpty;
  }


}
