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
      'image': 'asset/BD.jpg',
    },
    {
      'name': 'Wedding Anniversary',
      'category': 'Celebration',
      'status': 'Upcoming',
      'image': 'asset/WA.jpg',
    },
    {
      'name': 'Graduation Party',
      'category': 'Celebration',
      'status': 'Past',
      'image': 'asset/GA.jpg',
    },
    {
      'name': 'New Year’s Eve Celebration',
      'category': 'Celebration',
      'status': 'Upcoming',
      'image': 'asset/NY.jpg',
    },
  ];

  String sortCriteria = 'Name';

  // Function to show a confirmation dialog before deleting an event
  void _showDeleteConfirmationDialog(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Event', style: TextStyle(fontSize: 25,color: Colors.red,)),
          content: const Text('Are you sure you want to delete this event?', style: TextStyle(fontSize: 28,),),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog without doing anything
              },
              child: const Text('Cancel', style: TextStyle(fontSize: 25,),),
            ),
            TextButton(
              onPressed: () {
                _deleteEvent(index);
                Navigator.of(context).pop(); // Close the dialog after deletion
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red,fontSize: 25),),
            ),
          ],
        );
      },
    );
  }

  // Function to delete an event
  void _deleteEvent(int index) {
    setState(() {
      events.removeAt(index);
    });
  }

  // Function to sort events
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
            onPressed: () {
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
                const Icon(Icons.sort, color: Colors.indigo, size: 40),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: sortCriteria,
                  items: const [
                    DropdownMenuItem(value: 'Name', child: Text('Sort by Name', style: TextStyle(fontFamily: "Lobster"))),
                    DropdownMenuItem(value: 'Category', child: Text('Sort by Category', style: TextStyle(fontFamily: "Lobster"))),
                    DropdownMenuItem(value: 'Status', child: Text('Sort by Status', style: TextStyle(fontFamily: "Lobster"))),
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
            const SizedBox(height: 10),
            events.isEmpty
                ? const Center(child: Text('No events created yet.'))
                : Expanded(
              child: ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    elevation: 4.0,
                    margin: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Column(
                      children: [
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(15.0)),
                            image: DecorationImage(
                              image: event['image'] != null && event['image']!.isNotEmpty
                                  ? AssetImage(event['image']!)
                                  : const AssetImage('asset/placeholder.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: event['image'] != null && event['image']!.isNotEmpty
                              ? null
                              : const Icon(
                            Icons.image_not_supported,
                            size: 50,
                            color: Colors.red,
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.indigo, size: 40),
                              onPressed: () {
                                Navigator.pushNamed(context, '/EventDetailsPage');
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 40),
                              onPressed: () => _showDeleteConfirmationDialog(index),
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
