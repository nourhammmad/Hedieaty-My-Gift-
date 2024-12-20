import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import 'Database.dart';

class MyPledgedGiftsPage extends StatefulWidget {
  const MyPledgedGiftsPage({super.key});

  @override
  State<MyPledgedGiftsPage> createState() => _MyPledgedGiftsPageState();
}

class _MyPledgedGiftsPageState extends State<MyPledgedGiftsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String _userId;
  List<Map<String, dynamic>> pledgedGifts = [];
   late bool online;

  @override
  void initState() {
    super.initState();
    _userId = _auth.currentUser!.uid; // Get logged-in user's ID
     _fetchPledgedGifts();
  }

  Future<String> _fetchGiftImage(String PledgerId,String eventId, String giftId) async {
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

         DocumentSnapshot userDoc = await _firestore.collection('users').doc(PledgerId).get();
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

  Future<void> _fetchPledgedGifts() async {
    try {
      var internetConnection = InternetConnection(); // Initialize safely
      if (internetConnection != null) {
        online = await internetConnection.hasInternetAccess;
      }
    } catch (e) {
      print("Error checking internet connection: $e");
    }

    try {
      if (online) {
         DocumentSnapshot userDoc = await _firestore.collection('users').doc(
            _userId).get();

        if (userDoc.exists) {
          List pledgedGiftIds = userDoc['pledged_gifts'] ??
              [];

           List<Map<String, dynamic>> pledgedGiftsList = [];

          for (var pledgedGift in pledgedGiftIds) {
             String pledgerId = pledgedGift['pledgerId'];
            String giftId = pledgedGift['giftId'];
            String eventId = pledgedGift['eventId'];
            String status = pledgedGift['status'];

             DocumentSnapshot pledgerDoc = await _firestore.collection('users')
                .doc(pledgerId)
                .get();

            if (pledgerDoc.exists) {
               String pledgerName = pledgerDoc['displayName'] ?? 'Unknown';
               List eventsList = pledgerDoc['events_list'] ?? [];
              String eventTitle = 'Unknown Event';
              String giftTitle = 'Unknown Gift';
              String dueTo = 'No due date';
              String giftImage = '';

              for (var event in eventsList) {
                if (event['eventId'] == eventId) {
                  eventTitle = event['title'] ?? 'Unknown Event';

                   for (var gift in event['gifts']) {
                    if (gift['giftId'] == giftId) {
                      giftTitle = gift['title'] ?? 'Unknown Gift';
                      dueTo = gift['dueTo'] ?? 'No due date';

                       giftImage = await _fetchGiftImage(
                          pledgedGift['pledgerId'], eventId, giftId);
                      break;
                    }
                  }
                  break;
                }
              }

               pledgedGiftsList.add({
                'pledgerName': pledgerName,
                'pledgerId': pledgerId,
                'eventId': eventId,
                'title': giftTitle,
                'giftId': giftId,
                'eventTitle': eventTitle,
                'dueTo': dueTo,
                'status': status,
                'photoURL': giftImage,
              });
            }
          }

           setState(() {
             pledgedGifts = pledgedGiftsList;
          });
        }
      }else{
        print("YOU ARE OFFLINE");
      }
    } catch (e) {
      print("Error fetching pledged gifts: $e");
    }
  }

  Future<void> _unpledgeGift(int index) async {
    try {
       var giftToUnpledge = pledgedGifts[index];
      print(giftToUnpledge);
       if (giftToUnpledge['status'] == 'Pending') {
         DocumentSnapshot userDoc = await _firestore.collection('users').doc(_userId).get();
        if (userDoc.exists) {
           List pledgedGiftIds = List.from(userDoc['pledged_gifts'] ?? []);
           pledgedGiftIds.removeWhere((pledgedGift) =>
           pledgedGift['giftId'] == giftToUnpledge['giftId']);

           await _firestore.collection('users').doc(_userId).update({
            'pledged_gifts': pledgedGiftIds,
          });

           String pledgerId = giftToUnpledge['pledgerId'];
          DocumentSnapshot pledgerDoc = await _firestore.collection('users').doc(pledgerId).get();

          if (pledgerDoc.exists) {
             List eventsList = List.from(pledgerDoc['events_list'] ?? []);
            String eventId = giftToUnpledge['eventId'];
            String giftId = giftToUnpledge['giftId'];

            for (var event in eventsList) {
              if (event['eventId'] == eventId) {
                 List giftsList = List.from(event['gifts'] ?? []);
                for (var gift in giftsList) {
                  if (gift['giftId'] == giftId) {
                     gift['PledgedBy'] = null;
                    gift['status'] = "A"
                        ""
                        "vailable";
                    break;
                  }
                }

                 await _firestore.collection('users').doc(pledgerId).update({
                  'events_list': eventsList,
                });
                print("Gift unpledged and pledgerId set to null.");
                break;
              }
            }
          }

           setState(() {
            pledgedGifts.removeAt(index);
          });
        }
      } else {
        print("Gift is not in pending status.");
      }
    } catch (e) {
      print("Error unpledging gift: $e");
    }
  }

  void _showUnpledgeDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Unpledge Gift', style: TextStyle(color: Colors.red, fontSize: 28)),
          content: const Text('Are you sure you want to unpledge this gift?', style: TextStyle(fontSize: 25)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel', style: TextStyle(fontSize: 25)),
            ),
            TextButton(
              onPressed: () {
                _unpledgeGift(index);
                Navigator.of(context).pop();
              },
              child: const Text(
                'Unpledge',
                style: TextStyle(color: Colors.red, fontSize: 25),
              ),
            ),
          ],
        );
      },
    );
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                "My Pledged Gifts",
                style: TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Lobster",
                  color: Colors.indigo,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: pledgedGifts.isEmpty
                  ? Expanded(
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
                  : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 3 / 4,
                ),
                itemCount: pledgedGifts.length,
                itemBuilder: (context, index) {
                  final gift = pledgedGifts[index];
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(30), bottom: Radius.circular(20)), // Curved top and bottom
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        InkWell(
                          onTap: () {
                           },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                                  child: (gift['photoURL'] != null && gift['photoURL'].isNotEmpty)
                                      ? Image.network(
                                    gift['photoURL'],
                                    fit: BoxFit.cover,
                                  )
                                      : Container(
                                    color: Colors.grey[200],
                                    child: Center(
                                      child: Icon(
                                        Icons.image_not_supported,
                                        size: 100,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      gift['title'] ?? 'No Title',
                                      style: const TextStyle(
                                        fontSize: 25,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: "Lobster",
                                        color: Colors.indigo,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'For: ${gift['pledgerName']}',
                                      style: const TextStyle(fontSize: 17),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Due: ${gift['dueTo']}',
                                      style: const TextStyle(fontSize: 17),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Status: ${gift['status']}',
                                      style: TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold,
                                        color: gift['status'] == 'Pending'
                                            ? Colors.red
                                            : Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                         if (gift['status'] == 'Pending')
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                 Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.check_circle, color: Colors.green),
                                    onPressed: () async {
                                      try {
                                         final userId = FirebaseAuth.instance.currentUser?.uid;
                                        if (userId == null) return;

                                         final userDocRef = FirebaseFirestore.instance.collection('users').doc(userId);

                                         final userDoc = await userDocRef.get();
                                        if (userDoc.exists) {
                                          final pledgedGifts = List<Map<String, dynamic>>.from(userDoc.data()?['pledged_gifts'] ?? []);

                                           final giftToUpdate = pledgedGifts.firstWhere(
                                                (g) => g['giftId'] == gift['giftId'],
                                            orElse: () => {},
                                          );

                                          if (giftToUpdate != null) {
                                             giftToUpdate['status'] = 'Purchased';

                                             await userDocRef.update({
                                              'pledged_gifts': pledgedGifts,
                                            });

                                             setState(() {
                                              gift['status'] = 'Purchased';
                                            });
                                          }
                                        }
                                      } catch (e) {
                                        print('Error updating gift status: $e');
                                      }
                                    },
                                  ),
                                ),

                                 Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      _showUnpledgeDialog(index);
                                    },
                                  ),
                                ),
                              ],
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
