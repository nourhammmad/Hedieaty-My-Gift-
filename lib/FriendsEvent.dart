import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:projecttrial/FriendsGiftList.dart';


import 'GiftListPage.dart';

class FriendsEvent extends StatefulWidget {
  final String userId;
  final String userName;

  const FriendsEvent({Key? key, required this.userId, required this.userName}) : super(key: key);

  @override
  State<FriendsEvent> createState() => _FriendsEventState();
}

class _FriendsEventState extends State<FriendsEvent> {
  // List to store events fetched from Firestore
  List<Map<String, dynamic>> events = [];

  // Sorting criteria
  String sortCriteria = 'Name';

  // Function to fetch events from Firestore
  Future<void> _loadEvents(String userId) async {
    print("Loading events for userId: $userId");

    try {
      final FirebaseFirestore _firestore = FirebaseFirestore.instance;

      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        List<dynamic> eventsList = userDoc['events_list'] ?? [];

        // Fetch the event images asynchronously
        List<Map<String, dynamic>> updatedEvents = [];
        for (var event in eventsList) {
          String photoURL = await _fetchEventImage(event['eventId']);
          updatedEvents.add({
            'description': event['description'],
            'eventId': event['eventId'],
            'photoURL': photoURL,
            'gifts': event['gifts'],
            'status': event['status'],
            'title': event['title'],
            'type': event['type'],
          });
        }
        setState(() {

          events = updatedEvents;
        });
      }
    } catch (e) {
      print("Error loading events: $e");
    }
  }


  Future<String> _fetchEventImage(String eventId) async {
    try {
      final FirebaseFirestore _firestore = FirebaseFirestore.instance;


        // Fetch the user's document
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(widget.userId).get();

        if (userDoc.exists) {
          // Access the events array from the user's document
          List<dynamic> eventsList = userDoc['events_list'] ?? [];

          // Find the event by its eventId
          var event = eventsList.firstWhere((event) => event['eventId'] == eventId, orElse: () => null);

          if (event != null) {
            // Return the photoURL from the event
            return event['photoURL'] ?? '';
          }
        }

    } catch (e) {
      print("Error fetching event image: $e");
    }

    return '';  // Return an empty string if image fetching fails
  }



  // Function to show a confirmation dialog before deleting an event
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
                    .pop(); // Close the dialog without doing anything
              },
              child: const Text('Cancel', style: TextStyle(fontSize: 25)),
            ),
            TextButton(
              onPressed: () {
                _deleteEvent(eventId);
                Navigator.of(context).pop(); // Close the dialog after deletion
              },
              child: const Text(
                  'Delete', style: TextStyle(color: Colors.red, fontSize: 25)),
            ),
          ],
        );
      },
    );
  }

  // Function to delete an event
  void _deleteEvent(String eventId) async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    User? user = _auth.currentUser;
    if (user != null) {
      try {
        String userId = user.uid;

        // Reference to the user's document in Firestore
        DocumentReference userDocRef = _firestore.collection('users').doc(
            userId);

        // Find the index of the event in the list based on eventId
        int eventIndex = events.indexWhere((event) =>
        event['eventId'] == eventId);

        if (eventIndex != -1) {
          // Debugging: Print out eventId to confirm
          print(
              "Attempting to delete event with ID: $eventId at index $eventIndex");

          // Get the event to delete (from the found index)
          var eventToDelete = events[eventIndex];
          print("================================$eventToDelete");
          // Remove the event from the events_list in Firestore based on its index
          await userDocRef.update({
            'events_list': FieldValue.arrayRemove([eventToDelete]),
          }).then((_) {
            print("Event deleted successfully from Firestore.");

            // Remove the event from the UI (locally)
            setState(() {
              events.removeAt(eventIndex); // Remove event based on its index
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
  }

  // Function to sort events
  void _sortEvents() {
    switch (sortCriteria) {
      case 'Name':
        events.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
        break;
      case 'type':
        events.sort((a, b) =>
            (a['type'] ?? '').compareTo(b['type'] ?? ''));
        break;
      case 'Status':
        events.sort((a, b) => (a['status'] ?? '').compareTo(b['status'] ?? ''));
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadEvents(widget.userId);
  }

  @override
  @override
  Widget build(BuildContext context) {
    _sortEvents(); // Sort events whenever the build method is called

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.indigo),
        backgroundColor: Colors.indigo.shade50,
        title: Row(
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  widget.userName,
                  style: const TextStyle(
                    fontSize: 40,
                    fontFamily: "Lobster",
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
              ),
            ),
            Icon(Icons.card_giftcard, color: Colors.indigo, size: 25),
          ],
        ),

        titleSpacing: 69.0,
        toolbarHeight: 70,

      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Dropdown for sorting criteria
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
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            events.isEmpty
                ? const Center(child: Text('No events created yet.'))
                : Expanded(
              child: ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return InkWell(
                    onTap: () {
                      // Navigate to the GiftListPage
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FriendsGiftList(userId:widget.userId,eventId: event['eventId'],userName: widget.userName, ),
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
                          // Check if image exists or not
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
                              ],
                            ),
                          ),
                          // Row(
                          //   mainAxisAlignment: MainAxisAlignment.end,
                          //   children: [
                          //     IconButton(
                          //       icon: const Icon(Icons.edit, color: Colors.green, size: 30),
                          //       onPressed: () {
                          //         Navigator.pushNamed(context, '/EditEvent', arguments: event);
                          //       },
                          //     ),
                          //     IconButton(
                          //       icon: const Icon(Icons.delete, color: Colors.red, size: 30),
                          //       onPressed: () {
                          //         _showDeleteConfirmationDialog(event['eventId']);
                          //       },
                          //     ),
                          //   ],
                          // ),
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