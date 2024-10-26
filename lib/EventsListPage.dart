import 'package:flutter/material.dart';

class EventsListPage extends StatefulWidget {
  const EventsListPage({super.key});

  @override
  State<EventsListPage> createState() => _EventsListPageState();
}

class _EventsListPageState extends State<EventsListPage> {
  List<Map<String, String?>> events = [
    {
      'name': 'Birthday Party',
      'category': 'Celebration',
      'status': 'Upcoming',
      'image': 'asset/BD.jpg', // Example image path
    },
    {
      'name': 'Wedding Anniversary',
      'category': 'Celebration',
      'status': 'Upcoming',
      'image': 'asset/WA.jpg', // Example image path
    },
    {
      'name': 'Graduation Party',
      'category': 'Celebration',
      'status': 'Past',
      'image': 'asset/GA.jpg', // Example image path
    },
    {
      'name': 'New Year’s Eve Celebration',
      'category': 'Celebration',
      'status': 'Upcoming',
      'image': 'asset/NY.jpg', // Example image path
    },
  ];

  String sortCriteria = 'Name'; // Default sorting criteria

  // Function to show the dialog for adding a new event


  // Function to show the dialog for editing an event
  void _editEvent(int index) {
    String name = events[index]['name'] ?? '';
    String category = events[index]['category'] ?? '';
    String status = events[index]['status'] ?? '';
    String imagePath = events[index]['image'] ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Event'),
          content: _eventDialogContent(name, category, status, imagePath, (newName, newCategory, newStatus, newImagePath) {
            setState(() {
              events[index] = {
                'name': newName,
                'category': newCategory,
                'status': newStatus,
                'image': newImagePath,
              };
            });
          }),
        );
      },
    );
  }

  // Function to provide the dialog content for both add and edit
  Widget _eventDialogContent(String name, String category, String status, String imagePath, Function(String, String, String, String) onSubmit) {
    String tempName = name;
    String tempCategory = category;
    String tempStatus = status;
    String tempImagePath = imagePath;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          decoration: const InputDecoration(labelText: 'Event Name'),
          onChanged: (value) {
            tempName = value;
          },
          controller: TextEditingController(text: name),
        ),
        TextField(
          decoration: const InputDecoration(labelText: 'Category'),
          onChanged: (value) {
            tempCategory = value;
          },
          controller: TextEditingController(text: category),
        ),
        TextField(
          decoration: const InputDecoration(labelText: 'Image Path'),
          onChanged: (value) {
            tempImagePath = value;
          },
          controller: TextEditingController(text: imagePath),
        ),
        DropdownButton<String>(
          value: tempStatus,
          items: const [
            DropdownMenuItem(value: 'Upcoming', child: Text('Upcoming')),
            DropdownMenuItem(value: 'Current', child: Text('Current')),
            DropdownMenuItem(value: 'Past', child: Text('Past')),
          ],
          onChanged: (value) {
            setState(() {
              if (value != null) {
                tempStatus = value;
              }
            });
          },
        ),
      ],
    );
  }

  // Function to delete an event
  void _deleteEvent(int index) {
    setState(() {
      events.removeAt(index);
    });
  }

  void _sortEvents() {
    switch (sortCriteria) {
      case 'Name':
        events.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
        break;
      case 'Category':
        events.sort((a, b) => (a['category'] ?? '').compareTo(b['category'] ?? ''));
        break;
      case 'Status':
        events.sort((a, b) => (a['status'] ?? '').compareTo(b['status'] ?? ''));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    _sortEvents(); // Sort events whenever the build method is called

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.indigo),
        backgroundColor: Colors.indigo.shade50,
        title: const Row(
          children: [
            Text(
              "Hedieaty",
              style: TextStyle(
                fontSize: 40,
                fontFamily: "Lobster",
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            Icon(Icons.card_giftcard, color: Colors.indigo, size: 25),
          ],
        ),
        titleSpacing: 69.0,
        toolbarHeight: 70,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: (){
              Navigator.pushNamed(context, '/AddEvent');
          },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Dropdown for sorting criteria
            Row(
              children: [
                const Icon(Icons.sort, color: Colors.indigo,size: 40,), // Sort icon
                const SizedBox(width: 8), // Space between icon and dropdown
                DropdownButton<String>(
                  value: sortCriteria,
                  items: const [
                    DropdownMenuItem(value: 'Name', child: Text('Sort by Name',style: TextStyle(fontFamily: "Lobster"),)),
                    DropdownMenuItem(value: 'Category', child: Text('Sort by Category',style: TextStyle(fontFamily: "Lobster"),)),
                    DropdownMenuItem(value: 'Status', child: Text('Sort by Status',style: TextStyle(fontFamily: "Lobster"),)),
                  ],
                  onChanged: (value) {
                    setState(() {
                      if (value != null) {
                        sortCriteria = value;
                      }
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 10), // Space between dropdown and list
            events.isEmpty
                ? const Center(child: Text('No events created yet.'))
                : Expanded(
              child: ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0), // Make the corners curved
                    ),
                    elevation: 4.0,
                    margin: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Column(
                      children: [
                        // Image section taking full height
                        Container(
                          height: 200, // Set a fixed height for the image
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(15.0)), // Curved top corners
                            image: DecorationImage(
                              image: event['image'] != null && event['image']!.isNotEmpty
                                  ? AssetImage(event['image']!)
                                  : const AssetImage('asset/placeholder.png'), // Placeholder image
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: event['image'] != null && event['image']!.isNotEmpty
                              ? null // Show the image as background
                              : const Icon(
                            Icons.image_not_supported,
                            size: 50,
                            color: Colors.red, // Color for the icon
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event['name'] ?? 'Unnamed Event',
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontFamily: "Lobster",
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              Text(
                                "Category: ${event['category'] ?? 'Uncategorized'}",
                                style: const TextStyle(fontSize: 20),
                              ),
                              Text(
                                "Status: ${event['status'] ?? 'Unknown'}",
                                style: const TextStyle(fontSize: 20),
                              ),
                            ],
                          ),
                        ),
                        // Add action buttons for edit and delete using IconButton
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.indigo, size: 40),
                              onPressed: () {

                                Navigator.pushNamed(context, '/EventDetailsPage');}
                              ,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 40),
                              onPressed: () => _deleteEvent(index),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
