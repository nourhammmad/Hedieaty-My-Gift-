import 'package:flutter/material.dart';
import 'Database.dart'; // Import your database class

class RegistrationPage extends StatefulWidget {
  RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController firstnameController = TextEditingController();
  final TextEditingController lastnameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController(); // Added phone controller

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
              // Name Fields
              TextFormField(
                controller: firstnameController,
                decoration: InputDecoration(
                  labelText: 'First Name',
                  prefixIcon: Icon(Icons.person, color: Colors.indigo.shade200),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                keyboardType: TextInputType.name,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'First name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: lastnameController,
                decoration: InputDecoration(
                  labelText: 'Last Name',
                  prefixIcon: Icon(Icons.person, color: Colors.indigo.shade200),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                keyboardType: TextInputType.name,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Last name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Email Field
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
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Password Field
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
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Phone Field (new)
              TextFormField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone, color: Colors.indigo.shade200),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Phone number is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Register Button
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    String firstname = firstnameController.text;
                    String lastname = lastnameController.text;
                    String email = emailController.text;
                    String password = passwordController.text;
                    String phone = phoneController.text;

                    try {
                      int response = await _dbHelper.insertUser(
                          firstname, lastname, email, password, phone);
                      if (response > 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('User registered successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );

                        // Clear the form fields
                        firstnameController.clear();
                        lastnameController.clear();
                        emailController.clear();
                        passwordController.clear();
                        phoneController.clear();

                        Navigator.pushNamed(context, '/Login');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Registration failed'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } catch (e) {
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
}
