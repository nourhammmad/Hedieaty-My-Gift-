import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'UserSession.dart';

class FirebaseDatabaseClass {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore get firestore => _firestore;

  // Hash the password using SHA-256
  String hashPassword(String password) {
    var bytes = utf8.encode(password); // Convert password to bytes
    var hashed = sha256.convert(bytes); // Hash the bytes using SHA-256
    return hashed.toString(); // Return the hash as a string
  }

  // Register a user
  Future<User?> registerUser(
      String firstname,
      String lastname,
      String email,
      String password,
      String phoneNumber,
      ) async {
    try {
      // Create the user with Firebase Authentication
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Log UserCredential for debugging
      print("========================UserCredential: ${credential.toString()}");

      // After the user is created, get the current user
      User? user = credential.user;

      if (user != null) {
        // Save user data to Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'firstname': firstname,
          'lastname': lastname,
          'email': email,
          'phoneNumber': phoneNumber,
          'photoURL': null,
        }).then((_) {
          print("User data saved successfully for userId: ${user.uid}");
        }).catchError((e) {
          print("Error saving user data: $e");
        });

        return user; // Return the user object after successful registration
      } else {
        print("User object is null after registration.");
      }
    } catch (e) {
      print("Error registering user: $e");
      print("Detailed Error: ${e.toString()}");
    }

    return null; // Return null if registration fails
  }

  // Login the user
  Future<bool> validateLogin(String email, String password) async {
    try {
      // Hash the entered password
      String hashedPassword = hashPassword(password);

      // Query Firestore to find the user with matching email and password hash
      var result = await _firestore
          .collection('users')  // Ensure the correct collection name is used here ('users')
          .where('email', isEqualTo: email)  // Match email
          .where('password', isEqualTo: hashedPassword)  // Match hashed password
          .get();

      if (result.docs.isNotEmpty) {
        // Assuming user data is stored in Firestore correctly, extract necessary details
        String userName = result.docs.first['firstname'];

        // Save user session data (if applicable)
        await UserSession.saveUserSession(result.docs.first.id, userName);
        return true;
      }
    } catch (e) {
      print('Login error: $e');
    }
    return false;
  }

  // Add a friend by phone number
  Future<void> addFriendByPhoneNumber(String userId, String friendPhoneNumber) async {
    try {
      // Fetch the friend's user ID using the phone number
      var friendDoc = await _firestore.collection('users').where('phone', isEqualTo: friendPhoneNumber).get();

      if (friendDoc.docs.isNotEmpty) {
        String friendId = friendDoc.docs.first.id;

        // Check if the users are already friends
        var friendCheck = await _firestore.collection('friends')
            .where('user_id', isEqualTo: userId)
            .where('friend_id', isEqualTo: friendId)
            .get();

        if (friendCheck.docs.isEmpty) {
          // Add the friend if not already added
          await _firestore.collection('friends').add({
            'user_id': userId,
            'friend_id': friendId,
          });
        }
      } else {
        throw Exception('Friend with phone number $friendPhoneNumber not found');
      }
    } catch (e) {
      print('Error adding friend: $e');
    }
  }

  // Get a list of friends for a user
  Future<List<Map<String, dynamic>>> getFriends(String userId) async {
    try {
      var result = await _firestore.collection('friends')
          .where('user_id', isEqualTo: userId)
          .get();

      List<Map<String, dynamic>> friendsList = [];
      for (var doc in result.docs) {
        var friendId = doc['friend_id'];
        var friendData = await _firestore.collection('users').doc(friendId).get();
        friendsList.add({
          'firstname': friendData['firstname'],
          'lastname': friendData['lastname'],
          'email': friendData['email'],
        });
      }
      return friendsList;
    } catch (e) {
      print('Error fetching friends: $e');
      return [];
    }
  }

  // Remove a friend
  Future<void> removeFriend(String userId, String friendId) async {
    try {
      // Delete the friend relationship from Firestore
      var result = await _firestore.collection('friends')
          .where('user_id', isEqualTo: userId)
          .where('friend_id', isEqualTo: friendId)
          .get();

      if (result.docs.isNotEmpty) {
        await _firestore.collection('friends').doc(result.docs.first.id).delete();
      }
    } catch (e) {
      print('Error removing friend: $e');
    }
  }
}
