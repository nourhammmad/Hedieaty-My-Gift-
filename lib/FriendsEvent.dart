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
  bool _isLoading = true;

  // Sorting criteria
  String sortCriteria = 'Name';

  // Function to fetch events from Firestore
  Future<void> _loadEvents(String userId) async {
    print("Loading events for userId: $userId");

    try {
      final FirebaseFirestore _firestore = FirebaseFirestore.instance;

      // Fetch user document
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        // Get the list of events or an empty list
        List<dynamic> eventsList = userDoc['events_list'] ?? [];

        // Handle case where there are no events
        if (eventsList.isEmpty) {
          setState(() {
            _isLoading = false;
            events = []; // Clear events
          });
          return; // Exit early
        }

        // Fetch event images asynchronously
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

        // Update state with fetched events
        setState(() {
          _isLoading = false;
          events = updatedEvents;
        });
      } else {
        // User document doesn't exist
        setState(() {
          _isLoading = false;
          events = []; // No events to display
        });
      }
    } catch (e) {
      // Handle errors and update state
      print("Error loading events: $e");
      setState(() {
        _isLoading = false;
        events = []; // Clear events on error
      });
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
  Widget build(BuildContext context) {
    _sortEvents(); // Sort events whenever the build method is called
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.indigo),
        backgroundColor: Colors.indigo.shade50,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center, // Centers the content

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
      ),
      body:  _isLoading?const Center(child: CircularProgressIndicator())
      :Padding(
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
                  ?  Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_busy, // Use an icon that represents no events
                      size: 200,
                      color: Colors.indigo.shade100, // A subtle color for the icon
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
                    key: Key(event['title']),  // Add a unique key for each event

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