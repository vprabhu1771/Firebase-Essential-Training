require('dotenv').config();

const { initializeApp, applicationDefault } = require('firebase-admin/app');
const { getMessaging } = require('firebase-admin/messaging');
const express = require('express');
const cors = require('cors');

process.env.GOOGLE_APPLICATION_CREDENTIALS;

const app = express();
app.use(express.json());

const port = process.env.PORT || 3000;
const host = process.env.HOST || '0.0.0.0';

app.use(cors({ origin: "*" }));

app.use(cors({ methods: ["GET", "POST", "DELETE", "UPDATE", "PUT", "PATCH"] }));

app.use(function(req, res, next) {
  res.setHeader("Content-Type", "application/json");
  next();
});

initializeApp({
  credential: applicationDefault(),
  projectId: 'helloworld-80d40',
});

app.post("/send", function (req, res) {
  const receivedToken = req.body.fcmToken;
  
  const message = {
    notification: {
      title: "Welcome to Bughunt Technologies",
      body: 'Flutter and Firebase Class Completed'
    },
    token: receivedToken,
  };
  
  getMessaging()
    .send(message)
    .then((response) => {
      res.status(200).json({
        message: "Successfully sent message",
        token: receivedToken,
      });
      console.log("Successfully sent message:", response);
    })
    .catch((error) => {
      res.status(400);
      res.send(error);
      console.log("Error sending message:", error);
    });
});

app.listen(port, function () {
  console.log(`Server is running on http://${host}:${port}`);
});
