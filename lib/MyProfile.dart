  import 'dart:io';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
  import 'package:flutter/cupertino.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter_image_compress/flutter_image_compress.dart';
  import 'package:image_picker/image_picker.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
  import 'Database.dart';
  import 'imgur.dart';
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
    String? photoURL; // To store the user's photo URL
    TextEditingController NameController=TextEditingController();
    late bool online;

    Future<void> _checkAndEnableNotifications() async {
      try {
        // Check if permission has already been granted
        final settings = await FirebaseMessaging.instance.getNotificationSettings();

        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          print("Notification Permission Already Granted!");

          // If permission is granted, proceed with subscribing to topics and enabling notifications
          final token = await FirebaseMessaging.instance.getToken();
          print("Notification Enabled. Token: $token");

          // Subscribe to a topic (you can subscribe to more topics or use direct token-based notifications)
          await FirebaseMessaging.instance.subscribeToTopic("general");
          print("Subscribed to 'general' topic.");

        } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
          print("Notification Permission Denied!");
          // Handle permission denial gracefully (e.g., show a message explaining the benefit of enabling notifications)
        } else {
          // Request permission if not determined yet
          final newSettings = await FirebaseMessaging.instance.requestPermission();
          if (newSettings.authorizationStatus == AuthorizationStatus.authorized) {
            print("Notification Permission Granted!");

            // Proceed with subscribing to topics and enabling notifications
            final token = await FirebaseMessaging.instance.getToken();
            print("Notification Enabled. Token: $token");

            await FirebaseMessaging.instance.subscribeToTopic("general");
            print("Subscribed to 'general' topic.");
          } else {
            print("Notification Permission Denied!");
            // Handle permission denial gracefully
          }
        }
      } catch (e) {
        print("Error enabling notifications: $e");
      }
    }
    Future<void> _disableNotifications() async {
      try {
        // Get the current token
        final token = await FirebaseMessaging.instance.getToken();
        print("Notification Disabled. Token: $token");

        // Unsubscribe from topics (you can unsubscribe from multiple topics if needed)
        await FirebaseMessaging.instance.unsubscribeFromTopic("general");
        print("Unsubscribed from 'general' topic.");

        // Optionally, you could delete the token or revoke its use here
      } catch (e) {
        print("Error disabling notifications: $e");
      }
    }

    late Databaseclass _dbHelper;
    late FirebaseDatabaseClass _firebaseDb;
    final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore instance
    List<Map<String, dynamic>> events = []; // List to store fetched events

    File? _profileImage;
    final ImagePicker _imagePicker = ImagePicker();
    @override
    void initState() {
      super.initState();
      _dbHelper = Databaseclass();
      _firebaseDb = FirebaseDatabaseClass();

      _initializeDatabase();
      _fetchUserEvents(); // Fetch events when profile loads
      _fetchUserPhotoURL(); // Fetch user's photo URL
       _loadNotificationsEnabled();  // Fetch the saved notification setting

    }
    Future<void> _saveNotificationsEnabled(bool value) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notificationsEnabled', value);
    }

     Future<void> _loadNotificationsEnabled() async {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        notificationsEnabled = prefs.getBool('notificationsEnabled') ?? false;
      });
    }
    Future<void> _pickImage() async {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _profileImage = File(image.path);  // Update local state immediately
        });

        try {
          // Upload image to Imgur
          String imageUrl = await uploadImageToImgur(image.path);
          // Update photoURL in Firebase
          await _firebaseDb.updatePhotoURL(_firebaseDb.getCurrentUserId(), imageUrl);

          // Update photoURL in the state immediately
          setState(() {
            photoURL = imageUrl;  // Reflect the uploaded image in the UI
          });
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error uploading image: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
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
    Future<void> _fetchUserEvents() async {
      try {
        var internetConnection = InternetConnection(); // Initialize safely
        if (internetConnection != null) {
          online = await internetConnection.hasInternetAccess;
        }
      } catch (e) {
        print("Error checking internet connection: $e");
      }
      if (online) {
        User? user = FirebaseAuth.instance.currentUser;
        String? firebaseDisplayName = await _firebaseDb
            .getFirebaseDisplayName();
        firstName = firebaseDisplayName;

        if (user != null) {
          try {
            DocumentSnapshot userDoc = await _firestore.collection('users').doc(
                user.uid).get();
            if (userDoc.exists) {
              var data = userDoc.data() as Map<String, dynamic>;
              List<dynamic> eventsList = data['events_list'] ?? [];

              setState(() {
                events =
                    eventsList.map((event) => Map<String, dynamic>.from(event))
                        .toList();
              });
            }
          } catch (e) {
            print("Error fetching events: $e");
          }
        }
      }else{
        print("YOU ARE OFFLINE");

      }
    }
    // Fetch the photo URL for the current user from Firestore
  // Fetch the photo URL for the current user from Firestore
    Future<void> _fetchUserPhotoURL() async {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          // Fetch the photo URL, if available
          String? url = await getPhotoURL(user.uid); // Use String? to handle null values
          if (url != null && url.isNotEmpty) {
            setState(() {
              photoURL = url; // Update the state with the fetched URL
            });
          } else {
            setState(() {
              photoURL = null; // Set to null if no photo URL is available
            });
          }
        } catch (e) {
          print("Error fetching photo URL: $e");
          setState(() {
            photoURL = null; // In case of an error, set to null
          });
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
                if(online) {
                  Navigator.pushNamed(context, '/MyPledgedGiftsPage');
                }
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
                    // Use the photoURL from the state directly
                    photoURL != null && photoURL!.isNotEmpty
                        ? ClipOval(
                      child: Image.network(
                        photoURL!,  // Display the user's uploaded photo directly
                        width: 220,
                        height: 220,
                        fit: BoxFit.cover,
                      ),
                    )
                        : ClipOval(
                      child: Icon(
                        Icons.person,  // Default icon if no photoURL
                        size: 220,
                        color: Colors.grey,  // Icon color
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
                        onPressed: _pickImage,  // Call the function to pick and upload an image
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
                      controller: NameController..text=firstName??" ",
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        hintText: firstName,
                      ),

                    ),
                  ),
                  IconButton(
                    icon: Icon(isFirstNameEditable ? Icons.check : Icons.edit),
                    onPressed: () async {
                      if (isFirstNameEditable) {
                        // When done editing, save the new name and update Firebase
                        final updatedName = NameController.text.trim();
                        if (updatedName.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Name cannot be empty')),
                          );
                          return;
                        }

                        try {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            // Update displayName in Firebase Auth
                            await user.updateProfile(displayName: updatedName);
                            await user.reload();
                            final updatedUser = FirebaseAuth.instance.currentUser;

                            // Optionally save the name to Firestore or your database here
                            await _firestore.collection('users').doc(user.uid).update({
                              'displayName': updatedName,
                            });

                            // After updating, toggle edit mode
                            setState(() {
                              isFirstNameEditable = false; // Disable editing
                              firstName = updatedName; // Update the UI with the new name
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Name updated successfully')),
                            );
                          }
                        } catch (e) {
                          // Handle any errors
                          print('Error updating displayName: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to update name')),
                          );
                        }
                      } else {
                        // Toggle to edit mode if not editable
                        setState(() {
                          isFirstNameEditable = true;
                        });
                      }
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

              if (notificationsEnabled) {
                // Enable notifications (e.g., subscribe to FCM topic or enable token)
                _checkAndEnableNotifications();
              } else {
                // Disable notifications (e.g., unsubscribe from FCM topic or disable token)
                _disableNotifications();
              }
              _saveNotificationsEnabled(notificationsEnabled);  // Save the updated setting

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
                            Container(
                              width: 70, // Specify the width of the circle
                              height: 70, // Specify the height of the circle
                              decoration: BoxDecoration(
                                shape: BoxShape.circle, // Makes the container circular
                              ),
                              child: ClipOval(
                                child: event['photoURL'] != null
                                    ? Image.network(
                                  event['photoURL'],
                                  fit: BoxFit.cover,
                                  width: 70,
                                  height: 70,
                                )
                                    : Icon(
                                  Icons.image_not_supported,
                                  color: Colors.red, // Customize the icon color
                                  size: 70, // Icon size inside the circle
                                ),
                              ),
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
                            Container(
                              width: 70, // Specify the width of the circle
                              height: 70, // Specify the height of the circle
                              decoration: BoxDecoration(
                                shape: BoxShape.circle, // Makes the container circular
                              ),
                              child: ClipOval(
                                child: (event['gifts'] != null && event['gifts'].isNotEmpty &&
                                    event['gifts'][0]['photoURL'] != null && event['gifts'][0]['photoURL'].isNotEmpty)
                                    ? Image.network(
                                  event['gifts'][0]['photoURL'], // Fetch the first gift's image URL
                                  fit: BoxFit.cover,
                                  width: 70,
                                  height: 70,
                                )
                                    : Icon(
                                  Icons.image_not_supported,
                                  color: Colors.red, // Customize the icon color
                                  size: 70, // Icon size inside the circle
                                ),
                              ),
                            )

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
