import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isPressed = false; // Track the button state

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Hedieaty",
          style: TextStyle(
            fontSize: 45,
            fontFamily: "Lobster",
            fontWeight: FontWeight.bold,
          ),
        ),
        titleSpacing: 73.0,
        toolbarHeight: 70,
        leading: IconButton(
          onPressed: () {},
          alignment: Alignment.topLeft,
          icon: const Icon(Icons.menu, size: 35),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            alignment: Alignment.topRight,
            icon: const Icon(
              Icons.account_circle_outlined,
              size: 35,
              color: Colors.black,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          GestureDetector(
            onTapDown: (_) {
              // When the button is pressed down
              setState(() {
                _isPressed = true;
              });
            },
            onTapUp: (_) {
              // When the button press is released
              setState(() {
                _isPressed = false;
              });
            },
            onTapCancel: () {
              // Handle cases where the press is interrupted
              setState(() {
                _isPressed = false;
              });
            },
            child: Container(
              height: 60,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(30), // Curved corners
              ),
              child: Center(
                child: Text(
                  'Create Your Own Event/List',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: "Lobster",
                    color: _isPressed ? Colors.blueGrey.shade800 : Colors.blue.shade400, // Dynamic color change
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Image.asset('asset/pp1.jpg', width: 150),
                const Text(
                  "Nour",
                  style: TextStyle(
                    fontSize: 33,
                    fontFamily: "Lobster",
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
