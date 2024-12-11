import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'Database.dart';
import 'EventsListPage.dart';
import 'FirebaseDatabaseClass.dart';
import 'FriendsEvent.dart';
import 'UserSession.dart';
import 'imgur.dart';
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isPressed = false; // Track the button state
  bool _isSearching = false; // Track the state of the search bar
  late Databaseclass _dbHelper;
  List<Map<String, String>> friends = []; // State variable for friends
  late FirebaseDatabaseClass _firebaseDb; // Use FirebaseDatabaseClass
  late String currentUserId;
  bool isLoading = true;
  bool isOnline = false;
  @override
  void initState() {
    super.initState();
    print("=======================DAKHALT=====================");
    _dbHelper = Databaseclass();
    _firebaseDb=FirebaseDatabaseClass();

    //currentUserId = FirebaseAuth.instance.currentUser!.uid;
    _initializeDatabase();
    _loadFriendsList();
  }
  Future<String?> fetchPhotoURL(String userId) async {
    bool online = false; // Default value in case of failure
    try {
      var internetConnection = InternetConnection(); // Initialize safely
      if (internetConnection != null) {
        online = await internetConnection.hasInternetAccess ?? false;
      }
    } catch (e) {
      // Handle exceptions, such as if the method throws an error
      print("Error checking internet connection: $e");
    }
    if(!online)
      return '';
    try {
      String? photoURL = await getPhotoURL(userId); // Fetch the URL using your function
      return photoURL ?? ''; // Return empty string if photoURL is null
    } catch (e) {
      print('Error fetching photo URL: $e');
      return ''; // Return empty string if the fetch fails
    }
  }

  Future<void> _loadFriendsList() async {
    // Check connectivity status
    bool online = false; // Default value in case of failure
    try {
      var internetConnection = InternetConnection(); // Initialize safely
      if (internetConnection != null) {
        online = await internetConnection.hasInternetAccess ?? false;
      }
    } catch (e) {
      // Handle exceptions, such as if the method throws an error
      print("Error checking internet connection: $e");
    }
    print("=======LESSA MADAKAHLTSH=============");
    // If online, fetch from Firestore and update local database
    if (online) {
      try {
        currentUserId = FirebaseAuth.instance.currentUser!.uid;
        print("Online, fetch from Firestore and update local database");
        DocumentSnapshot currentUserDoc = await FirebaseFirestore.instance.collection('friend_list').doc(currentUserId).get();

        if (currentUserDoc.exists) {
          List<dynamic> friendIds = currentUserDoc['friends'] ?? [];
          List<Future<void>> friendFetchTasks = [];

          // Clear the current list of friends before adding new ones
          friends.clear();

          for (var friendId in friendIds) {
            // Fetch user data for each friend
            friendFetchTasks.add(FirebaseFirestore.instance.collection('users').doc(friendId).get().then((doc) async {
              if (doc.exists) {
                // Create friend data map
                Map<String, String> friendData = {
                  'displayName': doc['displayName'],
                  'phoneNumber': doc['phoneNumber'],
                  'friendId': friendId,
                };

                // Add friend to the list (UI update)
                friends.add(friendData);

                // Insert into local database for offline use
                _dbHelper.insertFriend(currentUserId, friendData);  // Pass currentUserId to insertFriend

              }

            }));
          }
          // List<Map<String, String>> users = await _dbHelper.getFriends();
          //
          // // Print the users' details
          // for (var user in users) {
          //   print('User ID: ${user['userId']}');
          //   print('Firebase ID: ${user['friendId']}');
          //   print('Display Name: ${user['displayName']}');
          //   print('Email: ${user['email']}');
          //   print('Phone: ${user['phone']}');
          //   print('Friends: ${user['friends']}');
          //   print('---------------------------');
          // }
          // List<Map<String, Object?>> localFriends = await _dbHelper.getFriendsByUserId(currentUserId);
          //
          // // Print the fetched friends list
          // for (var friend in localFriends) {
          //   print("Friend:");
          //   print("friendId: ${friend['friendId']}");
          //   print("displayName: ${friend['displayName']}");
          //   print("phoneNumber: ${friend['phoneNumber']}");
          //   print("---------------------------");
          // }

          // Wait for all Firestore fetch tasks to complete
          await Future.wait(friendFetchTasks);

          // Once all friends are loaded, call setState to rebuild the UI
          setState(() {});
        }
      } catch (e) {
        print("Error fetching friends from Firestore: $e");
      }
    } else {
      // If offline, load from local database
      _loadFriendsFromLocalDatabase();
    }
  }


