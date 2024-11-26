import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'FirebaseDatabaseClass.dart'; // Import your FirebaseDatabaseClass

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

  @override
  void initState() {
    super.initState();
    _firebaseDb = FirebaseDatabaseClass(); // Initialize FirebaseDatabaseClass
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Removes the back button
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Create an Account",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Lobster",
                  color: Colors.indigo.shade300,
                ),
              ),
              const SizedBox(height: 20),
              // Form Fields
              _buildTextField(
                controller: displayNameController,
                label: 'Name',
                icon: Icons.person,
                validator: (value) => value == null || value.isEmpty
                    ? 'First name is required'
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

  Future<void> _registerUser() async {
    if (_formKey.currentState?.validate() ?? false) {
      String displayName = displayNameController.text;
      String email = emailController.text;
      String password = passwordController.text;
      String phone = phoneController.text;

      try {
        User? user = await _firebaseDb.registerUser(displayName, email, password, phone);
        //print("======================================da el user id mn 3and el registeration $user");

        if (user != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User registered successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushNamed(context, '/Login');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration failed: User object is null'),
              backgroundColor: Colors.red,
            ),
          );
        }
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

}