import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:projecttrial/GiftListPage.dart';

import 'imgur.dart';

class GiftDetailsPage extends StatefulWidget {
  final String id;
  final String eventId;
  final String status;
  final String giftName;
  final String description;
  final String image;
  final String category;
  final String price;


  const GiftDetailsPage({
    super.key,
    required this.id,
    required this.eventId,
    required this.status,
    required this.giftName,
    required this.description,
    required this.image,
    required this.category,
    required this.price,
  });

  @override
  State<GiftDetailsPage> createState() => _GiftDetailsPageState();
}

class _GiftDetailsPageState extends State<GiftDetailsPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  File? _giftImage;
  final ImagePicker _imagePicker = ImagePicker();

  bool isPledged = false; // Track whether the gift is pledged

  @override

  void initState() {
    super.initState();
    // Initialize the controllers with the passed values
    titleController.text = widget.giftName;
    descriptionController.text = widget.description;
    categoryController.text = widget.category;
    priceController.text = widget.price.toString();


    // Set the pledged status based on the passed status
    isPledged = widget.status== 'Pledged';
  }
  void updateGiftDetails({
    required bool isPledged,
    required String title,
    required String description,
    required String category,
    required String price,
  }) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final FirebaseAuth _auth = FirebaseAuth.instance;
    String? photoUrl;

    if (_giftImage != null) {
      // Upload image to Imgur and get the URL
      photoUrl = await uploadImageToImgur(_giftImage!.path);
    } else {
      // Retain the existing image URL if no new image is selected
      photoUrl = widget.image;
    }

    // Get current user ID
    User? user = _auth.currentUser;
    if (user != null) {
      String userId = user.uid;

      // Prepare the updated gift data
      Map<String, dynamic> updatedGiftData = {
        'createdBy': userId,
        'eventId': widget.eventId,
        'giftId': widget.id, // Using the passed giftId
        'title': title,
        'description': description,
        'category': category,
        'price': price,
        'photoURL': photoUrl == null || photoUrl.isEmpty ? null : photoUrl, // Set to null if empty
        'status': isPledged ? 'Pledged' : 'Available', // Update status based on isPledged
      };

      try {
        // Reference to the user's collection
        DocumentReference userDocRef = _firestore.collection('users').doc(userId);

        // Retrieve the user's events_list
        DocumentSnapshot userSnapshot = await userDocRef.get();
        if (userSnapshot.exists) {
          List<dynamic> eventsList = userSnapshot['events_list'];

          // Find the event with the given eventId
          var event = eventsList.firstWhere(
                (event) => event['eventId'] == widget.eventId,
            orElse: () => null,
          );

          if (event != null) {
            List<dynamic> giftsList = event['gifts'] ?? [];

            // Find the gift within the event using giftId
            var giftIndex = giftsList.indexWhere((gift) => gift['giftId'] == widget.id);

            if (giftIndex != -1) {
              // Retrieve the existing gift to retain 'dueTo' and 'PledgedBy' values
              var currentGift = giftsList[giftIndex];

              // Preserve 'dueTo' and 'PledgedBy' values if they exist
              if (currentGift.containsKey('dueTo')) {
                updatedGiftData['dueTo'] = currentGift['dueTo'];
              }
              if (currentGift.containsKey('PledgedBy')) {
                updatedGiftData['PledgedBy'] = currentGift['PledgedBy'];
              }

              // Update the gift in the list
              if (isPledged) {
                // If pledged, update only the status
                giftsList[giftIndex]['status'] = 'Pledged';
              } else {
                // Otherwise, update all gift details
                giftsList[giftIndex] = updatedGiftData;
              }

              // Update the events_list with the modified gifts list
              await userDocRef.update({
                'events_list': eventsList,
              });

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gift updated successfully!')));
              Navigator.pop(context, 'reload');
            } else {
              // Gift not found
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gift not found in this event.')));
            }
          } else {
            // Event not found
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Event not found.')));
          }
        } else {
          // User not found
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User not found.')));
        }
      } catch (e) {
        // Handle errors
        print("Error updating gift: $e");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An error occurred while updating the gift.')));
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _giftImage = File(image.path);
      });
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
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Stack for profile image and plus icon
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
                          width: 160,
                          height: 160,
                          fit: BoxFit.cover,
                        ),
                      )
                          : widget.image != ''
                          ? ClipOval(
                        child: Image.network(
                          widget.image!,
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
          
              // Status Toggle
              Row(
                children: [
                  const Text("Status:", style: TextStyle(fontFamily: "Lobster", color: Colors.indigo, fontSize: 25)),
                  Switch(
                    value: isPledged,
                    onChanged: (value) {
                      setState(() {
                        isPledged = value; // Update the status
                      });
                    },
                    activeColor: Colors.indigo,
                  ),
                  const Text("Pledged", style: TextStyle(fontFamily: "Lobster", color: Colors.indigo, fontSize: 25)),
                ],
              ),
              const SizedBox(height: 20),
          
              // Gift Name Field
              _buildTextField(
                controller: titleController,
                label: 'Gift Name',
                enabled: !isPledged, // Disable if pledged
              ),
              const SizedBox(height: 10),
          
              // Description Field
              _buildTextField(
                controller: descriptionController,
                label: 'Description',
                maxLines: 3,
                enabled: !isPledged, // Disable if pledged
              ),
              const SizedBox(height: 10),
          
              // Category Field
              _buildTextField(
                controller: categoryController,
                label: 'Category (e.g., Electronics, Books)',
                enabled: !isPledged, // Disable if pledged
              ),
              const SizedBox(height: 10),
          
              // Price Field
              _buildTextField(
                controller: priceController,
                label: 'Price',
                prefixText: '\$', // Adds a dollar sign
                enabled: !isPledged, // Disable if pledged
              ),
              const SizedBox(height: 20),
          
          
              // Submit Button
              Container(
                child: ElevatedButton(
                  onPressed:  () {
                    // Handle the submission logic here
                    String title = titleController.text;
                    String description = descriptionController.text;
                    String category = categoryController.text;
                    String price = priceController.text;
          
          
                    updateGiftDetails(
                      isPledged: isPledged,
                      title: title,
                      description: description,
                      category: category,
                      price: price,
                    );                },
                  child: const Text(
                    'Save Gift Details',
                    style: TextStyle(fontSize: 30, fontFamily: "Lobster", color: Colors.indigo),
                  ),
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
    String? prefixText,
    bool enabled = true, // Added parameter to enable/disable
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // White background
        borderRadius: BorderRadius.circular(30.0), // Curved corners
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5), // Shadow color
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3), // Position of the shadow
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        enabled: enabled, // Set enabled state
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0), // Curved corners
            borderSide: BorderSide.none, // Remove border lines
          ),
          prefixText: prefixText,
        ),
      ),
    );
  }
}
