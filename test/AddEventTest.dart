import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:projecttrial/AddEvent.dart';
import 'dart:io';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockImagePicker extends Mock implements ImagePicker {}
class MockFirebaseUser extends Mock implements User {}

void main() {
  group('AddEvent Widget Tests', () {
    late MockFirebaseAuth mockFirebaseAuth;
    late MockFirebaseFirestore mockFirebaseFirestore;
    late MockImagePicker mockImagePicker;
    late MockFirebaseUser mockUser;

    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
      mockFirebaseFirestore = MockFirebaseFirestore();
      mockImagePicker = MockImagePicker();
      mockUser = MockFirebaseUser();
    });

    testWidgets('AddEvent widget renders correctly', (WidgetTester tester) async {
      // Mock Firebase user authentication
      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);

      // Mock data for AddEvent
      const eventTitle = "Birthday Party";
      const eventDescription = "A fun birthday celebration!";
      const eventDate = "2024-12-17";

      await tester.pumpWidget(
        MaterialApp(
          home: AddEvent(
            title: eventTitle,
            description: eventDescription,
            date: eventDate,
          ),
        ),
      );

      // Verify if the text fields are rendered with correct initial values
      expect(find.text(eventTitle), findsOneWidget);
      expect(find.text(eventDescription), findsOneWidget);
      expect(find.text(eventDate), findsOneWidget);
    });

    // testWidgets('Test image picking functionality', (WidgetTester tester) async {
    //   // Simulate image selection
    //   final XFile mockImage = XFile('mock_image_path.jpg');
    //
    //   // Mock the image picker to return a mock image
    //   when(mockImagePicker.pickImage(source: ImageSource.gallery)).thenAnswer(
    //         (_) async => mockImage,
    //   );
    //
    //   await tester.pumpWidget(
    //     MaterialApp(
    //       home: AddEvent(
    //         imageUrl: 'https://example.com/old_image.jpg',
    //       ),
    //     ),
    //   );
    //
    //   // Trigger the image picker
    //   await tester.tap(find.byIcon(Icons.add));
    //   await tester.pumpAndSettle();
    //
    //   // Verify that the image is displayed
    //   expect(find.byType(CircleAvatar), findsOneWidget);
    // });

    // test('Save event adds new event to Firestore', () async {
    //   // Mock Firestore interaction
    //   when(mockFirebaseFirestore.collection('users')).thenReturn(MockCollectionReference());
    //   when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
    //   when(mockUser.uid).thenReturn('mock_user_id');
    //
    //   // Create an instance of AddEvent
    //   final addEvent = AddEvent(
    //     title: "Test Event",
    //     description: "Test Event Description",
    //     date: "2024-12-17",
    //   );
    //
    //   // Call the method to add the event
    //   await addEvent._addEvent();
    //
    //   // Ensure that the Firestore update function was called
    //   verify(mockFirebaseFirestore.collection('users').doc('mock_user_id').update(any));
    // });
    //
    // test('Update event updates an existing event in Firestore', () async {
    //   // Mock Firestore interaction
    //   when(mockFirebaseFirestore.collection('users')).thenReturn(MockCollectionReference());
    //   when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
    //   when(mockUser.uid).thenReturn('mock_user_id');
    //   when(mockFirebaseFirestore.collection('users').doc('mock_user_id').get())
    //       .thenAnswer((_) async => MockDocumentSnapshot());
    //
    //   // Create an instance of AddEvent with existing event data
    //   final addEvent = AddEvent(
    //     id: 'event_id',
    //     title: "Updated Event",
    //     description: "Updated Event Description",
    //     date: "2024-12-18",
    //   );
    //
    //   // Call the method to update the event
    //   await addEvent._updateEvent('event_id');
    //
    //   // Ensure that Firestore update function was called with the new event data
    //   verify(mockFirebaseFirestore.collection('users').doc('mock_user_id').update(any));
    // });
  });
}

// Mock classes for Firestore and FirebaseAuth
class MockCollectionReference extends Mock implements CollectionReference {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot {}
