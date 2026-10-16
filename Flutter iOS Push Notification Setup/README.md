# Getting the FCM Token (APNs Token on iOS)

First, a quick clarification: **APNs token** is the Apple Push Notification service token — it's **iOS-only**. On Android, the equivalent is the **FCM registration token**. In Flutter, `FirebaseMessaging.instance.getToken()` returns the **FCM token** on both platforms, and on iOS, FCM internally uses the APNs token under the hood.

If you specifically need the **raw APNs token** (e.g., for a native iOS push provider), you use `getAPNSToken()`.

---

## 1. Get FCM Token (cross-platform — this is what you usually need)

```dart
Future<String?> getFcmToken() async {
  try {
    final token = await FirebaseMessaging.instance.getToken();
    debugPrint('FCM Token: $token');
    return token;
  } catch (e) {
    debugPrint('Error getting FCM token: $e');
    return null;
  }
}
```

### ⚠️ iOS Caveat
On iOS, `getToken()` may return `null` if the APNs token isn't ready yet. The APNs token is delivered asynchronously after the OS registers with APNs. You must wait for it.

---

## 2. Get Raw APNs Token (iOS only)

```dart
import 'dart:io' show Platform;

Future<String?> getApnsToken() async {
  if (!Platform.isIOS) return null;

  try {
    // Wait until APNs token is available
    String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();

    // Retry a few times if null (registration is async)
    int retries = 0;
    while (apnsToken == null && retries < 10) {
      await Future.delayed(const Duration(milliseconds: 500));
      apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      retries++;
    }

    debugPrint('APNs Token: $apnsToken');
    return apnsToken;
  } catch (e) {
    debugPrint('Error getting APNs token: $e');
    return null;
  }
}
```

---

## 3. Robust Approach — Listen for Token Refresh + Handle Null APNs

This is the production-ready version:

```dart
class PushTokenService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> init() async {
    // 1. Request permission first (required on iOS & Android 13+)
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      debugPrint('User denied notification permission');
      return;
    }

    // 2. iOS: wait for APNs token before requesting FCM token
    if (Platform.isIOS) {
      await _waitForApnsToken();
    }

    // 3. Get FCM token
    final fcmToken = await _fcm.getToken();
    debugPrint('FCM Token: $fcmToken');
    if (fcmToken != null) {
      await _sendTokenToServer(fcmToken);
    }

    // 4. Listen for token refresh
    _fcm.onTokenRefresh.listen((newToken) {
      debugPrint('FCM Token refreshed: $newToken');
      _sendTokenToServer(newToken);
    });
  }

  Future<void> _waitForApnsToken() async {
    String? apns = await _fcm.getAPNSToken();
    int attempts = 0;
    while (apns == null && attempts < 20) {
      await Future.delayed(const Duration(milliseconds: 300));
      apns = await _fcm.getAPNSToken();
      attempts++;
    }
    debugPrint('APNs Token ready: $apns');
  }

  Future<void> _sendTokenToServer(String token) async {
    // POST token to your backend here
    // e.g. await http.post(Uri.parse('https://api.example.com/device'),
    //   body: jsonEncode({'token': token, 'platform': Platform.operatingSystem}));
  }
}
```

Then in `main()`:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await PushTokenService().init();

  // ... your onMessage listeners
  runApp(const MyApp());
}
```

---

## 4. iOS Native Requirements

For `getAPNSToken()` to work on iOS, you **must**:

1. Enable **Push Notifications** capability in Xcode
2. Enable **Background Modes → Remote notifications**
3. Upload your **APNs Auth Key (.p8)** to Firebase Console → Project Settings → Cloud Messaging
4. Test on a **real device** — APNs tokens don't work on the iOS Simulator (older Xcode; newer Xcode 14+ simulators can get tokens with Apple Silicon Macs, but real device is safest)

Also, add to `ios/Runner/AppDelegate.swift`:

```swift
import UIKit
import Flutter
import Firebase

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    // For iOS 10+ display of notifications when app is in foreground
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

---

## Quick Summary Table

| Goal | Method | Platform |
|------|--------|----------|
| FCM token (send push via Firebase) | `getToken()` | Both |
| Raw APNs token | `getAPNSToken()` | iOS only |
| Detect token refresh | `onTokenRefresh` stream | Both |
| Delete token on logout | `deleteToken()` | Both |

**99% of the time you want the FCM token (`getToken()`), not the raw APNs token** — because you'll send notifications via Firebase Cloud Messaging, which handles APNs internally. Only fetch the APNs token directly if you're integrating with a non-Firebase push backend on iOS.


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
