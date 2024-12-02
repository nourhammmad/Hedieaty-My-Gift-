import 'dart:io';
import 'imgur.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

class AddEvent extends StatefulWidget {
  const AddEvent({super.key});

  @override
  State<AddEvent> createState() => _AddEventState();
}

class _AddEventState extends State<AddEvent> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  File? _eventImage;

  bool isPledged = false;
  bool imageExists = false;

  String eventStatus = 'Upcoming';
  String eventType = 'Birthday';
  final ImagePicker _imagePicker = ImagePicker();

  // Add the Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _eventImage = File(image.path);
      });
    }
  }
  // Function to add an event to Firestore
    void _addEvent() async {
      User? user = _auth.currentUser;
      if (user != null) {
        String userId = user.uid;
        String title = titleController.text;
        String description = descriptionController.text;

        // Generate a unique event ID using Firestore document ID
        String eventId = _firestore.collection('users').doc().id;

          String? photoUrl;
          if (_eventImage != null) {
            // Upload image to Imgur and get the URL
            photoUrl = await uploadImageToImgur(_eventImage!.path);
          }
        // Prepare event data
        Map<String, dynamic> eventData = {
          'eventId': eventId, // Unique ID for event
          'title': title,
          'description': description,
          'status': eventStatus,
          'type': eventType,
          'photoURL':photoUrl,
          'gifts':null,
        };

        try {
          // Reference to the user's events collection (document is the userId)
          CollectionReference eventsRef = _firestore.collection('users');

          // Update the events array field in the user's document
          await eventsRef.doc(userId).update({
            'events_list': FieldValue.arrayUnion([eventData]), // Add event to the list
          });

          // Show success message
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
                  CircleAvatar(
                    radius: 70,
                    backgroundColor: Colors.indigo.shade100,
                    child: _eventImage != null
                        ? ClipOval(
                      child: Image.file(
                        _eventImage!,
                        width: 140, // Match the CircleAvatar size
                        height: 140,
                        fit: BoxFit.cover,
                      ),
                    )
                        : Icon(
                      Icons.person,
                      size: 70,
                      color: Colors.indigo.shade300,
                    ),
                  ),
                  InkWell(
                    onTap: _pickImage,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.indigo,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                      ),
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
