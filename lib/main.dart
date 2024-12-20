import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
 import 'AddEvent.dart';
import 'GiftOrEvent.dart';
import 'AddGift.dart';
import 'LoginPage.dart';
import 'RegisterationPage.dart';
import 'FriendsEvent.dart';
import 'dart:async';
FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

final StreamController<Map<String, String>> _notificationStreamController = StreamController.broadcast();

Stream<Map<String, String>> get notificationStream => _notificationStreamController.stream;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  _createNotificationChannel();

  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('app_icon');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      String? title = message.notification?.title ?? "No Title";
      String? body = message.notification?.body ?? "No Body";
      _showForegroundNotification(title, body);
    } else {
      print("Notification received but no data available.");
    }
  });

  runApp(MyApp());
}

void _createNotificationChannel() async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'default_channel_id',
    'Default',
    description: 'Default notification channel',
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

void _showForegroundNotification(String title, String body) {
  try {
    // Push the notification data to the stream
    _notificationStreamController.add({'title': title, 'body': body});
    print('Notification received in app: $title, $body');
    const AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(
      'default_channel_id',
      'Default',
      channelDescription: 'Default notification channel',
      importance: Importance.high,
      priority: Priority.high,
      visibility: NotificationVisibility.public,
    );

    const NotificationDetails notificationDetails =
    NotificationDetails(android: androidNotificationDetails);

    flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      title,
      body,
      notificationDetails,
    );
    print('Notification shown: $title, $body');
  } catch (e) {
    print('Error adding notification to stream: $e');
  }
}


Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
}
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final List<Map<String, String>> notificationList = [];
  late Stream<Map<String, String>> notificationStream;
  void _dismissNotification(Map<String, String> notification) {
     notificationList.add(notification);

     Future.delayed(const Duration(seconds: 5), () {
      _notificationStreamController.add({});
    });
  }
  @override
  void initState() {
    super.initState();
    notificationStream = _notificationStreamController.stream;
  }
  @override
  void dispose() {
    _notificationStreamController.close();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: StreamBuilder<Map<String, String>>(
        stream: notificationStream,
        builder: (context, snapshot) {
          bool hasNotification = snapshot.hasData && snapshot.data!.isNotEmpty;

          if (hasNotification) {
            _dismissNotification(snapshot.data!);
          }

          return Stack(
            children: [
              MaterialApp(
                theme: ThemeData(
                  colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo.shade50),
                  useMaterial3: true,
                  scaffoldBackgroundColor: Colors.indigo.shade50,
                ),
                initialRoute: '/Login',
                routes: {
                  '/HomePage': (context) => HomePage(),
                  '/MyProfile': (context) => MyProfile(),
                  '/MyPledgedGiftsPage': (context) => MyPledgedGiftsPage(),
                  '/EventsListPage': (context) => EventsListPage(userId: ''),
                  '/GiftListPage': (context) => GiftListPage(eventId: ''),
                  '/GiftDetailsPage': (context) => GiftDetailsPage(
                    id: '',
                    eventId: '',
                    status: '',
                    giftName: '',
                    description: '',
                    image: '',
                    category: '',
                    price: '',
                  ),
                   '/AddEvent': (context) => AddEvent(),
                  '/GiftOrEvent': (context) => GiftOrEvent(),
                  '/AddGift': (context) => AddGift(),
                  '/FriendsGiftList': (context) =>
                      FriendsGiftList(userId: '', eventId: '', userName: ''),
                  '/Login': (context) => LoginPage(),
                  '/RegisterationPage': (context) => RegistrationPage(),
                  '/FriendsEvent': (context) => FriendsEvent(userId: '', userName: ''),
                },
              ),
              if (hasNotification)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.indigo,
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          snapshot.data!['title'] ?? '',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 25),
                        ),
                        Text(
                          snapshot.data!['body'] ?? '',
                          style: const TextStyle(color: Colors.white, fontSize: 25),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}