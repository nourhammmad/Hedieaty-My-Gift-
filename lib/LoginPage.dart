import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'Database.dart';
import 'UserSession.dart';  // Import the UserSession class

class HoverEffectText extends StatefulWidget {
  @override
  _HoverEffectTextState createState() => _HoverEffectTextState();
}

class _HoverEffectTextState extends State<HoverEffectText> {
  Color _textColor = Colors.indigo.shade300;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _textColor = Colors.indigo.shade500; // Change color on hover
        });
      },
      onExit: (_) {
        setState(() {
          _textColor = Colors.indigo.shade300; // Revert color when hover ends
        });
      },
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, '/RegisterationPage');
        },
        child: Text(
          "Don't have an account? Register",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  late Databaseclass _dbHelper;

  @override
  void initState() {
    super.initState();
    _dbHelper = Databaseclass();  // Initialize _dbHelper here
    //_dbHelper.mydeletedatabase();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    await _dbHelper.initialize();
  }

  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Step 1: Check the local database for the user

      bool isLocalValid = await _dbHelper.validateLogin(
        emailController.text,
        passwordController.text,
      );
      //print("================================isLocalValid:$isLocalValid ");

      if (isLocalValid) {
        // Fetch user details from the local database
        var result = await _dbHelper.readData(
          "SELECT * FROM Users WHERE EMAIL = ? AND PASSWORD = ?",
          [emailController.text, passwordController.text],
        );

        if (result.isNotEmpty) {
          // Local user found
          print("========================================found");

          //await UserSession.saveUserSession(userId, userName);
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: emailController.text,
            password: passwordController.text,
          );
          // Navigate to home page
          Navigator.pushReplacementNamed(context, '/');
          return; // Stop further processing
        }
      }

      // Step 2: If not found in the local database, validate with Firebase
      try {
        // Attempt Firebase authentication
        final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );

        User? firebaseUser = userCredential.user;

        if (firebaseUser != null) {
          // Firebase user found, sync with local database
          await _dbHelper.insertOrUpdateUser({
            'FIREBASE_ID': firebaseUser.uid, // Firebase UID as TEXT
            'EMAIL': firebaseUser.email,
            'displayName': firebaseUser.displayName,
            'PASSWORD': passwordController.text,
          });


          //await UserSession.saveUserSession(firebaseUser.uid, firebaseUser.displayName);

          // Navigate to home page
          Navigator.pushReplacementNamed(context, '/');
        }
      } catch (e) {
        // Handle Firebase errors (e.g., wrong credentials, user not found)
        _showErrorDialog('Firebase Authentication Failed: $e');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Login Failed'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
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
            Icon(Icons.lock, color: Colors.indigo, size: 25),
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
                "Welcome Back!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Lobster",
                  color: Colors.indigo.shade300,
                ),
              ),
              const SizedBox(height: 20),
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
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                child: const Text(
                  'Log In',
                  style: TextStyle(
                    fontSize: 30,
                    fontFamily: "Lobster",
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              HoverEffectText(), // Use the HoverEffectText widget here
            ],
          ),
        ),
      ),
    );
  }
}