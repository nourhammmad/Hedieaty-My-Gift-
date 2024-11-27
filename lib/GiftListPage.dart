import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GiftListPage extends StatefulWidget {
  const GiftListPage({super.key});

  @override
  State<GiftListPage> createState() => _GiftListPageState();
}

class _GiftListPageState extends State<GiftListPage> {
  List<Map<String, dynamic>> gifts = [];
  String sortCriteria = 'Name';

  @override
  void initState() {
    super.initState();
    _loadGifts();
  }

  // Function to load the gifts from Firestore
  Future<void> _loadGifts() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

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
          });
        }
      }
    } catch (e) {
      print('Error loading gifts: $e');
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


  // Function to navigate to the GiftDetailsPage
  void _navigateToGiftDetails(int index) {
    Navigator.pushNamed(context, '/GiftDetailsPage', arguments: gifts[index]);
  }

  // Function to delete a gift
  void _deleteGift(int index) {
    setState(() {
      gifts.removeAt(index);
    });
  }

  // Function to show a confirmation dialog before deleting a gift
  void _showDeleteDialog(int index) {
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
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("Cancel", style: TextStyle(fontSize: 25)),
            ),
            TextButton(
              onPressed: () {
                _deleteGift(index); // Delete the gift
                Navigator.of(context).pop(); // Close the dialog
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
            gifts.isEmpty
                ? const Center(child: Text('No gifts available.'))
                : Expanded(
              child: ListView.builder(
                itemCount: gifts.length,
                itemBuilder: (context, index) {
                  final gift = gifts[index];
                  final isPledged = gift['status'] == 'Pledged';
                  final status = gift['status'] ?? 'Unknown';
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    elevation: 4.0,
                    margin: const EdgeInsets.symmetric(vertical: 10.0),
                    color: _getCardColor(status), // Using the status to determine the color
                    child: Column(
                      children: [
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(15.0)),
                          ),
                          child: gift['image'] != null && gift['image'].isNotEmpty
                              ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(15.0)),
                            child: Image.network(
                              gift['image'], // Use the image URL if available
                              fit: BoxFit.cover,
                            ),
                          )
                              : Icon(
                            Icons.image_not_supported, // Show the default icon if no image is found
                            size: 100, // Adjust size as needed
                            color: Colors.red, // Set color of the icon
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
                        // Row for edit and delete buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Disable edit button if the gift is pledged
                            if (status != 'Pledged')
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.indigo, size: 40),
                                onPressed: () => _navigateToGiftDetails(index), // Navigate to GiftDetailsPage
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 40),
                              onPressed: () => _showDeleteDialog(index), // Show delete confirmation dialog
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
