`lib/customer_map2.dart`

```dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerMap2 extends StatefulWidget {
  const CustomerMap2({super.key});

  @override
  State<CustomerMap2> createState() => _CustomerMap2State();
}

class _CustomerMap2State extends State<CustomerMap2> {

  // Firestore reference instead of Realtime Database
  final DocumentReference driverRef = FirebaseFirestore.instance
      .collection('drivers')
      .doc('driver_001');

  @override
  void initState() {
    super.initState();

    // Fetch driver data from Firestore
    driverRef.get().then((snapshot) {
      print("Exists: ${snapshot.exists}");
      print("ID: ${snapshot.id}");
      print("Data: ${snapshot.data()}");
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
```
