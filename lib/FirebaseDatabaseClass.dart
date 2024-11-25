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

  Future<User?> registerUser(
      String displayName,
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
        // Update the user's displayName in Firebase Authentication
        await user.updateProfile(displayName: displayName).then((_) {
          print("User's displayName updated in Firebase Authentication.");
        }).catchError((e) {
          print("Error updating displayName: $e");
        });

        // Save user data to Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'displayName': displayName,
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
  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      print("User logged out successfully.");
    } catch (e) {
      print("Error during logout: $e");
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
  Future<String?> getFirebaseDisplayName() async {
    // Get the current user from FirebaseAuth
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // If a user is logged in, return the displayName
      print("$user.displayName");
      return user.displayName;
    } else {
      // If no user is logged in, return null
      return null;
    }
  }

}
