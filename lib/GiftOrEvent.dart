import 'package:flutter/material.dart';

class GiftOrEvent extends StatelessWidget {
  const GiftOrEvent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: Key('GiftOrEvent'),  // Assign a key here
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
      body: Column(
        children: [
          // Add Gift Option
          Expanded(
            key: Key('addGiftButton'), // Added key here

            child: _buildListItem(
              context: context,
              title: 'Add Gift',
              imageUrl: 'asset/giftc.jpg', // Ensure this path is correct
              onTap: () {
                // Navigate to Add Gift page
                Navigator.pushNamed(context, '/AddGift'); // Ensure route name is correct
              },
            ),
          ),
          // Add Event Option
          Expanded(
            key: Key('addEventButton'), // Added key here

            child: _buildListItem(
              context: context,
              title: 'Add Event',
              imageUrl: 'asset/eventc.jpg', // Ensure this path is correct
              onTap: () {
                // Navigate to Add Event page
                Navigator.pushNamed(context, '/AddEvent'); // Ensure route name is correct
              },

            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem({
    required BuildContext context,
    required String title,
    required String imageUrl,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0), // Margin between items
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30.0), // Curved corners
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3), // Position of the shadow
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30.0), // Curved corners
          child: Stack(
            children: [
              // Background Image
              Image.asset(
                imageUrl,
                fit: BoxFit.cover,
                width: double.infinity, // Extend to full width
                height: double.infinity, // Fill the available height
              ),
              // Centered Text
              Center(
                child: Text(
                  title,
                  style:  TextStyle(
                    color: Colors.indigo.shade200, // Change to white for better visibility
                    fontSize: 100, // Adjust font size for better visibility
                    fontWeight: FontWeight.bold,
                    fontFamily: "Lobster"
                  ),
                  textAlign: TextAlign.center, // Center text
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
