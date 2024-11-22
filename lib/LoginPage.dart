import 'package:flutter/material.dart';
import 'Database.dart';
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
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    bool isValid = await _dbHelper.validateLogin(
                        emailController.text, passwordController.text);

                    if (isValid) {
                      // If login is valid, navigate to the next page (e.g., home page)
                      Navigator.pushReplacementNamed(context, '/');
                    } else {
                      // If login is invalid, show a message
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Login Failed'),
                            content: const Text('Invalid email or password.'),
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