// Load friends from local database when offline
  Future<void> _loadFriendsFromLocalDatabase() async {
    print("======================DALHALT BARDO-========");
    try {
      print("Offline, fetching friends from local database");
      String? currentUserId = await UserSession.getUserId();
      if (currentUserId == null) {
        print("Error: currentUserId is null. Unable to load friends list.");
        return;
      }
      // Assuming currentUserId is already available
      // Fetch friends of the current user from the local database
      List<Map<String, Object?>> localFriends = await _dbHelper.getFriendsByUserId(currentUserId!);

      // Clear the existing list of friends before adding new ones
      friends.clear();

      for (var friendData in localFriends) {
        // Add friend to the list (UI update)
        // Ensure proper type casting from Object? to String
        friends.add({
          'friendId': friendData['friendId']?.toString() ?? '',
          'displayName': friendData['displayName']?.toString() ?? '',
          'phoneNumber': friendData['phoneNumber']?.toString() ?? '',
        });
      }

      // Update UI
      setState(() {});
    } catch (e) {
      print("Error loading friends from local database: $e");
    }
  }


  Future<void> _initializeDatabase() async {
    await _dbHelper.initialize();
  }
  // final List<Map<String, String>> friends = [
  // ];


  void _showAddFriendDialog(String currentUserId) {
    TextEditingController phoneNumberController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Add Friend"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: phoneNumberController,
                decoration: InputDecoration(labelText: 'Enter Friend\'s Phone Number'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                String phoneNumber = phoneNumberController.text.trim();
                if (phoneNumber.isNotEmpty) {
                  // Show a Snackbar while checking the user
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Checking user...")),
                  );

                  bool userExists = await _checkIfUserExistsByPhone(phoneNumber);
                  if (userExists) {
                    // Show a Snackbar while checking if friend is already in list
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Checking if already friends...")),
                    );

                    bool isAlreadyFriend = await _checkIfAlreadyFriend(currentUserId, phoneNumber);
                    if (isAlreadyFriend) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("You are already friends with this user.")),
                      );
                      Navigator.pop(context);  // Close the dialog
                    } else {
                      // Show a Snackbar while adding the friend
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Adding friend...")),
                      );

                      _addFriendToFirestore(currentUserId, phoneNumber);
                      Navigator.pop(context);  // Close the dialog
                      // Show success Snackbar
                      ScaffoldMessenger.of(context).showSnackBar(

                        SnackBar(content: Text("Friend added successfully!")),
                      );
                    }
                  } else {
                    print("No user found with this phone number.");
                    // Show error Snackbar
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("No user found with this phone number.")),
                    );
                  }
                } else {
                  print("Phone number cannot be empty.");
                  // Show error Snackbar
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Phone number cannot be empty.")),
                  );
                }
              },
              child: Text("Add Friend"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);  // Close the dialog without adding a friend
              },
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _checkIfUserExistsByPhone(String phoneNumber) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')  // Assuming your users are stored in the 'users' collection
          .where('phoneNumber', isEqualTo: phoneNumber)  // Query users by phone number field
          .get();

      if (snapshot.docs.isNotEmpty) {
        return true;  // User with this phone number exists
      } else {
        return false;  // No user with this phone number found
      }
    } catch (e) {
      print("Error checking phone number: $e");
      return false;
    }
  }

  Future<bool> _checkIfAlreadyFriend(String currentUserId, String friendPhoneNumber) async {
    try {
      // Find the friendId using phone number
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('phoneNumber', isEqualTo: friendPhoneNumber)
          .get();

      if (snapshot.docs.isNotEmpty) {
        String friendId = snapshot.docs.first.id;  // Get the friend ID from the document

        // Check if the friend is already in the current user's friend list
        DocumentSnapshot currentUserDoc = await FirebaseFirestore.instance.collection('friend_list').doc(currentUserId).get();

        if (currentUserDoc.exists) {
          List<dynamic> friendsList = currentUserDoc['friends'] ?? [];
          if (friendsList.contains(friendId)) {
            return true;  // Friend already exists
          }
        }
        return false;  // Friend does not exist in the list
      } else {
        print("No user found with this phone number.");
        return false;
      }
    } catch (e) {
      print("Error checking if already friends: $e");
      return false;
    }
  }

  void _addFriendToFirestore(String currentUserId, String friendPhoneNumber) async {
    try {
      // Reference to the user's friend list
      CollectionReference friendListRef = FirebaseFirestore.instance.collection('friend_list');

      // Find the friendId using phone number
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('phoneNumber', isEqualTo: friendPhoneNumber)
          .get();

      if (snapshot.docs.isNotEmpty) {
        String friendId = snapshot.docs.first.id;  // Get the friend ID from the document

        // Check if the friend list document for the current user exists
        DocumentSnapshot currentUserDoc = await friendListRef.doc(currentUserId).get();

        if (currentUserDoc.exists) {
          // Update the friend's list for the current user
          await friendListRef.doc(currentUserId).update({
            'friends': FieldValue.arrayUnion([friendId]),
          });
        } else {
          // If no document exists, create a new document with the friend's ID
          await friendListRef.doc(currentUserId).set({
            'friends': [friendId],
          });
        }

        // Optionally, update the friend list for the friend as well
        DocumentSnapshot friendDoc = await friendListRef.doc(friendId).get();
        if (!friendDoc.exists) {
          await friendListRef.doc(friendId).set({
            'friends': [currentUserId],
          });
        } else {
          await friendListRef.doc(friendId).update({
            'friends': FieldValue.arrayUnion([currentUserId]),
          });
        }

        print("Friend added successfully!");

        // After adding the friend, reload the friends list
        _loadFriendsList();  // Call _loadFriendsList() to refresh the UI
      } else {
        print("No user found with this phone number.");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No user found with this phone number.")),
        );
      }
    } catch (e) {
      print("Error adding friend: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred while adding the friend.")),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo.shade50,
        title: _isSearching
            ? AnimatedContainer(
          key: ValueKey('searchBar'),
          duration: const Duration(milliseconds: 600),
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: Colors.indigo.shade300),
              const SizedBox(width: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    final friend = friends[index];
                    return FutureBuilder<String?>(
                      future: fetchPhotoURL(friend['friendId']!), // Fetch photo URL for each friend
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          // While waiting for the photo URL, show a loading indicator
                          return FriendListItem(
                            displayName: friend['displayName']!,
                            phoneNumber: friend['phoneNumber']!,
                            friendId: friend['friendId']!,
                            image: '', // Pass an empty string or a placeholder image while loading
                          );
                        } else if (snapshot.hasError) {
                          // Handle any errors that occur while fetching the photo URL
                          return FriendListItem(
                            displayName: friend['displayName']!,
                            phoneNumber: friend['phoneNumber']!,
                            friendId: friend['friendId']!,
                            image: '', // Handle error case by passing an empty string
                          );
                        } else if (snapshot.hasData) {
                          // Successfully fetched the photo URL
                          return FriendListItem(
                            displayName: friend['displayName']!,
                            phoneNumber: friend['phoneNumber']!,
                            friendId: friend['friendId']!,
                            image: snapshot.data, // Pass the fetched photo URL
                          );
                        } else {
                          // If no data is available, show a fallback
                          return FriendListItem(
                            displayName: friend['displayName']!,
                            phoneNumber: friend['phoneNumber']!,
                            friendId: friend['friendId']!,
                            image: '', // Fallback to empty string if no photo URL
                          );
                        }
                      },
                    );
                  },
                ),
              ),

              IconButton(
                icon: const Icon(Icons.close, color: Colors.indigo),
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                  });
                },
              ),
            ],
          ),
        )
            : const Row(
          key: ValueKey('appName'),
          children: [
            Text(
              "Hedieaty",
              style: TextStyle(
                fontSize: 45,
                fontFamily: "Lobster",
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            SizedBox(width: 8),
            Icon(
              Icons.card_giftcard,
              color: Colors.indigo,
              size: 25,
            ),
          ],
        ),
        titleSpacing: 25.0,
        toolbarHeight: 70,
        leading: Builder(
          builder: (context) => IconButton(
            onPressed: () {
              Scaffold.of(context).openDrawer(); // Open the drawer
            },
            alignment: Alignment.topLeft,
            icon: const Icon(Icons.menu, size: 35, color: Colors.indigo),
          ),
        ),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search, size: 30, color: Colors.indigo),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/MyProfile');
            },
            alignment: Alignment.topRight,
            icon: const Icon(
              Icons.account_circle_outlined,
              size: 35,
              color: Colors.indigo,
            ),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Colors.indigo.shade50,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
              ),
              child: Icon(Icons.card_giftcard_outlined,
                  size: 500, color: Colors.indigo.shade100),
              height: 220,
            ),
            ListTile(
              leading: Icon(Icons.event, color: Colors.indigo, size: 45),
              title: const Text(
                'My Events',
                style: TextStyle(
                    fontSize: 50,
                    fontFamily: "Lobster",
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo),
              ),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventsListPage(userId:currentUserId ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red, size: 45),
              title: const Text(
                'Logout',
                style: TextStyle(
                    fontSize: 50,
                    fontFamily: "Lobster",
                    fontWeight: FontWeight.bold,
                    color: Colors.red),
              ),
              onTap: () async {
                Navigator.pop(context); // Close the drawer
                // Navigate to the logout page or handle the logout functionality
                await _firebaseDb.logout();
                await UserSession.clearUserSession();

                Navigator.pushNamed(context, '/Login'); // Example navigation
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              GestureDetector(
                onTapDown: (_) {
                  setState(() {
                    _isPressed = true;
                    Navigator.pushNamed(context,'/GiftOrEvent');

                  });
                },
                onTapUp: (_) {
                  setState(() {
                    _isPressed = false;
                  });
                },
                onTapCancel: () {
                  setState(() {
                    _isPressed = false;
                  });
                },
                child: Container(
                  height: 60,
                  width: double.infinity,
                  margin: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade100,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Center(

                    child: Text(
                      'Create Your Own Event/List',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: "Lobster",
                        color: _isPressed
                            ? Colors.blueGrey.shade800
                            : Colors.indigo.shade400,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    final friend = friends[index];
                    return FutureBuilder<String?>(
                      future: fetchPhotoURL(friend['friendId']!), // Fetch photo URL for each friend
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          // While waiting for the photo URL, show a loading indicator
                          return FriendListItem(
                            displayName: friend['displayName']!,
                            phoneNumber: friend['phoneNumber']!,
                            friendId: friend['friendId']!,
                            image: '', // Pass an empty string or a placeholder image while loading
                          );
                        } else if (snapshot.hasError) {
                          // Handle any errors that occur while fetching the photo URL
                          return FriendListItem(
                            displayName: friend['displayName']!,
                            phoneNumber: friend['phoneNumber']!,
                            friendId: friend['friendId']!,
                            image: '', // Handle error case by passing an empty string
                          );
                        } else if (snapshot.hasData) {
                          // Successfully fetched the photo URL
                          return FriendListItem(
                            displayName: friend['displayName']!,
                            phoneNumber: friend['phoneNumber']!,
                            friendId: friend['friendId']!,
                            image: snapshot.data, // Pass the fetched photo URL
                          );
                        } else {
                          // If no data is available, show a fallback
                          return FriendListItem(
                            displayName: friend['displayName']!,
                            phoneNumber: friend['phoneNumber']!,
                            friendId: friend['friendId']!,
                            image: '', // Fallback to empty string if no photo URL
                          );
                        }
                      },
                    );
                  },
                ),
              ),

            ],
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () {
                _showAddFriendDialog(_firebaseDb.getCurrentUserId());
              },
              backgroundColor: Colors.indigo.shade100,
              child: Icon(
                Icons.person_add,
                color: Colors.indigo.shade400,
                size: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget to display each friend with a fading image and info
class FriendListItem extends StatelessWidget {
  final String displayName;
  final String phoneNumber;
  final String? image; // image is nullable
  final String friendId;

  const FriendListItem({
    Key? key,
    required this.displayName,
    required this.phoneNumber,
    required this.image,
    required this.friendId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Safe handling for nullable image
    final String imageUrl = image?.isNotEmpty == true ? image! : ''; // If image is null or empty, fallback to empty string

    // Print image URL to console for debugging
    //print('===============================Image URL: $imageUrl'); // Prints the image URL to the console

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0, horizontal: 10.0),
      child: Row(
        children: [
          // Profile Image or fallback icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: imageUrl.isEmpty ? Colors.indigo.shade100 : null, // Background color if no image
              image: imageUrl.isNotEmpty
                  ? DecorationImage(
                image: NetworkImage(imageUrl), // Assuming image is a URL
                fit: BoxFit.cover,
              )
                  : null, // No image, so no background image
            ),
            child: imageUrl.isEmpty
                ? const Center(
              child: Icon(
                Icons.account_circle,
                size: 60,
                color: Colors.indigo, // Default icon color
              ),
            )
                : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.4),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Friend Info
          Expanded(
            child: GestureDetector(
              onTap: () {
                // Navigate to Friend's Gift List
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FriendsEvent(userId:friendId,userName: displayName ),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      fontFamily: "Lobster",
                      color: Colors.indigo
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    phoneNumber,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                      fontFamily: "Lobster",
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "No Upcoming Events", // Example status
                    style: TextStyle(
                      fontSize: 19,
                      color: Colors.grey,
                      fontFamily: "Lobster",
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Delete Icon Button
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              // Add delete logic here (if needed)
            },
          ),
        ],
      ),
    );
  }
}
