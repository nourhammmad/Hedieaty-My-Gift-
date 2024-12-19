import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projecttrial/main.dart'; // Make sure to import the correct entry point
import 'package:firebase_core/firebase_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test Create A Gift', (tester) async {
    // Step 1: Launch the app
    await tester.pumpWidget(MyApp());
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();

    // Step 2: Login Process
    final usernameField = find.byKey(Key('usernameField'));
    final passwordField = find.byKey(Key('passwordField'));
    final loginButton = find.byKey(Key('loginButton'));

    // Ensure the login fields and button are present
    expect(usernameField, findsOneWidget);
    expect(passwordField, findsOneWidget);
    expect(loginButton, findsOneWidget);

    // Simulate user entering credentials and logging in
    await tester.enterText(usernameField, 'b@b.com');
    await tester.enterText(passwordField, '123456');
    await tester.tap(loginButton);
    await tester.pumpAndSettle(const Duration(seconds: 5));  // Additional waiting time (optional)

    // // Step 3: Ensure the HomePage has finished loading
    // await tester.pumpAndSettle(); // Wait for any async tasks (data fetching, etc.) to complete
    print("Home page should be loaded now");
    //
    final friendTile = find.byKey(Key('Nina Yea'));

    // Step 2: Verify that Nour Hammad is present in the widget tree
    expect(friendTile, findsOneWidget);

    // Step 3: Tap on the friend tile
    await tester.tap(friendTile);

    // Step 4: Wait for navigation to complete
    await tester.pumpAndSettle(const Duration(seconds: 3));
    // // Check if the HomePage widget is rendered
    final myEventTile = find.byKey(Key('My Birthday'));  // Find the first event tile by key
    await tester.tap(myEventTile);  // Tap on the "Test Event 1"
    await tester.pumpAndSettle(const Duration(seconds: 3));
    final myGiftTile = find.byKey(Key('D&G'));  // Find the first event tile by key
    await tester.tap(myGiftTile);  // Tap on the "Test Event 1"
    await tester.pumpAndSettle(const Duration(seconds: 10));//

  });
}