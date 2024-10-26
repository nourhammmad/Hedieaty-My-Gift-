import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class GiftDetailsPage extends StatefulWidget {
  const GiftDetailsPage({super.key});

  @override
  State<GiftDetailsPage> createState() => _GiftDetailsPageState();
}

class _GiftDetailsPageState extends State<GiftDetailsPage> {
  // Controllers for input fields
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  bool isPledged = false; // Track whether the gift is pledged

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
            // Stack for profile image and plus icon
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  ClipOval(
                    child: Image.asset(
                      'asset/teddy.jpg', // Placeholder image
                      width: 220,
                      height: 220,
                      fit: BoxFit.cover,
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
                        // Add functionality for the button if needed
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Status Toggle
            Row(
              children: [
                const Text("Status:",style: TextStyle(fontFamily: "Lobster",color: Colors.indigo,fontSize: 25),),
                Switch(
                  value: isPledged,
                  onChanged: (value) {
                    setState(() {
                      isPledged = value; // Update the status
                    });
                  },
                  activeColor: Colors.indigo,
                ),
                const Text("Pledged",style: TextStyle(fontFamily: "Lobster",color: Colors.indigo,fontSize: 25),),
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
                onPressed: isPledged ? null : () {
                  // Handle the submission logic here
                  String title = titleController.text;
                  String description = descriptionController.text;
                  String category = categoryController.text;
                  String price = priceController.text;

                  // Implement your save logic here
                },
                child: const Text(
                  'Save Gift Details',
                  style: TextStyle(fontSize: 30, fontFamily: "Lobster", color: Colors.indigo),
                ),
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
