import 'dart:convert';
import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'PushNotifications.dart';

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
  bool isLoading = true;
  String sortCriteria = 'Name';


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (widget.userId.isNotEmpty && widget.eventId.isNotEmpty) {
        _loadGifts();
      } else {
        setState(() {
          isLoading = false;
        });
        print('Error: Missing or invalid arguments.');
      }
    });
  }

  Future<String> _fetchGiftImage(String eventId, String giftId) async {
    try {
      final FirebaseFirestore _firestore = FirebaseFirestore.instance;

      if (widget.userId != null) {
         DocumentSnapshot userDoc = await _firestore.collection('users').doc(widget.userId).get();

        if (userDoc.exists) {
           List<dynamic> eventsList = userDoc['events_list'] ?? [];
           var event = eventsList.firstWhere((event) => event['eventId'] == widget.eventId, orElse: () => null);

          if (event != null) {
             var gift = event['gifts']?.firstWhere((gift) => gift['giftId'] == giftId, orElse: () => null);

            if (gift != null) {
               return gift['photoURL'] ?? '';
            }
          }
        }
      }
    } catch (e) {
      print("Error fetching gift image: $e");
    }

    return '';
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
        isLoading = false;
      });
    }
  }

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
      return true;
    } else {
      return false;
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
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(pledgerId).get();
      final displayName = userDoc.data()?['displayName'];
      final gift = gifts.firstWhere(
            (gift) => gift['giftId'] == giftId,
        orElse: () => {},
      );

      if (gift == null) {
        print("Error: Gift not found.");
        return;
      }

      final giftTitle = gift['title']; // Get the gift title
      final eventId = gift['eventId'];

      if (eventId == null) {
        print("Error: Missing eventId.");
        return;
      }

      final friendUserId = gift['createdBy'];
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(friendUserId);

      final userDocSnapshot = await userDocRef.get();
      if (!userDocSnapshot.exists) {
        throw Exception("User document not found.");
      }

      final eventsList = List<Map<String, dynamic>>.from(userDocSnapshot.data()?['events_list'] ?? []);
      print("events_list: $eventsList");

       final eventIndex = eventsList.indexWhere((event) => event['eventId'] == eventId);
      if (eventIndex == -1) {
        throw Exception("Event not found.");
      }

      final event = eventsList[eventIndex];
      final eventTitle = event['title'];
      print("Event Title: $eventTitle");

      final giftsList = List<Map<String, dynamic>>.from(event['gifts'] ?? []);
      final giftIndex = giftsList.indexWhere((g) => g['giftId'] == giftId);

      if (giftIndex == -1) {
        throw Exception("Gift not found.");
      }

       giftsList[giftIndex]['PledgedBy'] = pledgerId;
      giftsList[giftIndex]['status'] = 'Pledged';
      eventsList[eventIndex]['gifts'] = giftsList;

       final currentUserDocRef = FirebaseFirestore.instance.collection('users').doc(pledgerId);
      final currentUserDocSnapshot = await currentUserDocRef.get();

      if (!currentUserDocSnapshot.exists) {
        throw Exception("Current user document not found.");
      }

      final currentUserPledgedGiftsList = List<Map<String, dynamic>>.from(currentUserDocSnapshot.data()?['pledged_gifts'] ?? []);
      currentUserPledgedGiftsList.add({
        'pledgerId': friendUserId,
        'eventId': eventId,
        'giftId': giftId,
        'status': "Pending",
      });

       await FirebaseFirestore.instance.runTransaction((transaction) async {
         transaction.update(userDocRef, {
          'events_list': eventsList,
        });

         transaction.update(currentUserDocRef, {
          'pledged_gifts': currentUserPledgedGiftsList,
        });
      });

       final deviceToken = userDocSnapshot.data()?['fcmToken'];

      if (deviceToken != null && deviceToken.isNotEmpty) {
         await PushNotifications.SendNotificationToPledgedFriend(deviceToken, context, giftId,giftTitle,eventTitle,displayName);
      }

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
    _sortGifts();

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.indigo),
        backgroundColor: Colors.indigo.shade50,
        title: SingleChildScrollView(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
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
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SingleChildScrollView(
              child: const Row(
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
            ),
            const SizedBox(height: 10),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : gifts.isEmpty?
                    Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.card_giftcard,
                      size: 200,
                      color: Colors.indigo.shade100,
                    ),
                  ],
                ),
              ),
            )
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
                    color: _getCardColor(status),
                    child: SingleChildScrollView(
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
                                color: Colors.red,
                                size: 100,
                              ),
                            )
                                : Image.network(
                              width: double.infinity,
                              height: double.infinity,
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
                           ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  gift['title'] ?? 'Unnamed Gift',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo,
                                    fontSize: 35,
                                    fontFamily: "Lobster",

                                  ),
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  "Category: ${gift['category'] ?? 'Uncategorized'}",
                                    style: const TextStyle(fontSize: 30,          fontFamily: "Lobster",),
                                ),
                                Text(
                                  "Status: ${status}",
                                    style: const TextStyle(fontSize: 30,          fontFamily: "Lobster",),
                                ),
                                Text(
                                  "Due Data: ${dueTo}",
                  style: const TextStyle(fontSize: 30,          fontFamily: "Lobster",)),

                  ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: ElevatedButton(
                              key:Key(gift['title']),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _getButtonColor(status),
                              ),
                              onPressed: isPledged ? null : () => _pledgeGift(gift['giftId']),
                              child: Text(
                                WhichText(status) ? 'Already Pledged' : 'Pledge Gift',
                                style: TextStyle(color: Colors.indigo.shade50, fontFamily: "Lobster", fontSize: 30),
                              ),
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