import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendsGiftList extends StatefulWidget {
  final String userId;
  final String eventId;
  final String userName;

  const FriendsGiftList({Key? key, required this.userId, required this.eventId,required this.userName}) : super(key: key);

  @override
  State<FriendsGiftList> createState() => _FriendsGiftListState();
}

class _FriendsGiftListState extends State<FriendsGiftList> {


  List<Map<String, dynamic>> gifts = [];
  bool isLoading = true; // To show a loading indicator

  @override
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;



      if (widget.userId.isNotEmpty && widget.eventId.isNotEmpty) {
        _loadGifts();
      } else {
        setState(() {
          isLoading = false; // Stop loading if no valid arguments
        });
        print('Error: Missing or invalid arguments.');
      }
    });
  }

  Future<String> _fetchGiftImage(String eventId, String giftId) async {
    try {
      final FirebaseFirestore _firestore = FirebaseFirestore.instance;

      if (widget.userId != null) {
        // Fetch the user's document
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(widget.userId).get();

        if (userDoc.exists) {
          // Access the events array from the user's document
          List<dynamic> eventsList = userDoc['events_list'] ?? [];

          // Find the event by its eventId
          var event = eventsList.firstWhere((event) => event['eventId'] == widget.eventId, orElse: () => null);

          if (event != null) {
            // Find the gift inside the event by its giftId
            var gift = event['gifts']?.firstWhere((gift) => gift['giftId'] == giftId, orElse: () => null);

            if (gift != null) {
              // Return the photoURL from the gift
              return gift['photoURL'] ?? '';
            }
          }
        }
      }
    } catch (e) {
      print("Error fetching gift image: $e");
    }

    return ''; // Return an empty string if image fetching fails
  }

  Future<void> _loadGifts() async {
    try {
      final FirebaseFirestore _firestore = FirebaseFirestore.instance;

      if (widget.userId.isNotEmpty) {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(widget.userId).get();

        if (userDoc.exists) {
          List<dynamic> eventsList = userDoc['events_list'] ?? [];

          var event = eventsList.firstWhere(
                (e) => e['eventId'] == widget.eventId,
            orElse: () => null,
          );

          if (event != null && event['gifts'] != null) {
            List<Map<String, dynamic>> updatedGifts = [];

            for (var gift in event['gifts']) {
              String photoURL = await _fetchGiftImage(widget.eventId, gift['giftId']);
              updatedGifts.add({
                'PledgedBy': gift['PledgedBy'],
                'category': gift['category'],
                'createdBy': gift['createdBy'],
                'description': gift['description'],
                'dueTo': gift['dueTo'],
                'eventId': widget.eventId,
                'giftId': gift['giftId'],
                'photoURL': photoURL,
                'price': gift['price'],
                'status': gift['status'],
                'title': gift['title'],
              });
            }

            setState(() {
              gifts = updatedGifts;
            });
          }
        }
      }
    } catch (e) {
      print('Error loading gifts: $e');
    } finally {
      setState(() {
        isLoading = false; // Stop the loading spinner regardless of success
      });
    }
  }



  String sortCriteria = 'Name';

  void _sortGifts() {
    switch (sortCriteria) {
      case 'Name':
        gifts.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
        break;
      case 'Category':
        gifts.sort((a, b) => (a['category'] ?? '').compareTo(b['category'] ?? ''));
        break;
      case 'Status':
        gifts.sort((a, b) => (a['status'] ?? '').compareTo(b['status'] ?? ''));
        break;
    }
  }

  Color _getCardColor(String status) {
    if (status == 'Pledged') {

      return Colors.red.shade100; // Color for pledged gifts
    } else {
      return Colors.green.shade100; // Color for available gifts
    }
  }
  Color _getButtonColor(String status) {
    if (status == 'Pledged') {

      return Colors.grey; // Color for pledged gifts
    } else {
      return Colors.indigo; // Color for available gifts
    }
  }
  bool WhichText(status){

    if (status == 'Pledged') {

      return true; // Color for pledged gifts
    } else {
      return false; // Color for available gifts
    }
  }
  void _pledgeGift(String giftId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print("Error: User is not logged in.");
        return;
      }

      final pledgerId = currentUser.uid;

      // Find the selected gift from the list
      final gift = gifts.firstWhere(
            (gift) => gift['giftId'] == giftId,
        orElse: () => {},
      );

      if (gift == null) {
        print("Error: Gift not found.");
        return;
      }

      final eventId = gift['eventId'];

      if (eventId == null) {
        print("Error: Missing eventId.");
        return;
      }

      // Debugging: Print gift and eventId
      print("Gift being pledged: $gift");
      print("Searching for eventId: $eventId");

      // Get the friend's document (not the current user)
      final friendUserId = gift['createdBy'];  // Assuming the gift creator (friend) has the 'createdBy' field
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(friendUserId); // Friend's userId

      // Fetch the user's data (events and pledged gifts)
      final userDocSnapshot = await userDocRef.get();
      if (!userDocSnapshot.exists) {
        throw Exception("User document not found.");
      }

      final eventsList = List<Map<String, dynamic>>.from(userDocSnapshot.data()?['events_list'] ?? []);
      print("events_list: $eventsList");

      // Find the correct event in the friend's event list
      final eventIndex = eventsList.indexWhere((event) => event['eventId'] == eventId);
      if (eventIndex == -1) {
        throw Exception("Event not found.");
      }

      final event = eventsList[eventIndex];
      final giftsList = List<Map<String, dynamic>>.from(event['gifts'] ?? []);
      final giftIndex = giftsList.indexWhere((g) => g['giftId'] == giftId);

      if (giftIndex == -1) {
        throw Exception("Gift not found.");
      }

      // Prepare the updates
      giftsList[giftIndex]['PledgedBy'] = pledgerId;  // The current user pledges the gift
      giftsList[giftIndex]['status'] = 'Pledged';
      eventsList[eventIndex]['gifts'] = giftsList;


      // Fetch the current user's document
      final currentUserDocRef = FirebaseFirestore.instance.collection('users').doc(pledgerId);
      final currentUserDocSnapshot = await currentUserDocRef.get();

      if (!currentUserDocSnapshot.exists) {
        throw Exception("Current user document not found.");
      }

      final currentUserPledgedGiftsList = List<Map<String, dynamic>>.from(currentUserDocSnapshot.data()?['pledged_gifts'] ?? []);
      currentUserPledgedGiftsList.add({
        'pledgerId': friendUserId,  // The logged-in user who is pledging the gift
        'eventId': eventId,
        'giftId': giftId,
        'status':"Pending",
      });

      // Now, run the transaction to apply the changes
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Update the friend's document with the updated events list
        transaction.update(userDocRef, {
          'events_list': eventsList,  // Save the updated events list
        });

        // Update the current user's pledged_gifts list
        transaction.update(currentUserDocRef, {
          'pledged_gifts': currentUserPledgedGiftsList,  // Update pledged_gifts for current user
        });
      });

      // Update the local state for the UI
      setState(() {
        final localGiftIndex = gifts.indexWhere((g) => g['giftId'] == giftId);
        if (localGiftIndex != -1) {
          gifts[localGiftIndex]['PledgedBy'] = pledgerId;  // Current user pledges the gift
          gifts[localGiftIndex]['status'] = 'Pledged';
        }
      });

      print("Gift pledged successfully.");
    } catch (e) {
      print("Error pledging gift: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    _sortGifts(); // Sort gifts before building the UI

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.indigo),
        backgroundColor: Colors.indigo.shade50,
        title: Row(
          children: [
            Text(
              widget.userName,
              style: const TextStyle(
                fontSize: 40,
                fontFamily: "Lobster",
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            Icon(Icons.card_giftcard, color: Colors.indigo, size: 25),
          ],
        ),
        titleSpacing: 50.0,
        toolbarHeight: 70,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Row(
              children: [
                CircleAvatar(backgroundColor: Colors.red, radius: 5),
                SizedBox(width: 5),
                Text("Pledged Gifts", style: TextStyle(fontFamily: "Lobster", fontSize: 25)),
                SizedBox(width: 20),
                CircleAvatar(backgroundColor: Colors.green, radius: 5),
                SizedBox(width: 5),
                Text("Available Gifts", style: TextStyle(fontFamily: "Lobster", fontSize: 25)),
                SizedBox(width: 20),
              ],
            ),
            const SizedBox(height: 10),
            isLoading
                ? const Center(child: CircularProgressIndicator()) // Show loading indicator
                : gifts.isEmpty
                ? const Center(child: Text('No gifts available.')) // Show no gifts message
                : Expanded(
              child: ListView.builder(
                itemCount: gifts.length,
                itemBuilder: (context, index) {
                  final gift = gifts[index];
                  final isPledged = gift['pledged'] ?? false;
                  final status = gift['status'] ?? 'Unknown';
                  final dueTo = gift['dueTo'] ?? 'Not Decided';
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    elevation: 4.0,
                    margin: const EdgeInsets.symmetric(vertical: 10.0),
                    color: _getCardColor(status), // Use the updated color logic
                    child: Column(
                      children: [
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(15.0)),

                          ),
                          child: gift['photoURL'] == null || gift['photoURL'].isEmpty
                              ? Center(
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.red, // You can customize the icon color
                              size: 100, // Customize the icon size
                            ),
                          )
                              : Image.network(
                            width: double.infinity, // Make sure image fills the width
                            height: double.infinity, // Make
                  gift['photoURL'],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                  return Center(
                  child: Icon(
                  Icons.error,
                  color: Colors.red,
                  size: 50,
                  ),
                  );
                  },
                  ),
                   // No icon if an image is available
                        ),

                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                gift['title'] ?? 'Unnamed Gift',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              Text(
                                "Category: ${gift['category'] ?? 'Uncategorized'}",
                                style: const TextStyle(fontSize: 18),
                              ),
                              Text(
                                "Status: ${status}",
                                style: const TextStyle(fontSize: 18),
                              ),
                              Text(
                                "Due Data: ${dueTo}",
                                style: const TextStyle(fontSize: 18),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _getButtonColor(status),
                            ),
                            onPressed: isPledged ? null : () => _pledgeGift(gift['giftId']),  // Pass the giftId here
                            child: Text(
                              WhichText(status) ? 'Already Pledged' : 'Pledge Gift',
                              style: TextStyle(color: Colors.indigo.shade50, fontFamily: "Lobster", fontSize: 30),
                            ),
                          ),
                        ),

                      ],
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