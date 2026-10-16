# Flutter Firebase Cloud Messaging (iOS) Using APNs authentication key (.p8) | iOS Push Notification
```
https://www.youtube.com/watch?v=Gu68mmYmpzw
```

`pubspec.yaml`
```
firebase_core: ^4.5.0
firebase_messaging: ^16.1.2
```

`ios/Podfile`
```
# Uncomment this line to define a global platform for your project
# platform :ios, '15.0'
platform :ios, '15.0'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure flutter pub get is executed first"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}. Try deleting Generated.xcconfig, then run flutter pub get"
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

pod 'GoogleMaps'

target 'Runner' do
  use_frameworks!

  # Change this line to enforce static linkage for Firebase compatibility
  use_frameworks! :linkage => :static

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  target 'RunnerTests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
  end
end
```

`main.dart`
```
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:untitled/HomeScreen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  // Request notification permission (esp. required on iOS & Android 13+)
  await FirebaseMessaging.instance.requestPermission();

  // Foreground message handler
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('Foreground message: ${message.notification?.title}');
    // Show a SnackBar / dialog / local notification here
  });

  // Background tap handler (app was in background, user tapped notification)
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('Notification tapped: ${message.data}');
    // Navigate to a specific screen based on message.data
  });

  // Check if app was launched from a terminated state via a notification
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    debugPrint('App launched from notification: ${initialMessage.data}');
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Fetch the FCM token as soon as the app starts
    _setupFcmToken();
  }

  Future<void> _setupFcmToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      debugPrint('🚀 FCM Token Generated successfully: $token');
      // TODO: Send this token to your backend server database here
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
```

`HomeScreen.dart`
```
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Home"),
        backgroundColor: Colors.amber,
      ),
      body: Center(
        child: Text("Home"),
      ),
    );
  }
}
```
