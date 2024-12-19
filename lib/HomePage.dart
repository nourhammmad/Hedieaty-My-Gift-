import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
  List<Map<String, String>> filteredFriends = []; // Filtered list for search results

  @override
    void initState()  {
      super.initState();
      key: Key('HomePage');  // Assign a key here
      _dbHelper = Databaseclass();
      _firebaseDb=FirebaseDatabaseClass();
      _dbHelper = Databaseclass();
      _loadFriendsList();
      _requestNotificationPermission();
    }
  void _requestNotificationPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission();
     if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("User granted permission for notifications.");
       String? token = await messaging.getToken();
       _saveFcmTokenToFirestore(token!);
     } else {
      print("User declined or has not accepted permission for notifications.");
    }
  }
  void _saveFcmTokenToFirestore(String token) async {
    String userId = FirebaseAuth.instance.currentUser!.uid; // Replace with your user ID
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'fcmToken': token,
    });
  }
  Future<String?> fetchPhotoURL(String userId) async {
    bool online = false;
    try {
      var internetConnection = InternetConnection();
      if (internetConnection != null) {
        online = await internetConnection.hasInternetAccess ?? false;
      }
    } catch (e) {
       print("Error checking internet connection: $e");
    }
    if(!online)
      return '';
    try {
      String? photoURL = await getPhotoURL(userId);
      return photoURL ?? '';
    } catch (e) {
      print('Error fetching photo URL: $e');
      return '';
    }
  }
  Future<void> _loadFriendsList() async {
    bool online = false;
    try {
      var internetConnection = InternetConnection(); // Initialize safely
      if (internetConnection != null) {
        online = await internetConnection.hasInternetAccess ?? false;
      }
    } catch (e) {
       print("Error checking internet connection: $e");
    }
     if (online) {
      try {
        currentUserId = FirebaseAuth.instance.currentUser!.uid;
        print("Online, fetch from Firestore and update local database");
        DocumentSnapshot currentUserDoc = await FirebaseFirestore.instance.collection('friend_list').doc(currentUserId).get();
        if (currentUserDoc.exists) {
          List<dynamic> friendIds = currentUserDoc['friends'] ?? [];
          List<Future<void>> friendFetchTasks = [];
          friends.clear();
          List<String> firestoreFriendIds = [];
          for (var friendId in friendIds) {
            friendFetchTasks.add(FirebaseFirestore.instance.collection('users').doc(friendId).get().then((doc) async {
              if (doc.exists) {
                 Map<String, String> friendData = {
                  'displayName': doc['displayName'],
                  'phoneNumber': doc['phoneNumber'],
                  'friendId': friendId,
                };
                 friends.add(friendData);
                firestoreFriendIds.add(friendData['friendId']!);
                _dbHelper.insertFriend(currentUserId, friendData);
              }
            }));
          }
          await _dbHelper.deleteFriendsNotInFirestore(currentUserId, firestoreFriendIds);
          await Future.wait(friendFetchTasks);
          filteredFriends = List.from(friends);
           setState(() {});
        }
      } catch (e) {
        print("Error fetching friends from Firestore: $e");
      }
    } else {
       _loadFriendsFromLocalDatabase();
    }
  }
   Future<void> _loadFriendsFromLocalDatabase() async {
     try {
      print("Offline, fetching friends from local database");
      String? currentUserIdoff = await UserSession.getUserId();
      currentUserId=currentUserIdoff!;
      if (currentUserId == null) {
        print("Error: currentUserId is null. Unable to load friends list.");
        return;
      }
      List<Map<String, Object?>> localFriends = await _dbHelper.getFriendsByUserId(currentUserIdoff!);
       friends.clear();
      for (var friendData in localFriends) {
        friends.add({
          'friendId': friendData['friendId']?.toString() ?? '',
          'displayName': friendData['displayName']?.toString() ?? '',
          'phoneNumber': friendData['phoneNumber']?.toString() ?? '',
        });
      }
      filteredFriends = List.from(friends);
      setState(() {});
    } catch (e) {
      print("Error loading friends from local database: $e");
    }
  }
  void _showAddFriendDialog(String currentUserId) {
    TextEditingController phoneNumberController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(
            child: Text("Add Friend",style: TextStyle(
              fontSize: 35,
              fontFamily: "Lobster",
              color: Colors.indigo,
            ),
            ),
          ),
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
                       ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Adding friend...")),
                      );
                      _addFriendToFirestore(currentUserId, phoneNumber);
                      Navigator.pop(context);  // Close the dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Friend added successfully!")),
                      );
                    }
                  } else {
                    print("No user found with this phone number.");
                     ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("No user found with this phone number.")),
                    );
                  }
                } else {
                  print("Phone number cannot be empty.");
                   ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Phone number cannot be empty.")),
                  );
                }
              },
              child: Text("Add Friend" ,style: TextStyle(
        fontSize: 26,
        fontFamily: "Lobster",
        color: Colors.indigo,
        ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel", style: TextStyle(
        fontSize: 26,
        fontFamily: "Lobster",
        color: Colors.red,
        ),),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _checkIfUserExistsByPhone(String phoneNumber) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .get();
      if (snapshot.docs.isNotEmpty) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("Error checking phone number: $e");
      return false;
    }
  }
  Future<bool> _checkIfAlreadyFriend(String currentUserId, String friendPhoneNumber) async {
    try {
       QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('phoneNumber', isEqualTo: friendPhoneNumber)
          .get();
      if (snapshot.docs.isNotEmpty) {
        String friendId = snapshot.docs.first.id;  // Get the friend ID from the document
        DocumentSnapshot currentUserDoc = await FirebaseFirestore.instance.collection('friend_list').doc(currentUserId).get();
        if (currentUserDoc.exists) {
          List<dynamic> friendsList = currentUserDoc['friends'] ?? [];
          if (friendsList.contains(friendId)) {
            return true;
          }
        }
        return false;
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
      CollectionReference friendListRef = FirebaseFirestore.instance.collection('friend_list');
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('phoneNumber', isEqualTo: friendPhoneNumber)
          .get();
      if (snapshot.docs.isNotEmpty) {
        String friendId = snapshot.docs.first.id;  // Get the friend ID from the document
        DocumentSnapshot currentUserDoc = await friendListRef.doc(currentUserId).get();
        if (currentUserDoc.exists) {
           await friendListRef.doc(currentUserId).update({
            'friends': FieldValue.arrayUnion([friendId]),
          });
        } else {
           await friendListRef.doc(currentUserId).set({
            'friends': [friendId],
          });
        }
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
        _loadFriendsList();
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
  void _filterFriends(String query) {
    setState(() {
      filteredFriends = friends.where((friend) {
        final displayName = friend['displayName']?.toLowerCase() ?? '';
        final phoneNumber = friend['phoneNumber']?.toLowerCase() ?? '';
        final searchLower = query.toLowerCase();
        return displayName.contains(searchLower) || phoneNumber.contains(searchLower);
      }).toList();
    });
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
                child: TextField(
                  autofocus: true,
                  onChanged: (query) {
                    _filterFriends(query);
                  },
                  decoration: const InputDecoration(
                    hintText: 'Search friends',
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.indigo),
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    filteredFriends = List.from(friends); // Reset the list
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
            key: Key('Drawer'), // Added key here

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
                key: Key('My Events'), // Added key here
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
        key: Key('HomePage'), // Added key here
        children: [
          Column(
            children: [
              GestureDetector(
                key: Key('createEventButton'), // Added key here
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
                  itemCount: filteredFriends.length,
                  itemBuilder: (context, index) {
                    final friend = friends[index];
                    return FutureBuilder<String?>(
                      future: fetchPhotoURL(friend['friendId']!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                           return FriendListItem(
                            displayName: friend['displayName']!,
                            phoneNumber: friend['phoneNumber']!,
                            friendId: friend['friendId']!,
                            image: '', onFriendDeleted: null,
                            currentUserId: currentUserId,
                          );
                        } else if (snapshot.hasError) {
                           return FriendListItem(
                            displayName: friend['displayName']!,
                            phoneNumber: friend['phoneNumber']!,
                            friendId: friend['friendId']!,
                            image: '', onFriendDeleted: null,
                            currentUserId: currentUserId,
                          );
                        } else if (snapshot.hasData) {
                           return FriendListItem(
                            displayName: friend['displayName']!,
                            phoneNumber: friend['phoneNumber']!,
                            friendId: friend['friendId']!,
                            image: snapshot.data, onFriendDeleted: _loadFriendsList,
                            currentUserId: currentUserId,
                          );
                        } else {
                           return FriendListItem(
                            displayName: friend['displayName']!,
                            phoneNumber: friend['phoneNumber']!,
                            friendId: friend['friendId']!,
                            image: '', onFriendDeleted: _loadFriendsList,
                            currentUserId: currentUserId,
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
class FriendListItem extends StatelessWidget {
  final String displayName;
  final String phoneNumber;
  final String? image;
  final String friendId;
  final dynamic onFriendDeleted;
  final String currentUserId;
  const FriendListItem({
    Key? key,
    required this.displayName,
    required this.phoneNumber,
    required this.image,
    required this.friendId,
    required this.onFriendDeleted,
    required this.currentUserId,
  }) : super(key: key);
  Future<int> getEventCount(String userId) async {
    bool online = false;
    try {
      var internetConnection = InternetConnection(); // Initialize safely
      if (internetConnection != null) {
        online = await internetConnection.hasInternetAccess ?? false;
      }
    } catch (e) {
       print("Error checking internet connection: $e");
    }
    if (online) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        if (userDoc.exists) {
           final data = userDoc.data() as Map<String, dynamic>?;
          if (data != null) {
            if (data['events_list'] is List) {
              final eventsList = data['events_list'] as List;
              return eventsList.length;
            } else {
              return 0;
            }
          } else {
            print('Document data is null');
            return 0;
          }
        } else {
          print('Document does not exist');
          return 0;
        }
      } catch (e) {
        print('Error fetching event count: $e');
        return 0;
      }
    }else{
      return 0;
    }
  }
  void _deleteFriendFromFirestore(String currentUserId, String friendId) async {
    try {
      CollectionReference friendListRef = FirebaseFirestore.instance.collection('friend_list');
      await friendListRef.doc(currentUserId).update({
        'friends': FieldValue.arrayRemove([friendId]),
      });
      DocumentSnapshot friendDoc = await friendListRef.doc(friendId).get();
      if (friendDoc.exists) {
        await friendListRef.doc(friendId).update({
          'friends': FieldValue.arrayRemove([currentUserId]),
        });
      }
      print("Friend deleted successfully!");
      onFriendDeleted();
    } catch (e) {
      print("Error deleting friend: $e");

    }
  }
  @override
  Widget build(BuildContext context) {
    final String imageUrl = image?.isNotEmpty == true ? image! : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0, horizontal: 10.0),
      child: Row(
        children: [
           Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: imageUrl.isEmpty ? Colors.indigo.shade100 : null,
              image: imageUrl.isNotEmpty
                  ? DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              )
                  : null,
            ),
            child: imageUrl.isEmpty
                ? const Center(
              child: Icon(
                Icons.account_circle,
                size: 60,
                color: Colors.indigo,
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
           Expanded(
            child: GestureDetector(
              onTap: () {
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
                    key: Key('$displayName'),
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
                      fontSize: 20,
                      color: Colors.grey,
                      fontFamily: "Lobster",
                    ),
                  ),
                  const SizedBox(height: 4),
                  FutureBuilder<int>(
                    future: getEventCount(friendId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                         return const Text(
                          "Loading events...",
                          style: TextStyle(
                            fontSize: 19,
                            color: Colors.grey,
                            fontFamily: "Lobster",
                          ),
                        );
                      } else if (snapshot.hasError) {
                         return const Text(
                          "Error loading events",
                          style: TextStyle(
                            fontSize: 19,
                            color: Colors.red,
                            fontFamily: "Lobster",
                          ),
                        );
                      } else if (!snapshot.hasData || snapshot.data == 0) {
                         return const Text(
                          "No Upcoming events",
                          style: TextStyle(
                            fontSize: 22,
                            color: Colors.grey,
                            fontFamily: "Lobster",
                          ),
                        );
                      } else {
                         return Text(
                          "Events: ${snapshot.data}",
                          style: const TextStyle(
                            fontSize: 22,
                            fontFamily: "Lobster",
                            color: Colors.indigo,
                          ),
                        );
                      }
                    },
                  )
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              _deleteFriendFromFirestore(currentUserId, friendId);
            },
          ),
        ],
      ),
    );
  }
}
