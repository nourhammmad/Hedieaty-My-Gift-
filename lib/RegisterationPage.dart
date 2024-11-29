import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import 'FirebaseDatabaseClass.dart';

class RegistrationPage extends StatefulWidget {
  RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController displayNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  late FirebaseDatabaseClass _firebaseDb; // Use FirebaseDatabaseClass

  File? _profileImage;
  final ImagePicker _imagePicker = ImagePicker();
  @override
  void initState() {
    super.initState();
    _firebaseDb = FirebaseDatabaseClass(); // Initialize FirebaseDatabaseClass
  }
  // Function to pick image from the gallery
  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  // Function to upload the image to Imgur
  Future<String> uploadImageToImgur(String imagePath) async {
    final String clientId = 'f9d1ca87570ca34'; // Replace with your Client ID
    final Uri url = Uri.parse('https://api.imgur.com/3/image');
    final imageBytes = File(imagePath).readAsBytesSync();
    final base64Image = base64Encode(imageBytes);

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Client-ID $clientId',
        },
        body: {
          'image': base64Image,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['link']; // Image URL
      } else {
        throw Exception('Failed to upload image. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  // Function to save user data including image URL in Firestore
  Future<void> _registerUser() async {
    if (_formKey.currentState?.validate() ?? false) {
      String displayName = displayNameController.text;
      String email = emailController.text;
      String password = passwordController.text;
      String phone = phoneController.text;

      try {
        String? photoUrl;
        if (_profileImage != null) {
          // Upload image to Imgur and get the URL
          photoUrl = await uploadImageToImgur(_profileImage!.path);
        }
        User? user = await _firebaseDb.registerUser(displayName, email, password, phone,photoUrl);

        // Save user data to Firestore
        // await FirebaseFirestore.instance.collection('users').add({
        //   'displayName': displayName,
        //   'email': email,
        //   'password': password, // Password should be hashed for real apps
        //   'phone': phone,
        //   'photoUrl': photoUrl, // Save the Imgur URL here
        // });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User registered successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushNamed(context, '/Login');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
            Icon(Icons.person_add, color: Colors.indigo, size: 25),
          ],
        ),
        titleSpacing: 125.0,
        toolbarHeight: 70,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Create an Account",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    fontFamily: "Lobster",
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(height: 20),
                // Profile Picture Upload
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 70,
                        backgroundColor: Colors.indigo.shade100,
                        child: _profileImage != null
                            ? ClipOval(
                          child: Image.file(
                            _profileImage!,
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
                // Form Fields
                _buildTextField(
                  controller: displayNameController,
                  label: 'Name',
                  icon: Icons.person,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Name is required'
                      : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: emailController,
                  label: 'Email',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Email is required'
                      : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: passwordController,
                  label: 'Password',
                  icon: Icons.lock,
                  obscureText: true,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Password is required'
                      : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: phoneController,
                  label: 'Phone Number',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Phone number is required'
                      : null,
                ),
                const SizedBox(height: 20),
                // Register Button
                ElevatedButton(
                  onPressed: _registerUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                  ),
                  child: const Text(
                    'Register',
                    style: TextStyle(
                      fontSize: 30,
                      fontFamily: "Lobster",
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/Login');
                  },
                  child: Text(
                    "Already have an account? Log In",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.indigo.shade300,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.indigo.shade200),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
    );
  }
}
