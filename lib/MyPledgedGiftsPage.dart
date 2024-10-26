import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MyPledgedGiftsPage extends StatefulWidget {
  const MyPledgedGiftsPage({super.key});

  @override
  State<MyPledgedGiftsPage> createState() => _MyPledgedGiftsPageState();
}

class _MyPledgedGiftsPageState extends State<MyPledgedGiftsPage> {
  // Sample data for pledged gifts
  final List<Map<String, dynamic>> pledgedGifts = [
    {
      'friendName': 'Alice',
      'giftTitle': 'Birthday Surprise',
      'dueDate': '2024-11-10',
      'status': 'Pending',
      'image': 'asset/gift1.jpg',
    },
    {
      'friendName': 'Bob',
      'giftTitle': 'Anniversary Present',
      'dueDate': '2024-12-15',
      'status': 'Delivered',
      'image': 'asset/gift2.jpg',
    },
    {
      'friendName': 'Charlie',
      'giftTitle': 'Graduation Gift',
      'dueDate': '2024-11-20',
      'status': 'Pending',
      'image': 'asset/gift3.jpg',
    },
    {
      'friendName': 'Diana',
      'giftTitle': 'Promotion Celebration',
      'dueDate': '2024-11-30',
      'status': 'Pending',
      'image': 'asset/gift4.jpg',
    },
    // Duplicate entries for demonstration
    {
      'friendName': 'Alice',
      'giftTitle': 'Birthday Surprise',
      'dueDate': '2024-11-10',
      'status': 'Pending',
      'image': 'asset/gift1.jpg',
    },
    {
      'friendName': 'Bob',
      'giftTitle': 'Anniversary Present',
      'dueDate': '2024-12-15',
      'status': 'Delivered',
      'image': 'asset/gift2.jpg',
    },
    {
      'friendName': 'Charlie',
      'giftTitle': 'Graduation Gift',
      'dueDate': '2024-11-20',
      'status': 'Pending',
      'image': 'asset/gift3.jpg',
    },
    {
      'friendName': 'Diana',
      'giftTitle': 'Promotion Celebration',
      'dueDate': '2024-11-30',
      'status': 'Pending',
      'image': 'asset/gift4.jpg',
    },
  ];

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
              child: GridView.builder(
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
                                  child: Image.asset(
                                    gift['image'],
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      gift['giftTitle'],
                                      style: const TextStyle(
                                        fontSize: 25,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: "Lobster",
                                        color: Colors.indigo,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'For: ${gift['friendName']}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Due: ${gift['dueDate']}',
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
