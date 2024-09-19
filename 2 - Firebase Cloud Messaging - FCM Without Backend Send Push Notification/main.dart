import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

@pragma("vm:entry-point")
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Awesome Notifications
  AwesomeNotifications().initialize(
    'resource://drawable/launch_background', // Replace with your app icon
    [
      NotificationChannel(
        channelKey: 'basic_channel',
        channelName: 'Basic notifications',
        channelDescription: 'Notification channel for basic tests',
        defaultColor: Color(0xFF9D50DD),
        ledColor: Colors.white,
        importance: NotificationImportance.High,
        channelShowBadge: true,
      )
    ],
  );

  // Request notification permissions
  NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print("User granted permission");
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print("User granted provisional permission");
  } else {
    print("User declined or has not accepted permission");
  }

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Received a message while the app is in the foreground!');

    if (message.notification != null) {
      print('Notification Title: ${message.notification?.title}');
      print('Notification Body: ${message.notification?.body}');

      // Display notification using Awesome Notifications
      _showNotification(message.notification?.title, message.notification?.body);
    }
  });

  final fcmToken = await FirebaseMessaging.instance.getToken();
  print(fcmToken);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(MyApp(fcmToken: fcmToken ?? ''));
}

// Function to display the notification using Awesome Notifications
void _showNotification(String? title, String? body) {
  AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: 10, // Unique ID for the notification
      channelKey: 'basic_channel', // Channel key defined during initialization
      title: title ?? 'No title',
      body: body ?? 'No body',
      notificationLayout: NotificationLayout.Default, // Simple notification layout
    ),
  );
}

class MyApp extends StatelessWidget {
  final String fcmToken;

  MyApp({required this.fcmToken});

  Future<void> sendFcmToken() async {
    // Your Node.js server URL
    const String url = "http://192.168.1.111:3000/send";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(<String, String>{
          'fcmToken': fcmToken,
        }),
      );

      if (response.statusCode == 200) {
        print("Successfully sent FCM token: $fcmToken");
      } else {
        print("Failed to send FCM token: ${response.body}");
      }
    } catch (e) {
      print("Error sending FCM token: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () async {
              print("TextButton pressed");
              await sendFcmToken();
            },
            child: Text("Send FCM Token to Node.js"),
          ),
        ),
      ),
    );
  }
}
