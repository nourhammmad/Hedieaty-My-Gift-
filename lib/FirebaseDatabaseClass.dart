import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'UserSession.dart';

class FirebaseDatabaseClass {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Hash the password using SHA-256
  String hashPassword(String password) {
    var bytes = utf8.encode(password); // Convert password to bytes
    var hashed = sha256.convert(bytes); // Hash the bytes using SHA-256
    return hashed.toString(); // Return the hash as a string
  }

  // Register a user
  Future<User?> registerUser(String firstname, String lastname, String email, String password, String phoneNumber) async {
    try {
      // Create the user using Firebase Authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Hash the password before saving it to Firestore
      String hashedPassword = hashPassword(password);

      // Add user details to Firestore
      await _firestore.collection('Users').doc(userCredential.user?.uid).set({
        'FIRSTNAME': firstname,
        'LASTNAME': lastname,
        'EMAIL': email,
        'PASSWORD': hashedPassword,
        'PHONENUMBER': phoneNumber,
      });

      // Return the user
      return userCredential.user;
    } catch (e) {
      print('Error registering user: $e');
      return null;
    }
  }

  // Login the user
  Future<bool> validateLogin(String email, String password) async {
    try {
      User? user = _auth.currentUser;

      // Hash the entered password
      String hashedPassword = hashPassword(password);

      // Query Firestore to find the user with matching email and password hash
      var result = await _firestore
          .collection('Users')
          .where('EMAIL', isEqualTo: email)
          .where('PASSWORD', isEqualTo: hashedPassword)
          .get();

      if (result.docs.isNotEmpty) {
        // Assuming user ID is the document ID and FIRSTNAME is in the document
        String userName = result.docs.first['FIRSTNAME'];

        // Save user session data
        await UserSession.saveUserSession(user!.uid, userName);
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
      var friendDoc = await _firestore.collection('Users').where('PHONENUMBER', isEqualTo: friendPhoneNumber).get();

      if (friendDoc.docs.isNotEmpty) {
        String friendId = friendDoc.docs.first.id;

        // Check if the users are already friends
        var friendCheck = await _firestore.collection('Friends')
            .where('USER_ID', isEqualTo: userId)
            .where('FRIEND_ID', isEqualTo: friendId)
            .get();

        if (friendCheck.docs.isEmpty) {
          // Add the friend if not already added
          await _firestore.collection('Friends').add({
            'USER_ID': userId,
            'FRIEND_ID': friendId,
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
      var result = await _firestore.collection('Friends')
          .where('USER_ID', isEqualTo: userId)
          .get();

      List<Map<String, dynamic>> friendsList = [];
      for (var doc in result.docs) {
        var friendId = doc['FRIEND_ID'];
        var friendData = await _firestore.collection('Users').doc(friendId).get();
        friendsList.add({
          'FIRSTNAME': friendData['FIRSTNAME'],
          'LASTNAME': friendData['LASTNAME'],
          'EMAIL': friendData['EMAIL'],
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
      var result = await _firestore.collection('Friends')
          .where('USER_ID', isEqualTo: userId)
          .where('FRIEND_ID', isEqualTo: friendId)
          .get();

      if (result.docs.isNotEmpty) {
        await _firestore.collection('Friends').doc(result.docs.first.id).delete();
      }
    } catch (e) {
      print('Error removing friend: $e');
    }
  }
}
