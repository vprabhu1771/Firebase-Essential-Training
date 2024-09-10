# https://www.youtube.com/watch?v=J8j_jzWPRtw

# https://pub.dev/packages/firebase_core

# https://pub.dev/packages/firebase_messaging

Firebase Doc -> Admin SDK -> Get started with Firebase -> Add Firebase to a server -> Send Firebase Cloud Messaging messages

```
mkdir notify
```

```
cd notify
```

```
npm init --y
```

```
Create File server.js
```




```
Firebase -> Project Overview -> Project Settings -> Service Accounts -> Firebase Admin SDK 
```

`Admin SDK configuration snippet`

`Node.js`

open `server.js`

```
var admin = require("firebase-admin");

var serviceAccount = require("path/to/serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});
```

Click -> `Generate new private key`


