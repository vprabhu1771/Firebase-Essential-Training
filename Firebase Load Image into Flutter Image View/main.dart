import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_kkchating/screens/CountryScreen.dart';
import 'package:flutter_kkchating/screens/HomeScreen.dart';
import 'package:flutter_kkchating/screens/RegisterScreen.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart'; // OneSignal import
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/LoginScreen.dart';
import 'services/auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

  //Remove this method to stop OneSignal Debugging
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

  // Initialize OneSignal
  OneSignal.initialize("4712d81e-1986-4a47-9dba-40f060b0d26b");

  // The promptForPushNotificationsWithUserResponse function will show the iOS or Android push notification prompt. We recommend removing the following code and instead using an In-App Message to prompt for notification permission
  OneSignal.Notifications.requestPermission(true);

  runApp(ChatApp());
}

class ChatApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => Auth()), // Provide Auth service
      ],
      child: MaterialApp(
        title: 'Flutter Chat App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        initialRoute: '/', // Define the initial route
        routes: {
          '/login': (context) => LoginScreen(title: 'Login'),
          '/country': (context) => CountryScreen(),
          '/': (context) => HomeScreen(),
          '/register': (context) => RegisterScreen(title: 'Register'),// Define the login route
        },
        debugShowCheckedModeBanner: false, // Remove the debug banner
      ),
    );
  }
}
