import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  @override
  void initState() {
    super.initState();
    _userId = _auth.currentUser!.uid; // Get logged-in user's ID
    _fetchPledgedGifts();
  }
  Future<String> _fetchGiftImage(String PledgerId,String eventId, String giftId) async {
    try {
      final FirebaseFirestore _firestore = FirebaseFirestore.instance;
      final FirebaseAuth _auth = FirebaseAuth.instance;

      User? user = _auth.currentUser;
      if (user != null) {
        String userId = user.uid;

        // Fetch the user's document
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(PledgerId).get();

        if (userDoc.exists) {
          // Access the events array from the user's document
          List<dynamic> eventsList = userDoc['events_list'] ?? [];

          // Find the event by its eventId
          var event = eventsList.firstWhere((event) => event['eventId'] == eventId, orElse: () => null);

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

    return '';  // Return an empty string if image fetching fails
  }

  Future<void> _fetchPledgedGifts() async {
    try {
      // Fetch the logged-in user's document from Firestore
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(_userId).get();

      if (userDoc.exists) {
        List pledgedGiftIds = userDoc['pledged_gifts'] ?? []; // List of pledged gifts data

        // Initialize a list to store detailed pledged gifts data
        List<Map<String, dynamic>> pledgedGiftsList = [];

        for (var pledgedGift in pledgedGiftIds) {
          // Extract the pledgerId, giftId, eventId, and status from the pledged gift
          String pledgerId = pledgedGift['pledgerId'];
          String giftId = pledgedGift['giftId'];
          String eventId = pledgedGift['eventId'];
          String status = pledgedGift['status'];

          // Fetch the pledger's user document
          DocumentSnapshot pledgerDoc = await _firestore.collection('users').doc(pledgerId).get();

          if (pledgerDoc.exists) {
            // Extract the pledger's name
            String pledgerName = pledgerDoc['displayName'] ?? 'Unknown';

            // Fetch the event details using the eventId from the pledger's events_list
            List eventsList = pledgerDoc['events_list'] ?? [];
            String eventTitle = 'Unknown Event';
            String giftTitle = 'Unknown Gift';
            String dueTo = 'No due date';
            String giftImage = '';  // To store the gift image URL

            for (var event in eventsList) {
              if (event['eventId'] == eventId) {
                eventTitle = event['title'] ?? 'Unknown Event';

                // Find the gift in the event's gifts array
                for (var gift in event['gifts']) {
                  if (gift['giftId'] == giftId) {
                    giftTitle = gift['title'] ?? 'Unknown Gift';
                    dueTo = gift['dueTo'] ?? 'No due date';

                    // Fetch the gift image using the _fetchGiftImage method
                    giftImage = await _fetchGiftImage(pledgedGift['pledgerId'],eventId, giftId);
                    break;
                  }
                }
                break; // Stop once we find the matching event
              }
            }

            // Create the detailed pledged gift entry
            pledgedGiftsList.add({
              'pledgerName': pledgerName,
              'title': giftTitle,
              'eventTitle': eventTitle,
              'dueTo': dueTo,
              'status': status,
              'photoURL': giftImage,  // Add the gift image URL
            });
          }
        }

        // Update the UI with the fetched pledged gifts
        setState(() {
          print("===================$pledgedGiftsList");
          pledgedGifts = pledgedGiftsList;
        });
      }
    } catch (e) {
      print("Error fetching pledged gifts: $e");
    }
  }



  void _unpledgeGift(int index) {
    setState(() {
      pledgedGifts.removeAt(index);
    });
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
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Cancel', style: TextStyle(fontSize: 25)),
            ),
            TextButton(
              onPressed: () {
                _unpledgeGift(index);
                Navigator.of(context).pop(); // Close dialog after unpledging
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
            const SizedBox(height: 16), // Space between heading and list
            Expanded(
              child: pledgedGifts.isEmpty
                  ? const Center(child: Text('No pledged gifts yet!', style: TextStyle(fontSize: 20)))
                  : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // Two gifts per row
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 3 / 4, // Adjust to your desired size
                ),
                itemCount: pledgedGifts.length,
                itemBuilder: (context, index) {
                  final gift = pledgedGifts[index];
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(30), bottom: Radius.circular(20)), // Curved top and bottom
                      color: Colors.white, // Card background color
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3), // Position of the shadow
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        InkWell(
                          onTap: () {
                            // Tap gesture is optional; you can keep it if you want
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)), // Round the top corners
                                  child: (gift['photoURL'] != null && gift['photoURL'].isNotEmpty)
                                      ? Image.network(
                                    gift['photoURL'], // Assuming gift image URL
                                    fit: BoxFit.cover,
                                  )
                                      : Container(
                                    color: Colors.grey[200], // Optional: background color for fallback
                                    child: Center(
                                      child: Icon(
                                        Icons.image_not_supported, // Default icon when no image available
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
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Due: ${gift['dueTo']}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Status: ${gift['status']}',
                                      style: TextStyle(
                                        fontSize: 16,
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
                        // Conditionally render the delete button for pending gifts only
                        if (gift['status'] == 'Pending')
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8), // Opaque white background
                                borderRadius: BorderRadius.circular(20), // Rounded corners
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  _showUnpledgeDialog(index);
                                },
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
