import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isPressed = false; // Track the button state
  bool _isSearching = false; // Track the state of the search bar

  final List<Map<String, String>> friends = [
    {"name": "Nour", "image": "asset/pp1.jpg"},
    {"name": "Liam", "image": "asset/pp2.jpg"},
    {"name": "Emma", "image": "asset/pp3.jpg"},
    {"name": "Oliver", "image": "asset/pp4.jpg"},
    {"name": "Nina", "image": "asset/pp1.jpg"},
    {"name": "Harry", "image": "asset/pp2.jpg"},
    {"name": "Taylor", "image": "asset/pp3.jpg"},
    {"name": "Oliver", "image": "asset/pp4.jpg"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo.shade50,
        title: _isSearching
            ? AnimatedContainer(
          key: ValueKey('searchBar'),
          duration: const Duration(milliseconds: 600),
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: Colors.indigo.shade300),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search Friends...',
                    border: InputBorder.none,
                  ),
                  style: TextStyle(
                    fontFamily: 'Lobster',
                    fontSize: 18,
                    color: Colors.indigo,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.indigo),
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                  });
                },
              ),
            ],
          ),
        )
            : const Row(
          key: ValueKey('appName'),
          children: [
            Text(
              "Hedieaty",
              style: TextStyle(
                fontSize: 45,
                fontFamily: "Lobster",
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            SizedBox(width: 8),
            Icon(
              Icons.card_giftcard,
              color: Colors.indigo,
              size: 25,
            ),
          ],
        ),
        titleSpacing: 25.0,
        toolbarHeight: 70,
        leading: IconButton(
          onPressed: () {},
          alignment: Alignment.topLeft,
          icon: const Icon(Icons.menu, size: 35, color: Colors.indigo),
        ),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search, size: 30, color: Colors.indigo),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/MyProfile');
            },
            alignment: Alignment.topRight,
            icon: const Icon(
              Icons.account_circle_outlined,
              size: 35,
              color: Colors.indigo,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              GestureDetector(
                onTapDown: (_) {
                  setState(() {
                    _isPressed = true;
                  });
                },
                onTapUp: (_) {
                  setState(() {
                    _isPressed = false;
                  });
                },
                onTapCancel: () {
                  setState(() {
                    _isPressed = false;
                  });
                },
                child: Container(
                  height: 60,
                  width: double.infinity,
                  margin: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade100,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Center(
                    child: Text(
                      'Create Your Own Event/List',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: "Lobster",
                        color: _isPressed
                            ? Colors.blueGrey.shade800
                            : Colors.indigo.shade400,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    return FriendListItem(
                      name: friends[index]['name']!,
                      image: friends[index]['image']!,
                    );
                  },
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddFriendPage()),
                );
              },
              backgroundColor: Colors.indigo.shade100,
              child: Icon(
                Icons.person_add,
                color: Colors.indigo.shade400,
                size: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget for the Add Friend Page
class AddFriendPage extends StatelessWidget {
  const AddFriendPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Friend"),
        backgroundColor: Colors.indigo.shade50,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const TextField(
              decoration:  InputDecoration(
                hintText: 'Friend Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                hintText: 'Friend Phone Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Add logic to save the friend information
                Navigator.pop(context); // Close the page after adding
              },
              child: const Text("Add Friend"),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget to display each friend with a fading image and info
class FriendListItem extends StatelessWidget {
  final String name;
  final String image;

  const FriendListItem({required this.name, required this.image});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0, horizontal: 10.0),
      child: Row(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(
                image: AssetImage(image),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.4),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/FriendsPage');
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      fontFamily: "Lobster",
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "No Upcoming Events", // Example status
                    style: TextStyle(
                      fontSize: 19,
                      color: Colors.grey,
                      fontFamily: "Lobster",
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
