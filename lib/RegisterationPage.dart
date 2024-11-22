import 'package:flutter/material.dart';
import 'Database.dart'; // Import your database class

class RegistrationPage extends StatefulWidget {
  RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  late Databaseclass _dbHelper;

  @override
  void initState() {
    super.initState();
    _dbHelper = Databaseclass();  // Initialize _dbHelper here
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    await _dbHelper.initialize();
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
              // Name Field with Validator
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person, color: Colors.indigo.shade200),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                keyboardType: TextInputType.name,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Name is required';
                  }
                  return null; // Validation passed
                },
              ),
              const SizedBox(height: 16),
              // Email Field with Validator
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email, color: Colors.indigo.shade200),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email is required';
                  }
                  return null; // Validation passed
                },
              ),
              const SizedBox(height: 16),
              // Password Field with Validator
              TextFormField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock, color: Colors.indigo.shade200),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required';
                  }
                  return null; // Validation passed
                },
              ),
              const SizedBox(height: 20),
              // Register Button
              ElevatedButton(
                onPressed: () async {
                  print('Register button pressed');  // Add this line for debugging

                  if (_formKey.currentState?.validate() ?? false) {
                    // Proceed with registration functionality
                    String name = nameController.text;
                    String email = emailController.text;
                    String password = passwordController.text;

                    try {
                      // Insert the user into the database
                      int response = await _dbHelper.insertUser(name, email, password);
                      if (response > 0) {
                        // Success, show a success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('User registered successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );

                        // Clear the form fields
                        nameController.clear();
                        emailController.clear();
                        passwordController.clear();

                        // Navigate to login page after registration
                        Navigator.pushNamed(context, '/Login');
                      } else {
                        // Handle failure case
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Registration failed'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } catch (e) {
                      // Handle any exception from database insert
                      print("Error during registration: $e");
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('An error occurred: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
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
              // Login Link
              GestureDetector(
                onTap: () {
                  // Navigate to Login Page
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
}
