import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isPressed = false; // Track the button state

  // List of friends (will be replaced by db)
  //Use final if the list itself should not be replaced,
  // but you still need to modify its contents
  // (add, remove, or update elements).
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
        title: Row(
          children: [
            const Text(
              "Hedieaty",
              style: TextStyle(
                fontSize: 45,
                fontFamily: "Lobster",
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const Icon(Icons.card_giftcard,color: Colors.indigo,size: 25,),
          ],
        ),

        titleSpacing: 69.0,
        toolbarHeight: 70,
        //AppBar menu icon
        //i used leading here top get the menu icon
        //to the left if i put it inside actions it'd have been to the
        //right next to account icon
        //The actions property aligns its children to the right of the AppBar.
        leading: IconButton(
          onPressed: () {},
          alignment: Alignment.topLeft,
          icon: const Icon(Icons.menu, size: 35,color: Colors.indigo,),
        ),
        actions: [
          IconButton(
            onPressed: () {Navigator.pushNamed(context, '/MyProfile');},
            alignment: Alignment.topRight,
            icon: const Icon(
              Icons.account_circle_outlined,
              size: 35,
              color: Colors.indigo,
            ),
          ),
        ],
      ),
      ///////////////////END OF APPBAR///////////////////
      // If you used only a Column, the button would be pushed to the bottom
      // of the layout and would scroll with the content. But using a Stack
      // ensures the button stays in place while the list can scroll
      // independently.
      body: Stack(
        children: [
          Column(
            children: [
              // Button at the top
              //A GestureDetector in Flutter is used to detect and respond to different
              // types of user interactions or gestures, such as taps, swipes, long presses
              // , and drags. It acts as an invisible layer that wraps around
              // widgets and enables them to handle touch events.
              //like onTapDown w kda
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
                  //wrapped with center
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
              // Friend list embedded below the button
              //Column aligns its children vertically, and the friend list
              // (ListView.builder) should take up the remaining space.
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
          // Floating circular button at the bottom right
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () {},
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
          // Fading image on the left
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
          // Name and additional info
          Expanded(
            child: GestureDetector(
              onTap:(){
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