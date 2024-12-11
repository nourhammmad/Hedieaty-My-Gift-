import 'dart:io';
import 'package:projecttrial/EventsListPage.dart';

import 'imgur.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

class AddEvent extends StatefulWidget {
  final String? id;
  final String? title;
  final String? description;
  final String? status;
  final String? type;
  final String? imageUrl;

  const AddEvent({
    Key? key,
    this.id,
    this.title,
    this.description,
    this.status,
    this.type,
    this.imageUrl,
  }) : super(key: key);

  @override
  State<AddEvent> createState() => _AddEventState();
}
class _AddEventState extends State<AddEvent> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;
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
  bool isEditMode = false;
  void _saveEvent() async {
    // Logic for adding or editing the event
    if (isEditMode) {
      _updateEvent(widget.id);
    } else {
      _addEvent();
    }
  }
  void _updateEvent(String? eventId) async {
    User? user = _auth.currentUser;
    if (user != null) {
      String userId = user.uid;

      // Get the updated event details
      String title = titleController.text;
      String description = descriptionController.text;
      String? photoUrl;

      if (_eventImage != null) {
        // Upload image to Imgur and get the URL
        photoUrl = await uploadImageToImgur(_eventImage!.path);
      }

      try {
        // Fetch the user's document
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();

        if (userDoc.exists) {
          List<dynamic> eventsList = userDoc.get('events_list') ?? [];

          // Find the event to update
          int eventIndex = eventsList.indexWhere((event) => event['eventId'] == eventId);

          if (eventIndex != -1) {
            // Update the event data
            Map<String, dynamic> updatedEventData = {
              'eventId': eventId, // Keep the same event ID
              'title': title,
              'description': description,
              'status': eventStatus,
              'type': eventType,
              'photoURL': photoUrl, // Retain old photo URL if no new image
              'gifts': eventsList[eventIndex]['gifts'], // Retain existing gifts
            };

            // Replace the old event data with the updated data
            eventsList[eventIndex] = updatedEventData;

            // Update the user's events_list in Firestore
            await _firestore.collection('users').doc(userId).update({
              'events_list': eventsList,
            });

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Event updated successfully!')),


            );
            Navigator.pop(context,'reload');



          } else {
            // Event not found
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Event not found.')),
            );
          }
        } else {
          // User document not found
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User document not found.')),
          );
        }
      } catch (e) {
        // Handle errors
        print("Error updating event: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred while updating the event.')),
        );
      }
    }
  }


  @override
  void initState() {
    super.initState();

    // Determine if this is edit mode
    isEditMode = widget.title != null && widget.description != null;

    // Initialize controllers with existing values if in edit mode
    titleController = TextEditingController(text: widget.title);
    descriptionController = TextEditingController(text: widget.description);
    eventStatus = widget.status ?? 'Upcoming';
    eventType = widget.type ?? 'Birthday';

    // Load existing image if URL is provided
    if (widget.imageUrl != null) {
      // Here you can use a package like `cached_network_image` or similar to load the image
      // For simplicity, we'll leave this as an indicator to show loading logic
      imageExists = true;
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
        'description': description,
        'eventId': eventId, // Unique ID for event
        'gifts':null,
        'photoURL':photoUrl != null ? photoUrl : null,
        'status': eventStatus,
        'title': title,
        'type': eventType,
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
        Navigator.pop(context,'reload');

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
                    radius: 90,
                    backgroundColor: Colors.indigo.shade100,
                    child: _eventImage != null
                        ? ClipOval(
                      child: Image.file(
                        _eventImage!,
                        width: 160,
                        height: 160,
                        fit: BoxFit.cover,
                      ),
                    )
                        : (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
                        ? ClipOval(
                      child: Image.network(
                        widget.imageUrl!,
                        width: 160,
                        height: 160,
                        fit: BoxFit.cover,
                      ),
                    )
                        : Icon(
                      Icons.image_not_supported,
                      size: 80,
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
                          size:40
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
                _saveEvent(); // Add event to Firestore
              },
              child: Text(
                isEditMode ? 'Update Event' : 'Add Event',

                style: const TextStyle(fontSize: 30, fontFamily: "Lobster", color: Colors.indigo),
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