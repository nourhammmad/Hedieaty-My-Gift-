import 'package:flutter/material.dart';

class GiftListPage extends StatefulWidget {
  const GiftListPage({super.key});

  @override
  State<GiftListPage> createState() => _GiftListPageState();
}

class _GiftListPageState extends State<GiftListPage> {
  List<Map<String, dynamic>> gifts = [
    {
      'name': 'Gift A',
      'category': 'Toys',
      'status': 'Available',
      'image': 'asset/teddy.jpg',
      'pledged': true,
    },
    {
      'name': 'Gift B',
      'category': 'Books',
      'status': 'Pledged',
      'image': 'asset/books.jpg',
      'pledged': false,
    },
    {
      'name': 'Gift C',
      'category': 'Clothing',
      'status': 'Available',
      'image': 'asset/dress.jpg',
      'pledged': true,
    },
    {
      'name': 'Gift D',
      'category': 'Electronics',
      'status': 'Available',
      'image': 'asset/elect.jpg',
      'pledged': false,
    },
  ];

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

  Color _getCardColor(bool isPledged, String status) {
    if (isPledged) {
      return Colors.green.shade100;
    } else if (status == 'Available') {
      return Colors.green.shade100;
    } else {
      return Colors.red.shade100;
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
                  final isPledged = gift['pledged'] ?? false;
                  final status = gift['status'] ?? 'Unknown';
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    elevation: 4.0,
                    margin: const EdgeInsets.symmetric(vertical: 10.0),
                    color: _getCardColor(isPledged, status),
                    child: Column(
                      children: [
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(15.0)),
                            image: DecorationImage(
                              image: AssetImage(gift['image'] ?? 'asset/placeholder.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                gift['name'] ?? 'Unnamed Gift',
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
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.indigo, size: 40),
                              onPressed: () => _navigateToGiftDetails(index), // Navigate to GiftDetailsPage
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 40),
                              onPressed: () => _deleteGift(index),
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
