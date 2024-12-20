import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'Database.dart';
import 'UserSession.dart';  // Import the UserSession class
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
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
          _textColor = Colors.indigo.shade500;
        });
      },
      onExit: (_) {
        setState(() {
          _textColor = Colors.indigo.shade300;
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
    _dbHelper = Databaseclass(); // Initialize _dbHelper here
   }

  Future<void> _login() async {
    bool online = false;
    try {
      var internetConnection = InternetConnection();
      if (internetConnection != null) {
        online = await internetConnection.hasInternetAccess;
      }
    } catch (e) {
       print("Error checking internet connection: $e");
    }
    if (_formKey.currentState?.validate() ?? false) {
       bool isLocalValid = await _dbHelper.validateLogin(
        emailController.text,
        passwordController.text,
      );

      if (isLocalValid) {
         var result = await _dbHelper.readData(
          "SELECT * FROM Users WHERE EMAIL = ? AND PASSWORD = ?",
          [emailController.text, passwordController.text],
        );
        String userId = result.isNotEmpty && result[0]['FIREBASE_ID'] != null
            ? result[0]['FIREBASE_ID']
            : 'offline_user';
        String userName = result.isNotEmpty && result[0]['displayName'] != null
            ? result[0]['displayName']
            : 'Offline User';

        await UserSession.saveUserSession(userId, userName);

        if (result.isNotEmpty) {
           print("User found locally");
           if (online) {
            try {
              await FirebaseAuth.instance.signInWithEmailAndPassword(
                email: emailController.text,
                password: passwordController.text,
              );
              print("User authenticated with Firebase");
            } catch (e) {
               _showErrorDialog('Incorrect email or password');
              print("Firebase authentication failed: $e");
            }
          }

           Navigator.pushReplacementNamed(context, '/HomePage');
          return;
        }
      }

       if (online) {
        try {
          final userCredential = await FirebaseAuth.instance
              .signInWithEmailAndPassword(
            email: emailController.text,
            password: passwordController.text,
          );

          User? firebaseUser = userCredential.user;

          if (firebaseUser != null) {
            await _dbHelper.insertOrUpdateUser({
              'FIREBASE_ID': firebaseUser.uid,
              'EMAIL': firebaseUser.email ?? '',
              'displayName': firebaseUser.displayName ?? 'Unknown User',
              'PASSWORD': passwordController.text,
            });
            Navigator.pushReplacementNamed(context, '/HomePage');
          } else {
            print("Firebase user is null.");
          }
        } catch (e) {
           _showErrorDialog('Incorrect email or password');
        }
      } else {
         print("No internet connection");
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
        automaticallyImplyLeading: false,
        backgroundColor: Colors.indigo.shade50,
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
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
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
             Container(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Icon(Icons.card_giftcard_outlined, color: Colors.indigo.shade100,
                  size: 260),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Center(
                  child: SingleChildScrollView(
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
                          key: Key('usernameField'),
                          controller: emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email,
                                color: Colors.indigo.shade200),
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
                        const SizedBox(height: 19),
                        TextFormField(
                          key: Key('passwordField'),
                          controller: passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock,
                                color: Colors.indigo.shade200),
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
                          key: Key('loginButton'),
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
                        HoverEffectText(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}