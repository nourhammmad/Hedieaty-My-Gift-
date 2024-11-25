// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'FirebaseDatabaseClass.dart';
// import 'Database.dart';
//
// class SyncService {
//   final FirebaseDatabaseClass firebaseDb = FirebaseDatabaseClass();
//   final Databaseclass localDb = Databaseclass();
//   Future<void> syncUserFromFirebaseByEmail(String email) async {
//     try {
//       // Fetch user data by email
//       Map<String, dynamic>? userData = await fetchUser(email); // Use the method's email parameter here
//       if (userData == null) {
//         print('No user found with email: $email');
//         return; // Stop execution if user is not found
//       }
//
//       String userId = userData['userId']; // Assuming 'userId' is stored in the user data
//       String firstname = userData['FIRSTNAME'];
//       String lastname = userData['LASTNAME'];
//       // Use the email parameter passed into the method, no need to re-define it
//       String password = userData['PASSWORD'];
//       String phoneNumber = userData['PHONENUMBER'];
//
//       // Insert user data into the local database
//       await localDb.insertUser(firstname, lastname, email, password, phoneNumber);
//       print('User synced from Firebase successfully');
//     } catch (e) {
//       print('Error syncing user from Firebase: $e');
//     }
//   }
//
//   // Sync a single user from Firebase to the local database
//   Future<void> syncUser(String userId, String email, String password) async {
//     try {
//       // Ensure user is authenticated
//       User? user = await authenticateUser(email, password);
//       if (user == null) {
//         print('User authentication failed');
//         return; // Stop execution if authentication fails
//       }
//
//       // Fetch user data from Firebase
//       DocumentSnapshot userDoc = await firebaseDb.firestore.collection('users').doc(userId).get();
//       if (userDoc.exists) {
//         var data = userDoc.data() as Map<String, dynamic>;
//         String firstname = data['FIRSTNAME'];
//         String lastname = data['LASTNAME'];
//         String email = data['EMAIL'];
//         String password = data['PASSWORD'];
//         String phoneNumber = data['PHONENUMBER'];
//
//         // Insert user data into the local database
//         await localDb.insertUser(firstname, lastname, email, password, phoneNumber);
//         print('User synced successfully');
//       }
//     } catch (e) {
//       print('Error syncing user: $e');
//     }
//   }
//
//   // Fetch a user by email from Firebase
//   Future<Map<String, dynamic>?> fetchUser(String email) async {
//     try {
//       // Query Firebase to find the user by email
//       QuerySnapshot userDocs = await firebaseDb.firestore
//           .collection('users') // Ensure the collection name is correctly capitalized
//           .where('EMAIL', isEqualTo: email)
//           .get();
//
//       if (userDocs.docs.isNotEmpty) {
//         // If the user exists, return the user's data as a Map
//         var userDoc = userDocs.docs.first.data() as Map<String, dynamic>;
//         return userDoc;
//       } else {
//         // Return null if no user is found with the provided email
//         return null;
//       }
//     } catch (e) {
//       print("Error fetching user: $e");
//       return null;
//     }
//   }
//
//   // Sync all friends for a user from Firebase to the local database
//   Future<void> syncFriends(String userId, String email, String password) async {
//     try {
//       // Ensure user is authenticated
//       User? user = await authenticateUser(email, password);
//       if (user == null) {
//         print('User authentication failed');
//         return; // Stop execution if authentication fails
//       }
//
//       // Fetch friends from Firebase
//       QuerySnapshot friendDocs = await firebaseDb.firestore
//           .collection('friends') // Ensure the collection name is lowercase
//           .where('USER_ID', isEqualTo: userId)
//           .get();
//
//       for (var doc in friendDocs.docs) {
//         String friendId = doc['FRIEND_ID'];
//
//         // Fetch friend's details from Firebase
//         DocumentSnapshot friendDoc =
//         await firebaseDb.firestore.collection('users').doc(friendId).get();
//
//         if (friendDoc.exists) {
//           var friendData = friendDoc.data() as Map<String, dynamic>;
//           String firstname = friendData['FIRSTNAME'];
//           String lastname = friendData['LASTNAME'];
//           String email = friendData['EMAIL'];
//           String phoneNumber = friendData['PHONENUMBER'];
//
//           // Add friend to local database
//           int userIntId = int.parse(userId); // Convert to int if local DB uses integers
//           await localDb.addFriendByPhoneNumber(userIntId, phoneNumber);
//           print('Friend $firstname $lastname synced');
//         }
//       }
//     } catch (e) {
//       print('Error syncing friends: $e');
//     }
//   }
// }
//
// // User authentication function
// Future<User?> authenticateUser(String email, String password) async {
//   try {
//     UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
//       email: email,
//       password: password,
//     );
//     return userCredential.user;
//   } catch (e) {
//     print("Authentication error: $e");
//     return null;
//   }
// }
