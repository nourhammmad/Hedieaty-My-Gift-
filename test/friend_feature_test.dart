import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter/material.dart';
import 'package:projecttrial/HomePage.dart';

void main() {
  group('Friend Feature Tests', () {
    late FakeFirebaseFirestore firestore;

    setUp(() {
      firestore = FakeFirebaseFirestore();
    });

    // Test: Check if user exists by phone number
    test('Check if user exists by phone number', () async {
      // Arrange
      print('Arranging test: Add user to Firestore');
      await firestore.collection('users').add({
        'phoneNumber': '123456789',
        'displayName': 'John Doe',
      });

      // Act
      print('Acting: Fetching user from Firestore');
      final querySnapshot = await firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: '123456789')
          .get();

      // Assert
      print('Asserting: Verifying the user exists');
      expect(querySnapshot.docs.length, 1);
      expect(querySnapshot.docs.first['displayName'], 'John Doe');
    });

    // Test: Check if user does not exist
    test('Check if user does not exist by phone number', () async {
      // Act
      print('Acting: Checking for non-existing user');
      final querySnapshot = await firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: '000000000')
          .get();

      // Assert
      print('Asserting: User does not exist');
      expect(querySnapshot.docs.length, 0);
    });

    // Test: Check if already friends
    test('Check if user is already a friend', () async {
      // Arrange
      print('Arranging test: Adding a friend to the list');
      final currentUserId = 'user1';
      final friendId = 'user2';
      await firestore.collection('friend_list').doc(currentUserId).set({
        'friends': [friendId],
      });

      // Act
      print('Acting: Fetching friend list');
      final userDoc = await firestore.collection('friend_list').doc(currentUserId).get();

      // Assert
      print('Asserting: Verifying friend is in the list');
      List<dynamic> friends = userDoc['friends'];
      expect(friends.contains(friendId), true);
    });

    // Test: Add a friend to Firestore
    test('Add a friend to Firestore', () async {
      // Arrange
      print('Arranging test: Adding a new user');
      final currentUserId = 'user1';
      final friendPhone = '123456789';
      await firestore.collection('users').doc('user2').set({
        'phoneNumber': friendPhone,
        'displayName': 'John Doe',
      });

      // Act: Simulate adding a friend
      print('Acting: Simulating adding a friend');
      final querySnapshot = await firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: friendPhone)
          .get();

      final friendId = querySnapshot.docs.first.id;

      // Update the current user's friend list
      await firestore.collection('friend_list').doc(currentUserId).set({
        'friends': [friendId],
      });

      // Assert
      print('Asserting: Verifying the friend is added');
      final currentUserDoc = await firestore.collection('friend_list').doc(currentUserId).get();
      expect(currentUserDoc.exists, true);
      expect(currentUserDoc['friends'], contains(friendId));
    });

    // Test: Filter friends based on query
    test('Filter friends list based on search query', () {
      // Arrange
      print('Arranging test: Creating a list of friends');
      final friends = [
        {'displayName': 'Alice', 'phoneNumber': '123456789'},
        {'displayName': 'Bob', 'phoneNumber': '987654321'},
        {'displayName': 'Charlie', 'phoneNumber': '555555555'},
      ];

      final query = 'Bob';

      // Act
      print('Acting: Filtering friends based on query');
      final filteredFriends = friends.where((friend) {
        final displayName = friend['displayName']?.toLowerCase() ?? '';
        final phoneNumber = friend['phoneNumber']?.toLowerCase() ?? '';
        final searchLower = query.toLowerCase();
        return displayName.contains(searchLower) || phoneNumber.contains(searchLower);
      }).toList();

      // Assert
      print('Asserting: Verifying the filtered result');
      expect(filteredFriends.length, 1);
      expect(filteredFriends.first['displayName'], 'Bob');
    });
  });
}
