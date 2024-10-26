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
  bool notificationsEnabled = false; // State variable for the toggle button

  // Sample values fetched from a database or user object
  String firstName = 'Nour';
  String lastName = 'Hammad';

  // Sample list of events with associated gifts (can be fetched from a database in real use case)
  final List<Map<String, String>> events = [
    {
      'imageLeft': 'asset/BD.jpg',
      'imageRight': 'asset/elect.jpg',
      'eventTitle': 'Birthday Party',
      'giftTitle': 'iPhone',
    },
    {
      'imageLeft': 'asset/WA.jpg',
      'imageRight': 'asset/teddy.jpg',
      'eventTitle': 'Anniversary Celebration',
      'giftTitle': 'Books',
    },
    {
      'imageLeft': 'asset/GA.jpg',
      'imageRight': 'asset/gift3.jpg',
      'eventTitle': 'Graduation Ceremony',
      'giftTitle': 'Teddy Bear',
    },
  ];

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
        actions: [
          IconButton(
            icon: const Icon(Icons.star, color: Colors.indigo),
            onPressed: () {
              Navigator.pushNamed(context, '/MyPledgedGiftsPage');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Stack for profile image and plus icon
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  ClipOval(
                    child: Image.asset(
                      'asset/pp1.jpg',
                      width: 220,
                      height: 220,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.indigo,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () {
                        print(events);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // First Name Field
            Row(
              children: [
                Expanded(
                  child: TextField(
                    style: const TextStyle(fontFamily: "Lobster", fontSize: 25),
                    enabled: isFirstNameEditable,
                    controller: TextEditingController(text: firstName),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
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
            const SizedBox(height: 20),

            // Last Name Field
            Row(
              children: [
                Expanded(
                  child: TextField(
                    style: const TextStyle(fontFamily: "Lobster", fontSize: 25),
                    enabled: isLastNameEditable,
                    controller: TextEditingController(text: lastName),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
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
            const SizedBox(height: 20),

            // Notification Toggle
            SwitchListTile(
              title: const Text(
                "Enable Notifications",
                style: TextStyle(
                  fontSize: 30,
                  fontFamily: "Lobster",
                ),
              ),
              value: notificationsEnabled,
              onChanged: (bool value) {
                setState(() {
                  notificationsEnabled = value;
                });
              },
              activeColor: Colors.indigo,
            ),
            const SizedBox(height: 20),

            // Event and Gift List
            Expanded(
              child: ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return Card(
                    elevation: 4.0,
                    margin: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ClipOval(
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: AssetImage(
                                    event['imageLeft'] ?? 'assets/default_image.png',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  event['eventTitle'] ?? 'Event Title',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontFamily: "Lobster",
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  event['giftTitle'] ?? 'Gift Title',
                                  style: const TextStyle(fontSize: 16),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          ClipOval(
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: AssetImage(
                                    event['imageRight'] ?? 'assets/default_image.png',
                                  ),
                                  fit: BoxFit.cover,
                                ),
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
