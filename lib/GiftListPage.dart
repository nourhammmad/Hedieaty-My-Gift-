import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:projecttrial/GiftDetailsPage.dart';

import 'Database.dart';
import 'UserSession.dart';

class GiftListPage extends StatefulWidget {
  final String eventId;

  const GiftListPage({Key? key, required this.eventId}) : super(key: key);

  @override
  State<GiftListPage> createState() => _GiftListPageState();
}


class _GiftListPageState extends State<GiftListPage> {
  List<Map<String, dynamic>> gifts = [];
  String sortCriteria = 'Name';
  late bool online;
  late String currentUserId;
  late Databaseclass _dbHelper;

  @override
  void initState() {
    super.initState();
    _dbHelper = Databaseclass();
    _loadGifts();
  }

   Future<String> _fetchGiftImage(String eventId, String giftId) async {
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
        final FirebaseAuth _auth = FirebaseAuth.instance;
        final FirebaseFirestore _firestore = FirebaseFirestore.instance;

        User? user = _auth.currentUser;
        if (user != null) {
          String userId = user.uid;
          DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();

          if (userDoc.exists) {
            List<dynamic> eventsList = userDoc['events_list'] ?? [];
             var event = eventsList.firstWhere(
                  (e) => e['eventId'] == widget.eventId,
              orElse: () => null,
            );

            if (event != null && event['gifts'] != null) {
              List<Map<String, dynamic>> updatedGifts = [];
              List<String> firestoreGiftIds = [];

              for (var gift in event['gifts']) {
                String photoURL = await _fetchGiftImage(
                    widget.eventId, gift['giftId']);
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
                firestoreGiftIds.add(gift['giftId']);

                Map<String, String> giftData = {
                  'FIRESTORE_GIFT_ID': gift['giftId'] ?? '',
                  'giftName': gift['title'] ?? '',
                  'status': gift['status'] ?? '',
                  'dueTo': gift['dueTo'] ?? '',
                  'category': gift['category'].toString() ?? '',
                  'giftValue': gift['price']?.toString() ?? '',
                  'FIRESTORE_EVENT_ID': widget.eventId ?? '',
                };

                _dbHelper.insertGift(widget.eventId, giftData);
              }
              await _dbHelper.deleteRemovedGifts(widget.eventId, firestoreGiftIds);
              List<Map<String, Object?>> localGifts = await _dbHelper.getGiftsByEventId(widget.eventId!);
              print(localGifts);
              setState(() {
                gifts = updatedGifts;
              });
            }
          }
        }
      } else {
        _loadGiftsFromLocalDatabase();
        print("YOU ARE OFFLINE");
      }
    } catch (e) {
      print('Error loading gifts: $e');
    }
  }

  Future<void> _loadGiftsFromLocalDatabase() async {
     try {
      print("Offline, fetching friends from local database");
      currentUserId = (await UserSession.getUserId())!;
      List<Map<String, Object?>> localGifts = await _dbHelper.getGiftsByEventId(widget.eventId!);
      gifts.clear();

      for (var giftData in localGifts) {

        gifts.add({
        'title': giftData['giftName'] ?? '',
        'status': giftData['status'] ?? '',
        'category':giftData['category'] ?? '',
        'dueTo': giftData['dueTo'] ?? '',
        'giftValue': giftData['giftValue']?.toString() ?? '',
        });
      }

       setState(() {});
    } catch (e) {
      print("Error loading gifts from local database: $e");
    }
  }

  void _sortGifts() {
    switch (sortCriteria) {
      case 'Name':
        gifts.sort((a, b) => (a['title'] ?? '').compareTo(b['title'] ?? ''));
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

  Future<void> _deleteGift(String giftId, String eventId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(userId);
      final userDoc = await userDocRef.get();
      if (userDoc.exists) {
        final eventsList = userDoc.data()?['events_list'] as List<dynamic>?;
        if (eventsList != null) {
           final event = eventsList.firstWhere(
                (event) => event['eventId'] == eventId,
            orElse: () => null,
          );
          if (event != null) {
            final giftsList = event['gifts'] as List<dynamic>?;
            if (giftsList != null) {
               final giftToDelete = giftsList.firstWhere(
                    (gift) => gift['giftId'] == giftId,
                orElse: () => null,
              );
              if (giftToDelete != null) {
                final pledgedBy = giftToDelete['PledgedBy'];
                if (pledgedBy != null) {
                  final pledgedUserDocRef = FirebaseFirestore.instance.collection('users').doc(pledgedBy);
                  final pledgedUserDoc = await pledgedUserDocRef.get();
                  if (pledgedUserDoc.exists) {
                    final pledgedGiftsList = pledgedUserDoc.data()?['pledged_gifts'] as List<dynamic>?;
                    if (pledgedGiftsList != null) {
                       final pledgedGiftToDelete = pledgedGiftsList.firstWhere(
                            (gift) => gift['giftId'] == giftId,
                        orElse: () => null,
                      );

                      if (pledgedGiftToDelete != null) {
                        pledgedGiftsList.remove(pledgedGiftToDelete);
                        await pledgedUserDocRef.update({'pledged_gifts': pledgedGiftsList});
                      }
                    }
                  }
                }
                giftsList.remove(giftToDelete);
                if (giftsList.isEmpty) {
                  event['gifts'] = null;
                }
                await userDocRef.update({'events_list': eventsList});
                setState(() {
                  gifts.removeWhere((gift) => gift['giftId'] == giftId);
                });
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error deleting gift: $e');
    }
  }

  void _showDeleteDialog(String giftId,String eventId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "Confirm Deletion",
            style: TextStyle(fontSize: 28, color: Colors.red),
          ),
          content: const Text("Are you sure you want to delete this gift?", style: TextStyle(fontSize: 25)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel", style: TextStyle(fontSize: 25)),
            ),
            TextButton(
              onPressed: () {
                _deleteGift(giftId,eventId);
                Navigator.of(context).pop();
              },
              child: const Text("Delete", style: TextStyle(fontSize: 25, color: Colors.red)),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    _sortGifts();

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
            gifts.isEmpty?Expanded(
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
                  final isPledged = gift['status'] == 'Pledged';
                  final status = gift['status'] ?? 'Unknown';
                  final duedate=gift['dueTo']??'Not Decided';
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    elevation: 4.0,
                    margin: const EdgeInsets.symmetric(vertical: 10.0),
                    color: _getCardColor(status),
                    child: Column(
                      children: [
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(15.0)),
                          ),
                          child: gift['photoURL'] != null && gift['photoURL'].isNotEmpty
                              ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(15.0)),
                            child: Image.network(
                              gift['photoURL'],
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          )
                              : Icon(
                            Icons.image_not_supported,
                            size: 100,
                            color: Colors.red,
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
                                  fontSize: 40,
                                  fontFamily: "Lobster",
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              Text(
                                "Category: ${gift['category'] ?? 'Uncategorized'}",
                                style: const TextStyle(fontSize: 30,fontFamily: "Lobster",
                                ),
                              ),
                              Text(
                                "Status: ${gift['status'] ?? 'Unknown'}",
                                style: const TextStyle(fontSize: 30,fontFamily: "Lobster",
                                ),
                              ),
                              Text(
                                "Due Date: ${duedate??'Unknown'}",
                                style: const TextStyle(fontSize: 30,          fontFamily: "Lobster",
                                ),
                              ),
                            ],
                          ),
                        ),
                         Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                             if (!isPledged)
                              IconButton(
                              icon: const Icon(Icons.edit, color: Colors.indigo, size: 40),
                              onPressed: () async {
                                 final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => GiftDetailsPage(
                                      id: gift['giftId'],
                                      eventId: gift['eventId'],
                                      status: gift['status'],
                                      giftName: gift['title'],
                                      description: gift['description'],
                                      image: gift['photoURL'],
                                      category: gift['category'],
                                      price: gift['price'],
                                    ),
                                  ),
                                );

                                if (result != null && result == 'reload') {
                                  setState(() {
                                     _loadGifts();
                                  });
                                }
                              },
                            ),

                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 40),
                              onPressed: () => _showDeleteDialog(gift['giftId'],gift['eventId']),
                            ),
                          ],
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
