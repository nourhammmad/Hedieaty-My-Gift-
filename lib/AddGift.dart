import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      if (selectedEventId == null || selectedStatus == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields!')),
        );
        return;
      }

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      String title = titleController.text;
      String description = descriptionController.text;
      String category = categoryController.text;
      String price = priceController.text;

      Map<String, dynamic> giftData = {
        'title': title,
        'description': description,
        'status': selectedStatus,
        'category': category,
        'price': price,
        'eventId': selectedEventId,
      };

      for (var event in events) {
        if (event['eventId'] == selectedEventId) {
          if (event['gifts'] == null) {
            event['gifts'] = [];
          }
          event['gifts'].add(giftData);
          break;
        }
      }

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
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  ClipOval(

                    child: imageExists
                        ? Image.asset(
                      'asset/placeholder.jpg',
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    )
                        : Container(
                      width: 120,
                      height: 120,
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.image,
                        size: 90,
                        color: Colors.indigo,
                      ),
                    ),
                  ),
                  FloatingActionButton(
                    mini: true,
                    onPressed: () {
                      // Add image selection functionality
                    },
                    child: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: selectedEventId,
              hint: const Text('Select Event'),
              items: events.map((event) {
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
              label: 'Gift Name',
            ),
            const SizedBox(height: 10),

            _buildTextField(
              controller: descriptionController,
              label: 'Description',
              maxLines: 3,
            ),
            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              value: selectedStatus,
              hint: const Text('Select Status'),
              items: const [
                DropdownMenuItem(value: 'Pledged', child: Text('Pledged')),
                DropdownMenuItem(
                    value: 'Not Pledged', child: Text('Not Pledged')),
              ],
              onChanged: (value) {
                setState(() {
                  selectedStatus = value;
                });
              },
            ),
            const SizedBox(height: 10),

            _buildTextField(
              controller: categoryController,
              label: 'Category (e.g., Electronics)',
            ),
            const SizedBox(height: 10),

            _buildTextField(
              controller: priceController,
              label: 'Price',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _addGift,
              child: const Text(
                'Add Gift',
                style: TextStyle(fontSize: 20),
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
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
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
