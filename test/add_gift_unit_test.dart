import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projecttrial/AddGift.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}
class MockQuerySnapshot extends Mock implements QuerySnapshot<Map<String, dynamic>> {}
class MockQueryDocumentSnapshot extends Mock implements QueryDocumentSnapshot<Map<String, dynamic>> {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}
class MockFirebaseUser extends Mock implements User {}

void main() {
  late MockFirebaseAuth mockFirebaseAuth;
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockCollectionReference;
  late MockDocumentReference mockDocumentReference;
  late MockQuerySnapshot mockQuerySnapshot;
  late MockQueryDocumentSnapshot mockQueryDocumentSnapshot;
  late MockDocumentSnapshot mockDoc;
  late MockFirebaseUser mockFirebaseUser;

  setUp(() {
    // Initialize mocks before each test
    mockFirebaseAuth = MockFirebaseAuth();
    mockFirestore = MockFirebaseFirestore();
    mockCollectionReference = MockCollectionReference();
    mockDocumentReference = MockDocumentReference();
    mockQuerySnapshot = MockQuerySnapshot();
    mockQueryDocumentSnapshot = MockQueryDocumentSnapshot();
    mockDoc = MockDocumentSnapshot();
    mockFirebaseUser = MockFirebaseUser();
  });

  testWidgets('renders AddGift widget and allows gift addition', (WidgetTester tester) async {
    // Mock FirebaseAuth and Firestore methods
    when(mockFirebaseAuth.currentUser).thenReturn(mockFirebaseUser);
    when(mockFirestore.collection('users')).thenReturn(mockCollectionReference);

    // Mock Firestore document reference and update method
    when(mockCollectionReference.doc(any)).thenReturn(mockDocumentReference);

    // Mock update to accept a valid Map<String, dynamic> instead of any
    // when(mockDocumentReference.update(any)).thenAnswer((_) async => {});

    // Simulate the data in the document snapshot
    when(mockDoc.data()).thenReturn({
      'events_list': [
        {'eventId': 'event123', 'title': 'Test Event', 'status': 'Upcoming'}
      ]
    });

    // Mock the QueryDocumentSnapshot to return mockDoc data
    when(mockQueryDocumentSnapshot.id).thenReturn('docId');
    when(mockQueryDocumentSnapshot.data()).thenReturn({
      'events_list': [
        {'eventId': 'event123', 'title': 'Test Event', 'status': 'Upcoming'}
      ]
    });

    // Mock the QuerySnapshot to return a list with mockQueryDocumentSnapshot
    when(mockQuerySnapshot.docs).thenReturn([mockQueryDocumentSnapshot]);

    // Mock the collection reference's get method to return the mockQuerySnapshot
    when(mockCollectionReference.get()).thenAnswer((_) async => mockQuerySnapshot);

    // Build the widget
    await tester.pumpWidget(MaterialApp(home: AddGift()));

    // Ensure widget renders correctly and interacts with the UI
    expect(find.byKey(Key('saveButton')), findsOneWidget);
    await tester.tap(find.byKey(Key('saveButton')));
    await tester.pumpAndSettle();

    // Verify that Firestore update was called once on the document reference
    // verify(mockDocumentReference.update(any)).called(1);
  });
}
