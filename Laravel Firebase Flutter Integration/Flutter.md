`main.dart`
```
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_small_shop/screens/RegisterScreen.dart';
import 'package:firebase_small_shop/services/AuthProvider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';

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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MyApp(),
    ),
  );
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


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // home: Scaffold(
      //   body: Center(
      //     child: TextButton(
      //       onPressed: () async {
      //         print("TextButton pressed");
      //         await sendFcmToken();
      //       },
      //       child: Text("Send FCM Token to Node.js"),
      //     ),
      //   ),
      // ),
      home: RegisterScreen(title: 'Register')
    );
  }
}
```

`Constants.dart`
```
class Constants {

  static const String SERVER_DOMAIN= "http://192.168.1.98:8000";

  static const String BASE_URL = SERVER_DOMAIN + "/api";

  static const String LOGIN_ROUTE = "/login";

  static const String LOGOUT_ROUTE = "/logout";

  static const String USER_ROUTE = "/user";

  static const String REGISTER_ROUTE = "/register";

  static const String SAVE_PLAYER_ID_ROUTE = "/save-player-id";

  static const String SEND_NOTIFICATION_ROUTE = "/send-notification";

}
```

`AuthProvider.dart`
```
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'package:dio/dio.dart' as Dio;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';



import '../models/User.dart';

import 'package:http/http.dart' as http;

import '../utils/Constants.dart';
import 'dio.dart';

class AuthProvider extends ChangeNotifier {

  bool _isLoggedIn = false;

  User? _user;

  String? _token;

  bool get authenticated => _isLoggedIn;

  User? get user => _user;

  // Flutter Secure Storage
  // Create storage
  final storage = new FlutterSecureStorage();

  void login({required Map creds}) async {
    print(creds);

    try {

      Dio.Response response = await dio().post(Constants.BASE_URL + Constants.LOGIN_ROUTE, data: creds);

      print(response.data);

      String token = response.data.toString();

      this.tryToken(token: token);

      _isLoggedIn = true;
      notifyListeners();

    } catch (e) {
      print('Login Error: $e ${Constants.BASE_URL}${Constants.LOGIN_ROUTE}');
      // Handle the error appropriately (show a message, etc.)
    }
  }

  void tryToken({required String token}) async {

    if(token == null) {
      return;
    }
    else {

      try {

        Dio.Response response = await dio().get(
            Constants.BASE_URL + Constants.USER_ROUTE,
            options: Dio.Options(headers: {'Authorization' : 'Bearer $token'})
        );

        _isLoggedIn = true;

        this._user = User.fromJson(response.data);

        this._token = token;

        this.storeToken(token: token);

        notifyListeners();

        print(this._user);


      } catch (e) {

      }


    }

  }

  void storeToken({required String token}) async {

    this.storage.write(key: 'token', value: token);

  }

  void logout() async {

    dynamic token = await this.storage.read(key: 'token');

    try {
      print('logout started');

      Dio.Response response = await dio().get(
          Constants.BASE_URL + Constants.LOGOUT_ROUTE,
          options: Dio.Options(headers: {'Authorization' : 'Bearer $token'})
      );

      print(response.data);

      cleanUp();
      notifyListeners();

      print('logout ended');

    }
    catch (e) {
      print(e);
    }

    notifyListeners();
  }

  void cleanUp() async {

    this._user = null;
    this._isLoggedIn = false;
    this._token = null;

    await storage.delete(key: 'token');

  }

  Future<void> registerUser({
    required Map creds
  }) async {

    try {

      final response = await http.post(
        Uri.parse(Constants.BASE_URL + Constants.REGISTER_ROUTE),
        body: creds,
      );

      if (response.statusCode == 201) {

        // Registration successful

        Map<String, dynamic> responseData = json.decode(response.body);

        print('User registered successfully: ${responseData['user']['name']}');

        // You can handle the successful registration response here
        String? token = await FirebaseMessaging.instance.getToken();
        print("Player ID: $token");

        final playerIdResponse = await http.post(
          Uri.parse(Constants.BASE_URL + Constants.SAVE_PLAYER_ID_ROUTE),
          headers: {
            'Authorization': 'Bearer ${responseData['token']}',
          },
          body: {
            'player_id': token,
            'user_id': responseData['user']['id'].toString(),
          },
        );

        final registerNotificationResponse = await http.post(
          Uri.parse(Constants.BASE_URL + Constants.SEND_NOTIFICATION_ROUTE),
          body: {
            "title": "Hello from Laravel",
            "body": "This is a Firebase notification test",
            // "player_id": "fcm_or_onesignal_token_here"
            "player_id": token
          },
        );

        print(registerNotificationResponse.statusCode);

        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          print('Received notification: ${message.notification?.title}');
        });

      }
      else
      {
        // Registration failed
        print('Registration failed: ${Constants.BASE_URL} ${Constants.REGISTER_ROUTE} ${response.toString()} ${response.body}');
        // You can handle the registration failure here
      }

    } catch (e)
    {
      print('Error during registration: $e');
      // Handle network errors or other exceptions here
    }

    await Future.delayed(Duration(seconds: 2));

    // Notify listeners that authentication state has changed
    notifyListeners();
  }
}
```

`RegisterScreen.dart`
```
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/AuthProvider.dart';

class RegisterScreen extends StatefulWidget {
  final String title;
  const RegisterScreen({super.key, required this.title});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  // Get Device Info
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  String _deviceName = '';

  void getDeviceName() async {

    try {

      if(Platform.isAndroid)
      {

        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

        // e.g. "Moto G (4)"
        _deviceName = androidInfo.model;

      }
      else if(Platform.isIOS)
      {

        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;

        // e.g. "iPod7,1"
        _deviceName = iosInfo.utsname.machine;

      }

    }
    catch (e) {

    }

  }

  @override
  void initState() {

    getDeviceName();

    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AuthProvider authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Register'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  // You can add more email validation logic if needed
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  // You can add more password validation logic if needed
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {

                  Map creds = {
                    'name' : _nameController.text,
                    'email' : _emailController.text,
                    'password' : _passwordController.text,
                    'device_name' : _deviceName ?? 'unknown'
                  };

                  if (_formKey.currentState?.validate() ?? false) {

                    // authProvider.registerUser(
                    //   name: _nameController.text,
                    //   email: _emailController.text,
                    //   password: _passwordController.text,
                    // );

                    Provider.of<AuthProvider>(context, listen: false).registerUser(creds: creds);
                    // Provider.of<AuthProvider>(context, listen: false).login(creds: creds);
                    // print(creds.toString());

                    // Navigator.pop(context);
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (context) => LoginScreen(title: 'Login',),
                    //   ),
                    // );

                  }

                },
                child: Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```
