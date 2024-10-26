import 'package:flutter/material.dart';
import 'HomePage.dart';
import 'FriendsPage.dart';
import 'MyProfile.dart';
import 'MyPledgedGiftsPage.dart';
import 'EventsListPage.dart';
import 'GiftListPage.dart';
import 'GiftDetailsPage.dart';

void main() {
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
      initialRoute:'/',
      routes:{
        '/':(context)=>HomePage(),
        '/FriendsPage':(context)=>FriendsPage(),
        '/MyProfile':(context)=>MyProfile(),
        '/MyPledgedGiftsPage':(context)=>MyPledgedGiftsPage(),
        '/EventsListPage':(context)=>EventsListPage(),
        '/GiftListPage':(context)=>GiftListPage(),
        '/GiftDetailsPage':(context)=>GiftDetailsPage(),

      }
    );
  }
}

