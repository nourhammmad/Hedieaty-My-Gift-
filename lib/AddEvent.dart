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
  final String? date;



  const AddEvent({
    this.id,
    this.title,
    this.description,
    this.status,
    this.type,
    this.imageUrl,
    this.date
  }) : super();

  @override
  State<AddEvent> createState() => _AddEventState();
}
class _AddEventState extends State<AddEvent> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  bool isPastStatus = false;
  late TextEditingController dueToController;
  File? _eventImage;
  bool isPledged = false;
  bool imageExists = false;
  String eventStatus = 'Upcoming';
  String eventType = 'Birthday';
  final ImagePicker _imagePicker = ImagePicker();
  bool isEditMode = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  void _selectDueDate(BuildContext context) async {
    DateTime currentDate = DateTime.now();
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: currentDate,
      lastDate: DateTime(2101),
    );
    if (selectedDate != null && selectedDate != currentDate) {
      setState(() {
        dueToController.text = '${selectedDate.toLocal()}'.split(' ')[0];  // format to display date
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _eventImage = File(image.path);
      });
    }
  }

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
      String title = titleController.text;
      String description = descriptionController.text;
      String? dueTo = dueToController.text;
      String? photoUrl;
      if (_eventImage != null) {
        photoUrl = await uploadImageToImgur(_eventImage!.path);
      }else {
         photoUrl = widget.imageUrl;
      }
      if (dueTo == null) {
         dueTo = widget.date;
      }
      try {
         DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();

        if (userDoc.exists) {
          List<dynamic> eventsList = userDoc.get('events_list') ?? [];
          int eventIndex = eventsList.indexWhere((event) => event['eventId'] == eventId);
          if (eventIndex != -1) {
            Map<String, dynamic> updatedEventData = {
              'eventId': eventId,
              'title': title,
              'description': description,
              'status': eventStatus,
              'type': eventType,
              'photoURL': photoUrl == null || photoUrl.isEmpty ? null : photoUrl,
              'gifts': eventsList[eventIndex]['gifts'],
              'dueTo':dueTo
            };
            eventsList[eventIndex] = updatedEventData;
            await _firestore.collection('users').doc(userId).update({
              'events_list': eventsList,
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Event updated successfully!')),
            );
            Navigator.pop(context,'reload');

          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Event not found.')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User document not found.')),
          );
        }
      } catch (e) {
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
     isEditMode = widget.title != null && widget.description != null;
     titleController = TextEditingController(text: widget.title);
    descriptionController = TextEditingController(text: widget.description);
    dueToController= TextEditingController(text: widget.date);
    eventStatus = widget.status ?? 'Upcoming';
    eventType = widget.type ?? 'Birthday';
    isPastStatus = eventStatus == 'Past';
    if (isPastStatus) {
      dueToController.text = 'Not Applicable';
    }
     if (widget.imageUrl != null) {
      imageExists = true;
    }
  }

  void _addEvent() async {
    User? user = _auth.currentUser;
    if (user != null) {
      String userId = user.uid;
      String title = titleController.text;
      String description = descriptionController.text;
      String eventId = _firestore.collection('users').doc().id;

      String? photoUrl;
      if (_eventImage != null) {
         photoUrl = await uploadImageToImgur(_eventImage!.path);
      }
       Map<String, dynamic> eventData = {
        'description': description,
        'eventId': eventId,
        'gifts':null,
        'photoURL':photoUrl != null ? photoUrl : null,
        'status': eventStatus,
        'title': title,
        'type': eventType,
        'dueTo': dueToController.text,
      };

      try {
        CollectionReference eventsRef = _firestore.collection('users');
        await eventsRef.doc(userId).update({
          'events_list': FieldValue.arrayUnion([eventData]),
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
            'Event added successfully!')
        ));
        Navigator.pop(context,'reload');

      } catch (e) {
         print("Error adding event: $e");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An error occurred while adding the event.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: Key('addEventPage'),
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
                      key: const Key('addImageButton'), // Add a unique key here
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
               _buildTextField(
                key: 'titleField',
                controller: titleController,
                label: 'Event Name', keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 10),
                        _buildTextField(
                key: 'descriptionField',
                controller: descriptionController,
                label: 'Description',
                maxLines: 3, keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => !isPastStatus ? _selectDueDate(context) : null,
                child: AbsorbPointer(
                  child: _buildTextField(
                    key: 'dueDateField',
                    controller: dueToController,
                    label: 'Due To',
                    keyboardType: TextInputType.datetime,
                    enabled: !isPastStatus,
          
                  ),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButton<String>(
                value: eventStatus,
                onChanged: (String? newValue) {
                  setState(() {
                    eventStatus = newValue!;
                    isPastStatus = eventStatus == 'Past';
                    dueToController.text = isPastStatus ? 'Not Applicable' : dueToController.text;
                  });
                },
                items: <String>['Past', 'Upcoming','Current']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
                hint: Text('Select Status'),
              ),
              const SizedBox(height: 10),
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
                        ElevatedButton(
                key: Key('saveButton'),
                onPressed: isPledged
                    ? null
                    : () {
                  _saveEvent();
                },
                child: Text(
                  isEditMode ? 'Update Event' : 'Add Event',
                  style: const TextStyle(fontSize: 30, fontFamily: "Lobster", color: Colors.indigo),
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
    bool enabled = true, required TextInputType keyboardType, required String key,
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
        key: Key(key),
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