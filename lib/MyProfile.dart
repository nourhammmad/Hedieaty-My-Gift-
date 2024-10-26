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

  // Sample list of gifts (can be fetched from a database in real use case)
  final List<Map<String, String>> gifts = [
    {'image': 'asset/pp1.jpg', 'title': 'Gift 1', 'event': 'A beautiful gift for special occasions'},
    {'image': 'asset/pp2.jpg', 'title': 'Gift 2', 'event': 'A wonderful surprise for loved ones'},
    {'image': 'asset/pp3.jpg', 'title': 'Gift 3', 'event': 'An unforgettable present for birthdays'},
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
                        print(gifts);
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

            // Gift List
            Expanded(
              child: ListView.builder(
                itemCount: gifts.length,
                itemBuilder: (context, index) {
                  final gift = gifts[index];
                  return Card(
                    elevation: 4.0,
                    margin: const EdgeInsets.symmetric(vertical: 10.0),
                    child: ListTile(
                      leading: ClipOval(
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: AssetImage(
                                gift['image'] ?? 'assets/default_image.png',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        gift['title'] ?? 'Gift Name',
                        style: const TextStyle(
                          fontSize: 30,
                          fontFamily: "Lobster",
                        ),
                      ),
                      subtitle: Text(
                        gift['event'] ?? 'Gift Description',
                        style: const TextStyle(fontSize: 20),
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
