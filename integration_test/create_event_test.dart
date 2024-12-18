import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projecttrial/main.dart'; // Make sure to import the correct entry point
import 'package:firebase_core/firebase_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test navigation flow: Login -> Home -> GiftOrEvent -> AddEvent', (tester) async {
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
    final addEventButton = find.byKey(Key('addEventButton'));
    expect(addEventButton, findsOneWidget); // Ensure the button is present
    await tester.tap(addEventButton);
    await tester.pumpAndSettle(); // Wait for navigation to AddEvent Page

    // Step 7: Verify AddEvent Page is displayed
    expect(find.byKey(Key('addEventPage')), findsOneWidget);
    // Step 7: Fill out the AddEvent Form
    final titleField = find.byKey(Key('titleField'));
    final descriptionField = find.byKey(Key('descriptionField'));
    final dateField = find.byKey(Key('dueDateField'));  // For picking a due date
    final saveButton = find.byKey(Key('saveButton'));

    // Ensure form fields and save button are present
    expect(titleField, findsOneWidget);
    expect(descriptionField, findsOneWidget);
    expect(dateField, findsOneWidget);
    expect(saveButton, findsOneWidget);

    // Simulate filling out the fields
    await tester.enterText(titleField, 'Test Event');
    await tester.enterText(descriptionField, 'This is a test event description.');
    await tester.tap(dateField);
    await tester.pumpAndSettle();  // Wait for the date picker to appear

    // Simulate selecting a date (you can adjust this based on your date picker implementation)
    await tester.tap(find.text('31')); // Select a day in the date picker
    await tester.tap(find.text('OK')); // Adjust the text if necessary

    await tester.pumpAndSettle();  // Wait for date picker to close

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
    await tester.pumpAndSettle(const Duration(seconds: 10));  // Wait for back navigation to complete

  });
}