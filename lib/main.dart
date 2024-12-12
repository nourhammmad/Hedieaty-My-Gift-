import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'HomePage.dart';
import 'FriendsGiftList.dart';
import 'MyProfile.dart';
import 'MyPledgedGiftsPage.dart';
import 'EventsListPage.dart';
import 'GiftListPage.dart';
import 'GiftDetailsPage.dart';
import 'EventDetailsPage.dart';
import 'AddEvent.dart';
import 'GiftOrEvent.dart';
import 'AddGift.dart';
import 'LoginPage.dart';
import 'RegisterationPage.dart';
import 'FriendsEvent.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // try {
  //   // Test Firebase Auth
  //   final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
  //     email: 'testuser@example.com',
  //     password: 'password123',
  //   );
  //   print("User registered successfully with UID: ${credential.user?.uid}");
  // } catch (e) {
  //   print("Error during Firebase Authentication: $e");
  // }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo.shade50),
        useMaterial3: true,
          scaffoldBackgroundColor:Colors.indigo.shade50
      ),
      initialRoute:'/Login',
      routes:{
        '/':(context)=>HomePage(),
        '/MyProfile':(context)=>MyProfile(),
        '/MyPledgedGiftsPage':(context)=>MyPledgedGiftsPage(),
        '/EventsListPage':(context)=>EventsListPage(userId: '',),
        '/GiftListPage':(context)=>GiftListPage(eventId: '',),
        '/GiftDetailsPage':(context)=>GiftDetailsPage(id: '', eventId: '',status: '', giftName: '', description: '', image: '', category: '', price: '', date: '',),
        '/EventDetailsPage':(context)=>EventDetailsPage(),
        '/AddEvent':(context)=>AddEvent(),
        '/GiftOrEvent':(context)=>GiftOrEvent(),
        '/AddGift':(context)=>AddGift(),
        '/FriendsGiftList':(context)=>FriendsGiftList(userId: '', eventId: '', userName: '',),
        '/Login':(context)=>LoginPage(),
        '/RegisterationPage':(context)=>RegistrationPage(),
        '/FriendsEvent':(context)=>FriendsEvent(userId: '', userName: ''),



      }
    );
  }
}

