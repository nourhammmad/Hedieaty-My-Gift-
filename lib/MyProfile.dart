import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MyProfile extends StatefulWidget {
  const MyProfile({super.key});

  @override
  State<MyProfile> createState() => _MyProfileState();
}

class _MyProfileState extends State<MyProfile> {
  bool isFirstNameEditable = false;
  bool isLastNameEditable = false;

  // Sample values fetched from a database or user object
  String firstName = 'Nour';
  String lastName = 'Hammad';

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
          children: [
            // Stack for profile image and plus icon
            Center(
              child: Stack(
                alignment: Alignment.bottomRight, // Align the icon to the bottom right
                children: [
                  // Circular image
                  ClipOval(
                    child: Image.asset(
                      'asset/pp1.jpg',
                      width: 220, // Set the desired width
                      height: 220, // Set the desired height
                      fit: BoxFit.cover, // Ensure the image covers the area
                    ),
                  ),
                  // Plus icon at the bottom right of the image
                  Container(
                    margin: const EdgeInsets.all(8), // Add margin around the icon
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.indigo, // Background color for the icon
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.add, // Plus icon
                        color: Colors.white, // Icon color
                        size: 28, // Size of the icon
                      ),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20), // Space between image and other content

            // First Name Field
            Row(
              children: [
                Expanded(
                  child: TextField(
                    enabled: isFirstNameEditable,
                    controller: TextEditingController(text: firstName),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'First Name',
                    ),
                    onChanged: (value) {
                      firstName = value;
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(isFirstNameEditable ? Icons.check : Icons.edit),
                  onPressed: () {
                    setState(() {
                      isFirstNameEditable = !isFirstNameEditable;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20), // Space between fields

            // Last Name Field
            Row(
              children: [
                Expanded(
                  child: TextField(
                    enabled: isLastNameEditable,
                    controller: TextEditingController(text: lastName),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Last Name',
                    ),
                    onChanged: (value) {
                      lastName = value;
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(isLastNameEditable ? Icons.check : Icons.edit),
                  onPressed: () {
                    setState(() {
                      isLastNameEditable = !isLastNameEditable;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
