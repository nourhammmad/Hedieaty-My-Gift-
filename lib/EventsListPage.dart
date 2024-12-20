import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:projecttrial/AddEvent.dart';
import 'Database.dart';
import 'GiftListPage.dart';
import 'UserSession.dart';

class EventsListPage extends StatefulWidget {
  final String userId;
  const EventsListPage({super.key, required this.userId});
  @override
  State<EventsListPage> createState() => _EventsListPageState();
}

class _EventsListPageState extends State<EventsListPage> {
   List<Map<String, dynamic>> events = [];
  late String currentUserId;
  late Databaseclass _dbHelper;
  late bool online;
  String sortCriteria = 'Name';

   Future<void> _loadEvents(String userId) async {
    try {
      var internetConnection = InternetConnection();
      if (internetConnection != null) {
        online = await internetConnection.hasInternetAccess;
      }
    } catch (e) {
      print("Error checking internet connection: $e");
    }

    try {
      if (online) {
        currentUserId = FirebaseAuth.instance.currentUser!.uid;
        final FirebaseFirestore _firestore = FirebaseFirestore.instance;
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          List<dynamic> eventsList = userDoc['events_list'] ?? [];
          List<Map<String, dynamic>> updatedEvents = [];
          List<String> firestoreEventIds = [];

          for (var event in eventsList) {
            firestoreEventIds.add(event['eventId']); // Track event IDs from Firestore
            String photoURL = await _fetchEventImage(event['eventId']);
            updatedEvents.add({
              'description': event['description'],
              'eventId': event['eventId'],
              'photoURL': photoURL != null ? photoURL : null,
              'gifts': event['gifts'],
              'status': event['status'],
              'title': event['title'],
              'type': event['type'],
              'dueTo': event['dueTo'],
            });

            Map<String, String> eventData = {
              'type': event['type'],
              'title': event['title'],
              'eventId': event['eventId'],
              'FIRESTORE_USER_ID': currentUserId,
              'status': event['status'],
            };
            _dbHelper.insertEvent(currentUserId, eventData);
          }
          await _dbHelper.deleteEventsNotInFirestore(currentUserId, firestoreEventIds);
          setState(() {
            events = updatedEvents;
          });
        }
      } else {
        _loadEventsFromLocalDatabase();
        print("YOU ARE OFFLINE");
      }
    } catch (e) {
      print("Error loading events: $e");
    }
  }

  Future<void> _loadEventsFromLocalDatabase() async {
    try {
      print("Offline, fetching friends from local database");
      String? currentUserIdoff = await UserSession.getUserId();
      currentUserId=currentUserIdoff!;
      if (currentUserId == null) {
        print("Error: currentUserId is null. Unable to load events list.");
        return;
      }
      List<Map<String, Object?>> localEvents = await _dbHelper.getEventsByUserId(currentUserIdoff!);
      events.clear();

      for (var eventData in localEvents) {
        events.add({
          'title': eventData['title']?.toString() ?? '',
          'type': eventData['type']?.toString() ?? '',
          'status': eventData['status']?.toString() ?? '',
          'eventId': eventData['eventId']?.toString() ?? '',
        });
      }

      setState(() {});
    } catch (e) {
      print("Error loading events from local database: $e");
    }
  }

  Future<String> _fetchEventImage(String eventId) async {
     try {
      var internetConnection = InternetConnection();
      if (internetConnection != null) {
        online = await internetConnection.hasInternetAccess ?? false;
      }
    } catch (e) {
       print("Error checking internet connection: $e");
    }
    if(!online)
      {return '';}
    try {
      final FirebaseFirestore _firestore = FirebaseFirestore.instance;
      final FirebaseAuth _auth = FirebaseAuth.instance;

      User? user = _auth.currentUser;
      if (user != null) {
        String userId = user.uid;

        DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();

        if (userDoc.exists) {
           List<dynamic> eventsList = userDoc['events_list'] ?? [];

           var event = eventsList.firstWhere((event) => event['eventId'] == eventId, orElse: () => null);

          if (event != null) {
             return event['photoURL'] ?? '';
          }
        }
      }
    } catch (e) {
      print("Error fetching event image: $e");
    }

    return '';
  }

  void _showDeleteConfirmationDialog(String eventId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Event',
              style: TextStyle(fontSize: 25, color: Colors.red)),
          content: const Text('Are you sure you want to delete this event?',
              style: TextStyle(fontSize: 28)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pop();
              },
              child: const Text('Cancel', style: TextStyle(fontSize: 25)),
            ),
            TextButton(
              onPressed: () {
                _deleteEvent(eventId);
                Navigator.of(context).pop();
              },
              child: const Text(
                  'Delete', style: TextStyle(color: Colors.red, fontSize: 25)),
            ),
          ],
        );
      },
    );
  }

  void _deleteEvent(String eventId) async {
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
      final FirebaseAuth _auth = FirebaseAuth.instance;
      final FirebaseFirestore _firestore = FirebaseFirestore.instance;

      User? user = _auth.currentUser;
      if (user != null) {
        try {
          String userId = user.uid;

           DocumentReference userDocRef = _firestore.collection('users').doc(userId);

           int eventIndex = events.indexWhere((event) => event['eventId'] == eventId);

          if (eventIndex != -1) {
            var eventToDelete = events[eventIndex];

             if (eventToDelete['photoURL'] == null || eventToDelete['photoURL']!.isEmpty) {
              eventToDelete['photoURL'] = null; // Standardize missing image value
            }

            print("Deleting event: $eventToDelete");

             await userDocRef.update({
              'events_list': FieldValue.arrayRemove([eventToDelete]),
            }).then((_) {
              print("Event deleted successfully from Firestore.");
              setState(() { // Remove event locally
              });
            }).catchError((error) {
              print("Error deleting event from Firestore: $error");
            });
          } else {
            print("Event with ID $eventId not found in local events.");
          }
        } catch (e) {
          print("Error deleting event: $e");
        }
      } else {
        print("No user is currently logged in.");
      }
    } else {
      print("YOU ARE OFFLINE");
    }
  }
   void _sortEvents() {
    switch (sortCriteria) {
      case 'Name':
        events.sort((a, b) => (a['title']?.toLowerCase() ?? '').compareTo(b['title']?.toLowerCase() ?? ''));
        break;
      case 'Category':
        events.sort((a, b) => (a['type'] ?? '').compareTo(b['type'] ?? ''));
        break;
      case 'Status':
        events.sort((a, b) => (a['status'] ?? '').compareTo(b['status'] ?? ''));
        break;
    }

  }

  @override
  void initState() {
    super.initState();
    _dbHelper = Databaseclass();
    _loadEvents(widget.userId);
  }


  @override
  Widget build(BuildContext context) {
    _sortEvents();

    return Scaffold(
      key: const Key('eventsListPage'),
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
            icon: const Icon(Icons.add),
            onPressed: () async {
              if(online){

            final result =await Navigator.push(context,MaterialPageRoute(
      builder: (context) => AddEvent(),
       ),
      );
     if (result != null && result == 'reload') {
          setState(() {
            _loadEvents(widget.userId);
          });
     }}
     },

          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
             Row(
              children: [
                const Icon(Icons.sort, color: Colors.indigo, size: 40),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: sortCriteria,
                  items: const [
                    DropdownMenuItem(value: 'Name',
                        child: Text('Sort by Name',
                            style: TextStyle(fontFamily: "Lobster"))),
                    DropdownMenuItem(value: 'Category',
                        child: Text('Sort by Category',
                            style: TextStyle(fontFamily: "Lobster"))),
                    DropdownMenuItem(value: 'Status',
                        child: Text('Sort by Status',
                            style: TextStyle(fontFamily: "Lobster"))),
                  ],
                  onChanged: (value) {
                    setState(() {
                      if (value != null) {
                        sortCriteria = value;
                      }
                      _sortEvents();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            events.isEmpty
                ? Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_busy,
                      size: 200,
                      color: Colors.indigo.shade100,
                    ),
                  ],
                ),
              ),
            )
                : Expanded(
              child: ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return InkWell(
                    key: Key(event['title']),
                    onTap: () async {

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GiftListPage(eventId: event['eventId']!),
                        ),
                      );
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      elevation: 4.0,
                      margin: const EdgeInsets.symmetric(vertical: 10.0),
                      child: Column(
                        children: [
                           event['photoURL']?.isNotEmpty == true
                              ? Container(
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(15.0)),
                              image: DecorationImage(
                                image: NetworkImage(event['photoURL']!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                              : Container(
                            height: 200,
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                size: 50,
                                color: Colors.red,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event['title'] ?? 'Unnamed Event',
                                  style: const TextStyle(
                                    fontSize: 40,
                                    fontFamily: "Lobster",
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo,
                                  ),
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  "Category: ${event['type'] ?? 'Uncategorized'}",
                                  style: const TextStyle(fontSize: 30, fontFamily: "Lobster"),
                                ),
                                Text(
                                  "Status: ${event['status'] ?? 'Unknown'}",
                                  style: const TextStyle(fontSize: 30, fontFamily: "Lobster"),
                                ),
                                Text(
                                  "Due Date: ${event['dueTo'] ?? 'Unknown'}",
                                  style: const TextStyle(fontSize: 30, fontFamily: "Lobster"),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (event['status'] != 'Past')
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.green, size: 30),
                                onPressed: () async {
                                  final result =await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddEvent(id:event['eventId'],title: event['title'],description:event['description'],status:event['status'],type:event['type'] ,imageUrl:event['photoURL'],date:event['dueTo']),
                                    ),
                                  );
                                  if (result != null && result == 'reload') {
                                    setState(() {
                                       _loadEvents(widget.userId);
                                    });
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 30),
                                onPressed: () {
                                  _showDeleteConfirmationDialog(event['eventId']);
                                },
                              ),
                            ],
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