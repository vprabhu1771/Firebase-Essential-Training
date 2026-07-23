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

`main.dart`

```dart
import 'package:customer_app/customer_map2.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'customer_map.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      // home: CustomerMap(),
      home: CustomerMap2(),
    ),
  );
}
```

```
I/flutter (14698): Exists: true
I/flutter (14698): ID: driver_001
I/flutter (14698): Data: {updated_at: 1721632100, heading: 170, latitude: 11.7442, speed: 34, status: online, longitude: 79.7681}
```
