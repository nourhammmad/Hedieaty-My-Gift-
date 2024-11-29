import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

Future<String?> getPhotoURL(String userId) async {
  try {
    // Fetch the document for the specific user using the userId
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('users') // Replace with your collection name
        .doc(userId) // The document ID is the userId
        .get();

    if (snapshot.exists) {
      return snapshot['photoURL']; // Return the photo URL from the document field
    } else {
      throw Exception('Document does not exist');
    }
  } catch (e) {
    throw Exception('Error fetching photo URL: $e');
  }
}
Future<String> uploadImageToImgur(String imagePath) async {
  final String clientId = 'f9d1ca87570ca34'; // Replace with your Client ID
  final Uri url = Uri.parse('https://api.imgur.com/3/image');
  final imageBytes = File(imagePath).readAsBytesSync();
  final base64Image = base64Encode(imageBytes);

  try {
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Client-ID $clientId',
      },
      body: {
        'image': base64Image,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']['link']; // Image URL
    } else {
      throw Exception('Failed to upload image. Status code: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error uploading image: $e');
  }
}
