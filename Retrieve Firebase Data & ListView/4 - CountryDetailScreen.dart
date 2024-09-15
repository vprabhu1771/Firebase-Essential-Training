import 'package:flutter/material.dart';

// Import the Country model
import '../../models/Country.dart';


class CountryDetailScreen extends StatelessWidget {
  final Country country; // Accept a Country model instance

  const CountryDetailScreen({super.key, required this.country});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(country.name), // Use the name from the Country model
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Document ID: ${country.documentId}', // Display document ID
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 16),
            Text(
              'Country: ${country.name}', // Display country name
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),                    
            // Add more fields here if needed
          ],
        ),
      ),
    );
  }
}
