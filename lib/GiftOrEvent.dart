import 'package:flutter/material.dart';

class GiftOrEvent extends StatelessWidget {
  const GiftOrEvent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: Key('GiftOrEvent'),
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
          Expanded(
            key: Key('addGiftButton'),
            child: _buildListItem(
              context: context,
              title: 'Add Gift',
              imageUrl: 'asset/giftc.jpg',
              onTap: () {
                 Navigator.pushNamed(context, '/AddGift');
              },
            ),
          ),
           Expanded(
            key: Key('addEventButton'),

            child: _buildListItem(
              context: context,
              title: 'Add Event',
              imageUrl: 'asset/eventc.jpg',
              onTap: () {
                 Navigator.pushNamed(context, '/AddEvent');
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
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30.0),
          child: Stack(
            children: [
               Image.asset(
                imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
              // Centered Text
              Center(
                child: Text(
                  title,
                  style:  TextStyle(
                    color: Colors.indigo.shade200,
                    fontSize: 100,
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
