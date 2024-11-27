import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'Database.dart';
import 'FirebaseDatabaseClass.dart';

class MyProfile extends StatefulWidget {
  const MyProfile({super.key});

  @override
  State<MyProfile> createState() => _MyProfileState();
}

class _MyProfileState extends State<MyProfile> {
  bool isFirstNameEditable = false;
  bool notificationsEnabled = false;
  String? firstName;

  late Databaseclass _dbHelper;
  late FirebaseDatabaseClass _firebaseDb;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore instance
  List<Map<String, dynamic>> events = []; // List to store fetched events

  @override
  void initState() {
    super.initState();
    _dbHelper = Databaseclass();
    _firebaseDb = FirebaseDatabaseClass();
    _initializeDatabase();
    _fetchUserEvents(); // Fetch events when profile loads
  }

  Future<void> _initializeDatabase() async {
    await _dbHelper.initialize();
    String? firebaseDisplayName = await _firebaseDb.getFirebaseDisplayName();

    if (firebaseDisplayName != null) {
      setState(() {
        firstName = firebaseDisplayName;
      });
    }
  }

  // Fetch events from Firestore for the current user
  Future<void> _fetchUserEvents() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          var data = userDoc.data() as Map<String, dynamic>;
          List<dynamic> eventsList = data['events_list'] ?? [];

          setState(() {
            events = eventsList.map((event) => Map<String, dynamic>.from(event)).toList();
          print("==============================================$events");
          });
        }
      } catch (e) {
        print("Error fetching events: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.indigo),
        backgroundColor: Colors.indigo.shade50,
        title: const Row(
          children: [
            Text(
              "Hedieaty",
              style: TextStyle(
                fontSize: 40,
                fontFamily: "Lobster",
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            Icon(Icons.card_giftcard, color: Colors.indigo, size: 25),
          ],
        ),
        titleSpacing: 69.0,
        toolbarHeight: 70,
        actions: [
          IconButton(
            icon: const Icon(Icons.star, color: Colors.indigo),
            onPressed: () {
              Navigator.pushNamed(context, '/MyPledgedGiftsPage');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profile image and edit button
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  ClipOval(
                    child: Image.asset(
                      'asset/pp1.jpg',
                      width: 220,
                      height: 220,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.indigo,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () {
                        print(events);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // First Name Field
            Row(
              children: [
                Expanded(
                  child: TextField(
                    style: const TextStyle(fontFamily: "Lobster", fontSize: 25),
                    enabled: isFirstNameEditable,
                    controller: TextEditingController(text: firstName),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      hintText: firstName,
                    ),
                    onChanged: (value)async  {
                      firstName = (await _firebaseDb.getFirebaseDisplayName())!;
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(isFirstNameEditable ? Icons.check : Icons.edit),
                  onPressed: () {
                    setState(() {
                      isFirstNameEditable = !isFirstNameEditable;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Notification Toggle
            SwitchListTile(
              title: const Text(
                "Enable Notifications",
                style: TextStyle(
                  fontSize: 30,
                  fontFamily: "Lobster",
                ),
              ),
              value: notificationsEnabled,
              onChanged: (bool value) {
                setState(() {
                  notificationsEnabled = value;
                });
              },
              activeColor: Colors.indigo,
            ),
            const SizedBox(height: 20),

            // Event and Gift List
            Expanded(
              child: ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return Card(
                    elevation: 4.0,
                    margin: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(
                            Icons.image_not_supported,
                            color: Colors.red, // You can customize the icon color
                            size: 70, // Customize the icon size to match the original container
                          ),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  event['title'] ?? 'Event Title',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontFamily: "Lobster",
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  event['gifts'] != null && event['gifts'].isNotEmpty
                                      ? event['gifts'].map((gift) => gift['title']).join(', ')
                                      : 'No Gifts',
                                  style: const TextStyle(fontSize: 16),
                                  textAlign: TextAlign.center,
                                ),

                              ],
                            ),
                          ),
                          Icon(
                            Icons.image_not_supported,
                            color: Colors.red, // You can customize the icon color
                            size: 70, // Customize the icon size to match the original container
                          ),
                        ],
                      ),

                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
