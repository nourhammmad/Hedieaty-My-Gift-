// import 'package:firebase_core/firebase_core.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:flutter/material.dart';
// import 'package:mockito/mockito.dart';
// import 'package:projecttrial/FriendsGiftList.dart'; // Your actual widget location
//
// // Mock classes
// class MockFirestore extends Mock implements FirebaseFirestore {}
//
// class MockCollectionReference extends Mock implements CollectionReference {}
//
// class MockQuerySnapshot extends Mock implements QuerySnapshot {}
//
// class MockDocumentSnapshot extends Mock implements DocumentSnapshot {}
//
// void main() {
//   // Group the tests for the FriendsGiftList widget
//   group('FriendsGiftList Widget Tests', () {
//     late MockFirebaseAuth mockFirebaseAuth;
//     late MockFirebaseFirestore mockFirebaseFirestore;
//     late MockImagePicker mockImagePicker;
//     late MockFirebaseUser mockUser;
//     // Initialize Firebase before running the tests
//     setUp(() {
//       mockFirebaseAuth = MockFirebaseAuth();
//       mockFirebaseFirestore = MockFirebaseFirestore();
//       mockImagePicker = MockImagePicker();
//       mockUser = MockFirebaseUser();
//     });
//     testWidgets('Displays loading indicator and loads gifts list', (WidgetTester tester) async {
//       // Create mock Firestore and collection references
//       final mockFirestore = MockFirestore();
//       final mockCollection = MockCollectionReference();
//       final mockQuerySnapshot = MockQuerySnapshot();
//
//       // Set up the mock to return a collection reference when `collection('gifts')` is called
//       when(mockFirestore.collection('gifts')).thenReturn(mockCollection);
//
//       // Set up the mock collection to return a mock query snapshot
//       when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
//
//       // Optionally, set up the query snapshot to return mock data when calling docs
//       final mockDocumentSnapshot = MockDocumentSnapshot();
//       when(mockQuerySnapshot.docs).thenReturn([mockDocumentSnapshot]);
//       when(mockDocumentSnapshot.data()).thenReturn({
//         'name': 'Gift 1',
//         'price': 10,
//         'category': 'Electronics',
//         'PledgedBy': '',
//         'createdBy': 'user123',
//         'description': 'A cool gift',
//         'dueTo': '2024-12-25',
//         'status': 'Available',
//         'giftId': 'gift1',
//         'photoURL': '',
//       });
//
//       // Act: Set up the widget with the necessary parameters and Firestore data
//       await tester.pumpWidget(
//         MaterialApp(
//           home: Scaffold(
//             body: FriendsGiftList(
//               userId: 'user123',
//               eventId: 'event456',
//               userName: 'John Doe',
//               firestore: mockFirestore, // Inject mockFirestore into the widget
//             ),
//           ),
//         ),
//       );
//
//       // Act: Trigger the widget to load data and wait for Firestore interaction
//       await tester.pumpAndSettle();
//
//       // Assert: Verify that the loading indicator is no longer displayed
//       expect(find.byType(CircularProgressIndicator), findsNothing);
//
//       // Assert: Verify that the gift "Gift 1" is shown on the screen
//       expect(find.text('Gift 1'), findsOneWidget);
//     });
//   });
// }
