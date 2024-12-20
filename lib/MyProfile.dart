  import 'dart:io';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
  import 'package:flutter/cupertino.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter_image_compress/flutter_image_compress.dart';
  import 'package:image_picker/image_picker.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:projecttrial/UserSession.dart';
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
    String? photoURL;
    TextEditingController NameController=TextEditingController();
    late bool online;
    late Databaseclass _dbHelper;
    late FirebaseDatabaseClass _firebaseDb;
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    List<Map<String, dynamic>> events = [];
    File? _profileImage;
    final ImagePicker _imagePicker = ImagePicker();

    Future<void> _checkAndEnableNotifications() async {
      try {
        final settings = await FirebaseMessaging.instance.getNotificationSettings();
        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          print("Notification Permission Already Granted!");
          final token = await FirebaseMessaging.instance.getToken();
          print("Notification Enabled. Token: $token");
          await FirebaseMessaging.instance.subscribeToTopic("general");
          print("Subscribed to 'general' topic.");
        } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
          print("Notification Permission Denied!");
         } else {
           final newSettings = await FirebaseMessaging.instance.requestPermission();
          if (newSettings.authorizationStatus == AuthorizationStatus.authorized) {
            print("Notification Permission Granted!");
            final token = await FirebaseMessaging.instance.getToken();
            print("Notification Enabled. Token: $token");
            await FirebaseMessaging.instance.subscribeToTopic("general");
            print("Subscribed to 'general' topic.");
          } else {
            print("Notification Permission Denied!");
           }
        }
      } catch (e) {
        print("Error enabling notifications: $e");
      }
    }

    Future<void> _disableNotifications() async {
      try {
        final token = await FirebaseMessaging.instance.getToken();
        print("Notification Disabled. Token: $token");

        await FirebaseMessaging.instance.unsubscribeFromTopic("general");
        print("Unsubscribed from 'general' topic.");

       } catch (e) {
        print("Error disabling notifications: $e");
      }
    }

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
          _profileImage = File(image.path);
        });
        try {
           String imageUrl = await uploadImageToImgur(image.path);
           await _firebaseDb.updatePhotoURL(_firebaseDb.getCurrentUserId(), imageUrl);
           setState(() {
            photoURL = imageUrl;
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
        var internetConnection = InternetConnection();
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
        firstName=await UserSession.getUserName();
        print("YOU ARE OFFLINE");
      }
    }

    Future<void> _fetchUserPhotoURL() async {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
           String? url = await getPhotoURL(user.uid);
          if (url != null && url.isNotEmpty) {
            setState(() {
              photoURL = url;
            });
          } else {
            setState(() {
              photoURL = null;
            });
          }
        } catch (e) {
          print("Error fetching photo URL: $e");
          setState(() {
            photoURL = null;
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
               Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                     photoURL != null && photoURL!.isNotEmpty
                        ? ClipOval(
                      child: Image.network(
                        photoURL!,
                        width: 220,
                        height: 220,
                        fit: BoxFit.cover,
                      ),
                    )
                        : ClipOval(
                      child: Icon(
                        Icons.person,
                        size: 220,
                        color: Colors.grey,
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
                        onPressed: _pickImage,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

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
                             await user.updateProfile(displayName: updatedName);
                            await user.reload();
                             await _firestore.collection('users').doc(user.uid).update({
                              'displayName': updatedName,
                            });

                             setState(() {
                              isFirstNameEditable = false;
                              firstName = updatedName;
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Name updated successfully')),
                            );
                          }
                        } catch (e) {
                           print('Error updating displayName: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to update name')),
                          );
                        }
                      } else {
                         setState(() {
                          isFirstNameEditable = true;
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
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
                 _checkAndEnableNotifications();
              } else {
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
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
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
                                  color: Colors.red,
                                  size: 70,
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
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              child: ClipOval(
                                child: (event['gifts'] != null && event['gifts'].isNotEmpty &&
                                    event['gifts'][0]['photoURL'] != null && event['gifts'][0]['photoURL'].isNotEmpty)
                                    ? Image.network(
                                  event['gifts'][0]['photoURL'],
                                  fit: BoxFit.cover,
                                  width: 70,
                                  height: 70,
                                )
                                    : Icon(
                                  Icons.image_not_supported,
                                  color: Colors.red,
                                  size: 70,
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
