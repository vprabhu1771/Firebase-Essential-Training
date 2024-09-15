




You need to use the following plugin:

dependencies:
  firebase_auth: ^0.15.3
  cloud_firestore: ^0.13.0+1


Don't forget to configure firebase:

flutterfire config

Also in your app/build.gradle, increase the minSdkVersion:

Change this:

```
C:\Users\windows_rig2\StudioProjects\flutter_laravel_thoondil_meengal_shop\android\app\build.gradle
```

```
defaultConfig {
    minSdkVersion flutter.minSdkVersion

    targetSdkVersion flutter.targetSdkVersion
}
```

into this:

```
defaultConfig {
    minSdkVersion 23

    targetSdkVersion 33
}
```

```
https://pub.dev/packages/cloud_firestore
```

```
https://pub.dev/packages/firebase_auth#usage
```



Firebase -> Go to console -> Create a project -> flutter listview


Firebase -> Build -> Firestore Database -> Create database -> 


A **`permission-denied`** error when using `cloud_firestore` in Flutter typically occurs when your Firebase Firestore security rules are not configured correctly, or the client does not have the necessary permissions to read or write data.

### Steps to Fix the `permission-denied` Error:

1. **Check Firestore Security Rules**:
   The most common cause of `permission-denied` errors is improperly set Firestore security rules. If you’re in development, you can temporarily allow read/write access for unauthenticated users to test your setup.

   Go to your Firebase Console > Firestore > Rules, and set the rules to the following (for development purposes only):

   ```plaintext
   service cloud.firestore {
     match /databases/{database}/documents {
       match /{document=**} {
         allow read, write: if true;
       }
     }
   }
   ```

   This rule grants **read and write access to everyone**. Make sure you set stricter rules for production environments to avoid security vulnerabilities.

2. **Authenticated Users**:
   If you are using Firebase Authentication and want only authenticated users to access Firestore data, modify the rules to allow access to authenticated users only:

   ```plaintext
   service cloud.firestore {
     match /databases/{database}/documents {
       match /{document=**} {
         allow read, write: if request.auth != null;
       }
     }
   }
   ```

   This ensures that only authenticated users can read and write data in Firestore.

3. **Proper Firestore Setup**:
   Ensure that you have set up Firestore correctly:
   
   - Go to **Firebase Console > Firestore Database**.
   - Ensure your Firestore database is in the **correct mode** (e.g., start with Test Mode during development).
   - Make sure you have initialized Firebase in your Flutter app using `Firebase.initializeApp()`.

4. **Enable Firestore in Firebase Console**:
   If you haven't enabled Firestore in your Firebase project:
   
   - Go to the Firebase Console.
   - Navigate to **Firestore Database**.
   - Click on **Create Database** and follow the steps (ensure you're either in production or test mode).

5. **Flutter App Configuration**:
   Ensure your Firebase configuration files (e.g., `google-services.json` for Android or `GoogleService-Info.plist` for iOS) are properly added and linked to your project. Double-check your Firebase project settings.

6. **Testing Firebase Setup**:
   Try performing simple read and write operations to confirm if the rules are the issue. If the error persists, consider logging out and logging back in (if using Firebase Authentication) to ensure the proper authentication context.

### Example of Restricting Access to Specific Users:

If you want only certain users to have access to Firestore documents, you can use security rules that check specific fields like `uid`:

```plaintext
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

This rule restricts access to a document to the authenticated user who owns the `userId`.

### Recap of Common Causes:

- **Firestore security rules** are too restrictive.
- **Unauthenticated access** to a resource that requires authentication.
- **Firestore database not properly initialized**.
  
After making these changes, you should no longer see the `permission-denied` error unless there is an issue with the user’s authentication or Firestore rule setup.