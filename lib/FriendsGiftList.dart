import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendsGiftList extends StatefulWidget {
  final String userId;
  final String userName;

  const FriendsGiftList({Key? key, required this.userId, required this.userName}) : super(key: key);

  @override
  State<FriendsGiftList> createState() => _FriendsGiftListState();
}

class _FriendsGiftListState extends State<FriendsGiftList> {
  late String userId;
  late String userName;

  List<Map<String, dynamic>> gifts = [];
  bool isLoading = true; // To show a loading indicator

  @override
  void initState() {
    super.initState();

    // Delay context-dependent code using WidgetsBinding
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      if (arguments != null) {
        setState(() {
          userId = arguments['friendId']; // Get userId (friendId)
          userName = arguments['friendName']; // Get userName (friendName)
        });

        // Fetch the gifts only after userId and userName are set
        _loadGifts();
      } else {
        print('Error: No arguments provided.');
      }
    });
  }

  Future<void> _loadGifts() async {
    try {
      // Use the userId passed from the other page (no need to fetch it from FirebaseAuth)
      if (userId.isEmpty) return;

      // Get the user's document
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final eventsList = userDoc.data()?['events_list'] as List<dynamic>?;

        if (eventsList != null) {
          setState(() {
            gifts = [];
            // Iterate through the events and collect all gifts
            for (var event in eventsList) {
              if (event['gifts'] != null) {
                gifts.addAll(List<Map<String, dynamic>>.from(event['gifts']));
              }
            }
            // Set loading to false once gifts are loaded (even if empty)
            isLoading = false;
          });

          // Print the gifts list to the console
          print('Loaded gifts: $gifts');
        } else {
          // Set loading to false if no eventsList is found
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading gifts: $e');
      setState(() {
        isLoading = false; // Ensure loading is stopped in case of error
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
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(userId); // Friend's userId

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userDocSnapshot = await transaction.get(userDocRef);

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

        // Update the gift status to pledged and assign pledger
        giftsList[giftIndex]['PledgedBy'] = pledgerId;
        giftsList[giftIndex]['status'] = 'Pledged';
        eventsList[eventIndex]['gifts'] = giftsList;

        transaction.update(userDocRef, {'events_list': eventsList});
      });

      // Update the local state for the UI
      setState(() {
        final localGiftIndex = gifts.indexWhere((g) => g['giftId'] == giftId);
        if (localGiftIndex != -1) {
          gifts[localGiftIndex]['PledgedBy'] = pledgerId;
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
              userName,
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
                            // image: DecorationImage(
                            //   image: gift['image'] != null && gift['image'].isNotEmpty
                            //       ? AssetImage(gift['image'])
                            //       : AssetImage('asset/placeholder.png'),
                            //   fit: BoxFit.cover,
                            // ),
                          ),
                          child: gift['image'] == null || gift['image'].isEmpty
                              ? Center(
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.red, // You can customize the icon color
                              size: 100, // Customize the icon size
                            ),
                          )
                              : null, // No icon if an image is available
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
