  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'dart:convert';
  import 'package:crypto/crypto.dart';
  import 'UserSession.dart';
  
  class FirebaseDatabaseClass {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final FirebaseAuth _auth = FirebaseAuth.instance;
    FirebaseFirestore get firestore => _firestore;
  

    Future<User?> registerUser(String displayName, String email, String password, String phoneNumber, String? photoUrl) async {
      try {
         final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('phoneNumber', isEqualTo: phoneNumber)
            .get();
print("===============$querySnapshot");
         if (querySnapshot.docs.isNotEmpty) {
          print("A user with this phone number already exists.");
          return null;
        }

         final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );


         User? user = credential.user;

        if (user != null) {
           await user.updateProfile(displayName: displayName).then((_) {
            print("User's displayName updated in Firebase Authentication.");
          }).catchError((e) {
            print("Error updating displayName: $e");
          });

           await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'displayName': displayName,
            'email': email,
            'phoneNumber': phoneNumber,
            'photoURL': photoUrl,
          }).then((_) {
            print("User data saved successfully for userId: ${user.uid}");
          }).catchError((e) {
            print("Error saving user data: $e");
          });

          return user;
        } else {
          print("User object is null after registration.");
        }
      } catch (e) {
        print("Error registering user: $e");
        print("Detailed Error: ${e.toString()}");
      }

      return null;
    }


    Future<void> updatePhotoURL(String userId, String? photoUrl) async {
      try {
         User? user = FirebaseAuth.instance.currentUser;

         if (user != null && user.uid == userId) {
           if (photoUrl != null && photoUrl.isNotEmpty) {
            await user.updatePhotoURL(photoUrl).then((_) {
              print("User's photoUrl updated in Firebase Authentication.");
            }).catchError((e) {
              print("Error updating photoUrl in Firebase Authentication: $e");
            });
          } else {
            print("photoUrl is null or empty, skipping update in Firebase Authentication.");
          }

           await FirebaseFirestore.instance.collection('users').doc(userId).update({
            'photoURL': photoUrl,
          }).then((_) {
            print("photoURL successfully updated in Firestore.");
          }).catchError((e) {
            print("Error updating photoURL in Firestore: $e");
          });
        } else {
          print("User not logged in or userId does not match.");
        }
      } catch (e) {
        print("Error updating photoURL: $e");
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

    String getCurrentUserId() {
      User? user = FirebaseAuth.instance.currentUser;
      return user!.uid; // Return the UID of the current logged-in user
    }

    Future<String?> getFirebaseDisplayName() async {
       User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
           DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          if (userDoc.exists) {
             String? displayName = userDoc['displayName'];
            print("Fetched displayName from Firestore: $displayName");
            return displayName;
          } else {
            print("User document does not exist in Firestore.");
            return null;
          }
        } catch (e) {
          print("Error fetching displayName from Firestore: $e");
          return null;
        }
      } else {
         return null;
      }
    }

  }

