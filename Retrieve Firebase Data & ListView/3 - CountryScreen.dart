import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import the Country model
import '../../models/Country.dart';

// Import the detail screen
import 'CountryDetailScreen.dart';

class CountryScreen extends StatefulWidget {
  const CountryScreen({super.key});

  @override
  State<CountryScreen> createState() => _CountryScreenState();
}

class _CountryScreenState extends State<CountryScreen> {
  final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('country');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Firestore ListView')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _usersCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final List<DocumentSnapshot> documents = snapshot.data?.docs ?? [];

          // Convert documents to Country model instances
          final List<Country> countries = documents.map((doc) => Country.fromDocumentSnapshot(doc)).toList();

          return ListView.builder(
            itemCount: countries.length,
            itemBuilder: (context, index) {
              final Country country = countries[index];

              return ListTile(
                title: Text(country.name), // Use the name from the Country model
                onTap: () {
                  // Pass the Country model instance to the CountryDetailScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CountryDetailScreen(country: country),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
