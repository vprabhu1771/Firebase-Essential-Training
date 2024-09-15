import 'package:cloud_firestore/cloud_firestore.dart';

class Country {
  final String documentId;
  final String name;

  Country({
    required this.documentId,
    required this.name,
  });

  // Factory constructor to create a Country object from Firestore document data
  factory Country.fromDocumentSnapshot(DocumentSnapshot doc) {
    return Country(
      documentId: doc.id, // Get the document ID
      name: doc['name'] ?? 'Unknown', // Get the name from document or use 'Unknown'
    );
  }
}
