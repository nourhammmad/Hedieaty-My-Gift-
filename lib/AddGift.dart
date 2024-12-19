import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import 'imgur.dart';

class AddGift extends StatefulWidget {
  const AddGift({super.key});

  @override
  State<AddGift> createState() => _AddGiftState();
}

class _AddGiftState extends State<AddGift> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  File? _giftImage;
  final ImagePicker _imagePicker = ImagePicker();
  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _giftImage = File(image.path);
      });
    }
  }
  String? selectedStatus;
  String? selectedEventId;
  List<Map<String, dynamic>> events = [];
  bool imageExists = false;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      DocumentSnapshot userDoc =
      await _firestore.collection('users').doc(userId).get();

      List<dynamic> eventsList = userDoc['events_list'] ?? [];
      setState(() {
        events = eventsList.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      print('Error fetching events: $e');
    }
  }

  Future<void> _addGift() async {
    try {

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Generate a unique ID for the gift
      String giftId = _firestore
          .collection('users')
          .doc(userId)
          .collection('events_list')
          .doc(selectedEventId)
          .collection('gifts')
          .doc()
          .id;

      String title = titleController.text;
      String description = descriptionController.text;
      String category = categoryController.text;
      String price = priceController.text;
      String? photoUrl;
      if (_giftImage != null) {
        // Upload image to Imgur and get the URL
        photoUrl = await uploadImageToImgur(_giftImage!.path);
      }

      // Find the dueTo date from the selected event
      String dueTo = '';
      for (var event in events) {
        if (event['eventId'] == selectedEventId) {
          dueTo = event['dueTo']; // Assuming 'dueTo' is a field in your event
          break;
        }
      }

      Map<String, dynamic> giftData = {
        'giftId': giftId,
        'title': title,
        'description': description,
        'status': 'Available',
        'category': category,
        'price': price,
        'eventId': selectedEventId,
        'dueTo': dueTo,  // Assign the dueTo from the selected event
        'PledgedBy': null,
        'createdBy': userId,
        'photoURL': photoUrl,
      };

      // Update the `events` list locally
      for (var event in events) {
        if (event['eventId'] == selectedEventId) {
          if (event['gifts'] == null) {
            event['gifts'] = [];
          }
          event['gifts'].add(giftData);
          break;
        }
      }

      // Update the Firestore database
      CollectionReference usersRef = _firestore.collection('users');
      await usersRef.doc(userId).update({
        'events_list': events,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gift added successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      print('Error adding gift: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error adding gift.')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: Key('addGiftPage'),  // Assign a key here
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
        child: SingleChildScrollView(
          child: Column(
            children: [
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
            CircleAvatar(
            radius: 90,
            backgroundColor: Colors.indigo.shade100,
            child: _giftImage != null
                ? ClipOval(
              child: Image.file(
                _giftImage!,
                width: 160, // Match the CircleAvatar size
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
          
              DropdownButtonFormField<String>(
                key: Key('eventDropdown'),  // Add the key here
                value: selectedEventId,
                hint: const Text('Select Event'),
                items: events
                    .where((event) => event['status'] != 'Past') // Filter out past events
                    .map((event) {
                  return DropdownMenuItem<String>(
                    value: event['eventId'],
                    child: Text(event['title']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedEventId = value;
                  });
                },
              ),
          
              const SizedBox(height: 20),
          
              _buildTextField(
          
                controller: titleController,
                label: 'Gift Name', key: 'titleField',
              ),
              const SizedBox(height: 10),
          
              _buildTextField(
                controller: descriptionController,
                label: 'Description',
                maxLines: 3, key: 'descriptionField',
              ),
              const SizedBox(height: 10),
          
              _buildTextField(
                controller: categoryController,
                label: 'Category (e.g., Electronics)', key: 'Category',
              ),
              const SizedBox(height: 10),
          
              _buildTextField(
                controller: priceController,
                label: 'Price',
                keyboardType: TextInputType.number, key: 'Price',
              ),
              const SizedBox(height: 20),
          
          
              ElevatedButton(
                key: Key('saveButton'),  // Add the key here
                onPressed: _addGift,
                child: const Text(
                  'Add Gift',
                  style: TextStyle(fontSize: 30,fontFamily: "Lobster",color: Colors.indigo),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,required String key,
  }) {
    return TextField(
      key: Key(key),  // Add the key here
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40.0),
        ),
      ),
    );
  }
}
