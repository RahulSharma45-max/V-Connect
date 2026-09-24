const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// CORRECTED PATH: the Flutter app writes new events to a subcollection under
// each user's own document - confirmed from lib/Calendar/calendar.dart and
// lib/HomePage/homepage.dart, both of which use:
//   .collection('users').doc(user.uid).collection('events')
// The original version of this function listened on a top-level 'events/{eventId}'
// path, which nothing in the app ever writes to - so it would never have fired.
exports.sendEventNotification = functions.firestore
    .document("users/{userId}/events/{eventId}") // matches the app's actual write path
    .onCreate(async (snap, context) => {
      const event = snap.data(); // get event data

      const message = {
        notification: {
          title: "New Event: " + event.title,
          body: event.description,
        },
        topic: "allUsers", // must match topic in Flutter app
      };

      try {
        const response = await admin.messaging().send(message);
        console.log("Notification sent:", response);
      } catch (error) {
        console.error("Error sending notification:", error);
      }
    });
