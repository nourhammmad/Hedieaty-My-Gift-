import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      String? title = message.notification?.title;
      String? body = message.notification?.body;

      if (title != null && body != null) {
        print("Foreground Notification Received: $title");
        showDialog(
          context: navigatorKey.currentContext!, // Replace with your app's navigation context
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(title, style: TextStyle(
                fontSize: 30,
                color: Colors.indigo,
              ),),
              content: Text(body , style: TextStyle(
                fontSize: 25,
                color: Colors.black87,
              ),),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("OK",
                    style: TextStyle(
                      fontSize: 30,
                      color: Colors.red,
                    ),),
                )
              ],
            );
          },
        );
      } else {
        print("Notification received but title or body is null");
      }
    }
  });

  runApp(
    MaterialApp(
      navigatorKey: navigatorKey, // Set the global key here
      home: MyApp(),
    ),
  );}


Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
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

