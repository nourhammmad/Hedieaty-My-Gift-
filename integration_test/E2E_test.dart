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
    await tester.pumpAndSettle(const Duration(seconds: 10)); // Wait for navigation to GiftOrEvent Page

    // Step 5: Verify GiftOrEvent Page is displayed

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
    await tester.enterText(titleField, 'A Test Event');
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
     await tester.pumpAndSettle(const Duration(seconds: 5));  // Wait for back navigation to complete

    // Step 10: Verify that we navigated back correctly
    // Example: Verify that we are back on the GiftOrEvent page

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
    final testEventItem = find.text('A Test Event').first;  // Assumes "Test Event" is the text of the item
    await tester.tap(testEventItem);
    await tester.pumpAndSettle();

    final titleFieldG = find.byKey(Key('titleField'));
    final descriptionFieldG = find.byKey(Key('descriptionField'));
    final Category = find.byKey(Key('Category'));  // For picking a due date
    final price = find.byKey(Key('Price'));  // For picking a due date
    final saveButtonG = find.byKey(Key('saveButton'));

    // Ensure form fields and save button are present
    expect(titleFieldG, findsOneWidget);
    expect(descriptionFieldG, findsOneWidget);
    expect(Category, findsOneWidget);
    expect(saveButtonG, findsOneWidget);

    // Simulate filling out the fields
    await tester.enterText(titleFieldG, 'Test Gift');
    await tester.enterText(descriptionFieldG, 'This is a test gift description.');
    await tester.enterText(Category,'TEMP CATEGORY');
    await tester.enterText(price,'500');

    // Step 8: Submit the form to add the event
    await tester.tap(saveButtonG);
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
    final myEventTile = find.byKey(Key('A Test Event'));  // Find the first event tile by key
    await tester.tap(myEventTile);  // Tap on the "Test Event 1"
    await tester.pumpAndSettle(const Duration(seconds: 5));  // Wait for navigation to complete
    await tester.pageBack();
    await tester.pumpAndSettle(const Duration(seconds: 3));  // Wait for navigation to complete
    await tester.pageBack();
    await tester.pumpAndSettle(const Duration(seconds: 3));  // Wait for navigation to complete
    expect(drawerIcon, findsOneWidget); // Ensure drawer icon is present

    await tester.tap(drawerIcon); // Tap on the drawer icon (hamburger menu)
    await tester.pumpAndSettle(); // Wait for the drawer to open

    // Step 4: Tap on "My Events" in the Drawer
    final logout =find.byKey(Key('logout')); // Finds the text "My Events"
    expect(logout, findsOneWidget); // Ensure the "My Events" ListTile is present

    await tester.tap(logout); // Tap on the "My Events" option
    await tester.pumpAndSettle(const Duration(seconds: 3));
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
    final testevent = find.byKey(Key('A Test Event'));  // Find the first event tile by key
    await tester.tap(testevent);  // Tap on the "Test Event 1"
    await tester.pumpAndSettle(const Duration(seconds: 3));
    final myGiftTile = find.byKey(Key('Test Gift'));  // Find the first event tile by key
    await tester.tap(myGiftTile);  // Tap on the "Test Event 1"
    await tester.pumpAndSettle(const Duration(seconds: 10));//

  });
 }