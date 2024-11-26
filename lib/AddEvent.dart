import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AddEvent extends StatefulWidget {
  const AddEvent({super.key});

  @override
  State<AddEvent> createState() => _AddEventState();
}

class _AddEventState extends State<AddEvent> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  bool isPledged = false;
  bool imageExists = false;

  String eventStatus = 'Upcoming';
  String eventType = 'Birthday';

  // Add the Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Function to add an event to Firestore
  void _addEvent() async {
    // Get the current user ID
    User? user = _auth.currentUser;
    if (user != null) {
      String userId = user.uid;

      // Collect data from the text controllers and dropdowns
      String title = titleController.text;
      String description = descriptionController.text;

      // Prepare event data
      Map<String, dynamic> eventData = {
        'title': title,
        'description': description,
        'status': eventStatus,
        'type': eventType,
        'createdAt': Timestamp.now(), // Add a timestamp
      };

      try {
        // Reference to the user's events collection (document is the userId)
        CollectionReference eventsRef = _firestore.collection('users');

        // Update the events array field in the user's document
        await eventsRef.doc(userId).update({
          'events_list': FieldValue.arrayUnion([eventData]), // Add the event to the events array
        });

        // Optionally, show a success message
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Event added successfully!')));
      } catch (e) {
        // Handle errors
        print("Error adding event: $e");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An error occurred while adding the event.')));
      }
    }
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
          children: [
            // Profile image and plus icon
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  ClipOval(
                    child: imageExists
                        ? Image.asset(
                      '', // Placeholder image
                      width: 220,
                      height: 220,
                      fit: BoxFit.cover,
                    )
                        : Container(
                      width: 220,
                      height: 220,
                      color: Colors.grey[200], // Background for no image
                      child: const Center(
                          child: Icon(Icons.person, size: 100, color: Colors.white)),
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
                        // Add image upload logic if needed
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Event Name Field
            _buildTextField(
              controller: titleController,
              label: 'Event Name',
            ),
            const SizedBox(height: 10),

            // Description Field
            _buildTextField(
              controller: descriptionController,
              label: 'Description',
              maxLines: 3,
            ),
            const SizedBox(height: 10),

            // Event Status Dropdown
            DropdownButton<String>(
              value: eventStatus,
              onChanged: (String? newValue) {
                setState(() {
                  eventStatus = newValue!;
                });
              },
              items: <String>['Past', 'Upcoming']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(value: value, child: Text(value));
              }).toList(),
              hint: Text('Select Status'),
            ),
            const SizedBox(height: 10),

            // Event Type Dropdown
            DropdownButton<String>(
              value: eventType,
              onChanged: (String? newValue) {
                setState(() {
                  eventType = newValue!;
                });
              },
              items: <String>['Birthday', 'Wedding Anniversary', 'Graduation']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(value: value, child: Text(value));
              }).toList(),
              hint: Text('Select Event Type'),
            ),
            const SizedBox(height: 10),

            // Submit Button
            ElevatedButton(
              onPressed: isPledged
                  ? null
                  : () {
                _addEvent(); // Add event to Firestore
              },
              child: const Text(
                'Add Event',
                style: TextStyle(fontSize: 30, fontFamily: "Lobster", color: Colors.indigo),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    String? prefixText,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none,
          ),
          prefixText: prefixText,
        ),
      ),
    );
  }
}
