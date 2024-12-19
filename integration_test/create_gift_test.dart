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
    await tester.enterText(usernameField, 'n@n.com');
    await tester.enterText(passwordField, '123456');
    await tester.tap(loginButton);
    await tester.pumpAndSettle(const Duration(seconds: 5));  // Additional waiting time (optional)

    // // Step 3: Ensure the HomePage has finished loading
    // await tester.pumpAndSettle(); // Wait for any async tasks (data fetching, etc.) to complete
    print("Home page should be loaded now");
    //
    // // Check if the HomePage widget is rendered

    // Step 4: Navigate to GiftOrEvent Page by tapping the Create Event Button
    final createEventButton = find.byKey(Key('createEventButton'));
    expect(createEventButton, findsOneWidget); // Ensure the button is present
    await tester.tap(createEventButton);
    await tester.pumpAndSettle(); // Wait for navigation to GiftOrEvent Page

    // Step 5: Verify GiftOrEvent Page is displayed
    expect(find.byKey(Key('GiftOrEvent')), findsOneWidget);

    // Step 6: Navigate to AddEvent Page by tapping the Add Event Button
    final addGiftButton = find.byKey(Key('addGiftButton'));
    expect(addGiftButton, findsOneWidget); // Ensure the button is present
    await tester.tap(addGiftButton);
    await tester.pumpAndSettle(); // Wait for navigation to AddEvent Page

    // Step 7: Verify AddEvent Page is displayed
    expect(find.byKey(Key('addGiftPage')), findsOneWidget);
    // Step 7: Fill out the AddEvent Form
    // Tap on the dropdown to open the options
    final dropdown = find.byKey(Key('eventDropdown'));

// Ensure the dropdown is present
    expect(dropdown, findsOneWidget);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();  // Wait for dropdown options to appear

// Select an option (for example, selecting the first event)
    final testEventItem = find.text('Test Event').first;  // Assumes "Test Event" is the text of the item
    await tester.tap(testEventItem);
    await tester.pumpAndSettle();

    final titleField = find.byKey(Key('titleField'));
    final descriptionField = find.byKey(Key('descriptionField'));
    final Category = find.byKey(Key('Category'));  // For picking a due date
    final price = find.byKey(Key('Price'));  // For picking a due date
    final saveButton = find.byKey(Key('saveButton'));

    // Ensure form fields and save button are present
    expect(titleField, findsOneWidget);
    expect(descriptionField, findsOneWidget);
    expect(Category, findsOneWidget);
    expect(saveButton, findsOneWidget);

    // Simulate filling out the fields
    await tester.enterText(titleField, 'Test Gift');
    await tester.enterText(descriptionField, 'This is a test gift description.');
    await tester.enterText(Category,'TEMP CATEGORY');
    await tester.enterText(price,'500');

    // Step 8: Submit the form to add the event
    await tester.tap(saveButton);
    await tester.pumpAndSettle();  // Wait for the event to be saved

// Step 9: Simulate pressing the back action (this could be tapping a back button in the UI)
    // Assuming this is a MaterialApp or Navigator
    await tester.pageBack();
    await tester.pumpAndSettle(const Duration(seconds: 5));  // Wait for back navigation to complete

    // Step 10: Verify that we navigated back correctly
    // Example: Verify that we are back on the GiftOrEvent page
    final drawerIcon = find.byKey(Key('Drawer'));// Default tooltip for Drawer icon
    expect(drawerIcon, findsOneWidget); // Ensure drawer icon is present

    await tester.tap(drawerIcon); // Tap on the drawer icon (hamburger menu)
    await tester.pumpAndSettle(); // Wait for the drawer to open

    // Step 4: Tap on "My Events" in the Drawer
    final myEventsTile =find.byKey(Key('My Events')); // Finds the text "My Events"
    expect(myEventsTile, findsOneWidget); // Ensure the "My Events" ListTile is present

    await tester.tap(myEventsTile); // Tap on the "My Events" option
    await tester.pumpAndSettle(); // Wait for navigation to EventsListPage

    // Step 5: Verify navigation to EventsListPage
    expect(find.byKey(Key('eventsListPage')), findsOneWidget); // Verify EventsListPage is displayed
    await tester.pumpAndSettle(const Duration(seconds: 5));  // Wait for back navigation to complete
// // Step 1: Tap on the first event in the list
//     final myEventTile = find.byKey(Key('DXuULHI8MIb95X5TtYLJ'));  // Find the first event tile by key
//     await tester.tap(myEventTile);  // Tap on the "Test Event 1"
//     await tester.pumpAndSettle(const Duration(seconds: 5));  // Wait for navigation to complete

  });
}