# Show FCM Foreground Message as a SnackBar

Since FCM doesn't automatically display notifications when the app is in the foreground, you can show a `SnackBar` instead. The tricky part is that `FirebaseMessaging.onMessage` is a stream that lives outside the widget tree, so you need a **global `ScaffoldMessengerKey`**.

---

## 1. Create a global key

Create a file like `lib/globals.dart` (or anywhere convenient):

```dart
import 'package:flutter/material.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
```

---

## 2. Wire it up in `main.dart`

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'globals.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Foreground message handler
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('Foreground message: ${message.notification?.title}');

    final title = message.notification?.title ?? 'New message';
    final body  = message.notification?.body  ?? '';

    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty)
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (body.isNotEmpty) Text(body),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            // Navigate or handle tap
            debugPrint('SnackBar action tapped: ${message.data}');
          },
        ),
      ),
    );
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FCM SnackBar Demo',
      scaffoldMessengerKey: scaffoldMessengerKey, // <-- attach here
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Waiting for foreground messages...')),
    );
  }
}
```

---

## 3. Test it

Send a test message from the **Firebase Console → Messaging → Send test message**, targeting your device's FCM token. While your app is open, you'll see the SnackBar.

Or send via REST:

```bash
curl -X POST https://fcm.googleapis.com/v1/projects/YOUR_PROJECT/messages:send \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "token": "DEVICE_FCM_TOKEN",
      "notification": {
        "title": "Hello",
        "body": "This is a foreground test"
      }
    }
  }'
```

---

## Key points

| Point | Why it matters |
|---|---|
| **`scaffoldMessengerKey` on `MaterialApp`** | `FirebaseMessaging.onMessage` has no `BuildContext`, so a global key is required. |
| **`ScaffoldMessenger` vs `Scaffold.of`** | Using the global messenger key means the SnackBar works from anywhere — even outside the widget tree. |
| **`behavior: SnackBarBehavior.floating`** | Looks nicer over content; drop it if you prefer the default docked style. |
| **`message.data` for action** | If you want to navigate on tap, pass `message.data` (a `Map<String, dynamic>`) into your action handler. |
| **Null safety** | `message.notification` can be `null` for **data-only** messages — always check. |

---

## Bonus: Navigate on SnackBar action

If you want to route to a specific screen when the user taps **View**, use a global `navigatorKey` too:

```dart
// globals.dart
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// main.dart MaterialApp
MaterialApp(
  navigatorKey: navigatorKey,
  scaffoldMessengerKey: scaffoldMessengerKey,
  ...
)

// in the SnackBar action
onPressed: () {
  final route = message.data['route'];
  if (route != null) navigatorKey.currentState?.pushNamed(route);
},
```

That's it — foreground FCM messages will now show as SnackBars without needing `flutter_local_notifications`. 👍
