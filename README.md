V-Connect - Campus Communication Platform

PROTOTYPE PHASE This application is currently in active development and prototype testing. Features may change, and stability is not guaranteed for production use.

About V-Connect

V-Connect is an all-in-one campus communication and management platform built with Flutter. It provides faculty with tools for messaging, event management, timetable sharing, and presence tracking - all in one unified application.

Key Features
Secure Authentication - Firebase-powered login system
Real-time Messaging - Personal and group chats with rich media support
Event Calendar - Create, manage, and track campus events
Timetable Sharing - Upload and view class schedules via Google Drive
User Search - Find and connect with other campus members
Presence Tracking - Mark yourself as present/absent
Push Notifications - Stay updated with important messages
Cross-Platform - Works on Android, iOS, Web, Windows, macOS, and Linux
Firebase Configuration

This codebase is linked to the team's own Firebase project (v-connect-eac00). Configuration files (google-services.json, firebase_options.dart, etc.) are already set up for this project and should not need to be regenerated for normal development.

If you're setting up a personal/testing instance separate from the team project:

Create your own Firebase project
Run flutterfire configure to point your local copy at it (see Setup Instructions below)
Do not commit your personal Firebase config over the team's — check with the team before pushing config file changes
Getting Started - Step by Step
Step 1: Install Required Software

Before you begin, you need to install these programs on your computer:

1.1 Install Flutter SDK
Go to Flutter's official website
Choose your operating system (Windows, macOS, or Linux)
Download the Flutter SDK
Follow the installation instructions for your OS
After installation, open a terminal/command prompt and type:
bash
   flutter doctor

This will check if everything is installed correctly.

1.2 Install an IDE (Code Editor)

Choose one of these:

Visual Studio Code (Recommended for beginners)
Download from: https://code.visualstudio.com/
After installing, add the Flutter extension:
Open VS Code
Click on Extensions icon (left sidebar)
Search for "Flutter"
Click Install
Android Studio
Download from: https://developer.android.com/studio
Includes Android emulator for testing
1.3 Install Git
Go to https://git-scm.com/downloads
Download and install Git for your operating system
Follow the installation wizard (default settings are fine)
Step 2: Download the Code
Option A: Using Git (Recommended)
Open Terminal (Mac/Linux) or Command Prompt (Windows)
Navigate to where you want to save the project:
bash
   cd Desktop
Clone the repository:
bash
   git clone https://github.com/RahulSharma45-max/V-Connect.git
   cd V-Connect
Option B: Download as ZIP
Go to the GitHub repository page
Click the green "Code" button
Select "Download ZIP"
Extract the ZIP file to your desired location
Open Terminal/Command Prompt and navigate to the extracted folder:
bash
   cd path/to/V-Connect
Step 3: Install Dependencies

Once you're in the project folder:

Run this command to download all required packages:
bash
   flutter pub get
Wait for it to complete (may take a few minutes)
Step 4: Firebase Setup

The project is already configured to use the team's Firebase project (v-connect-eac00). If your local checkout has working google-services.json and firebase_options.dart files, you can skip straight to Step 5.

If you need to reconfigure (e.g., setting up your own separate test project):

Install FlutterFire CLI:
bash
   dart pub global activate flutterfire_cli
Configure Your Project:
bash
   flutterfire configure
Login with your Google account
Select the Firebase project you want to use
Select all platforms you want to support (use spacebar to select, enter to confirm)
This will automatically update lib/firebase_options.dart
Note: Firestore Security Rules are already configured for the team project. If using your own separate project, you'll need to set up your own rules — see firestore.rules in this repo for the current production rules as a reference.
Step 5: Run the Application
On Android Emulator:
Start an Emulator:
Open Android Studio
Click "Device Manager" (phone icon on right sidebar)
Click "Create Device"
Select a phone model (e.g., Pixel 5)
Select a system image (latest Android version)
Click Finish
Run the App:
bash
   flutter run
On Physical Device:

Android:

Enable Developer Options on your phone:
Go to Settings > About Phone
Tap "Build Number" 7 times
Go back to Settings > Developer Options
Enable "USB Debugging"
Connect your phone via USB
Run:
bash
   flutter run

iOS (Mac only):

Connect your iPhone via USB
Trust your computer on the iPhone
Run:
bash
   flutter run
On Web:
bash
flutter run -d chrome
Project Structure
V-Connect/
├── lib/
│   ├── Calendar/          # Event calendar functionality
│   ├── Chat/              # Messaging system
│   ├── HomePage/          # Main dashboard
│   ├── LoginPage/         # Authentication screens
│   ├── Profile/           # User profile management
│   ├── Search/            # User search functionality
│   ├── auth_gate.dart     # Authentication handler
│   ├── firebase_options.dart  # Firebase configuration
│   └── main.dart          # App entry point
├── android/               # Android-specific code (package: com.vconnect.app)
├── ios/                   # iOS-specific code
├── web/                   # Web-specific code
├── functions/             # Firebase Cloud Functions (not currently deployed - see Known Issues)
├── firebase-admin-panel/  # Standalone admin tool for user management
├── assets/                # Images and resources
└── pubspec.yaml           # Dependencies configuration
Creating Test Accounts

Since this is a prototype, you'll need to create user accounts through Firebase Console:

Go to Firebase Console > Authentication > Users
Click "Add User"
Enter email and password
After creating, go to Firestore Database
Create a document in users collection with the user's UID:
json
   {
     "name": "John Doe",
     "email": "john@example.com",
     "dept": "Computer Science",
     "customId": "CS001",
     "isPresent": false,
     "photoUrl": "",
     "phoneNumber": ""
   }

Alternatively, use firebase-admin-panel/index.html (requires a login gate — see its own notes) for manual or CSV bulk user creation.

Known Issues / Pending Work
Cloud Functions not deployed - functions/index.js contains a notification-sending function but requires the Firebase Blaze (pay-as-you-go) plan to deploy. Currently deferred; the app works fully without it, minus automatic push notifications on new calendar events.
Firebase Storage not enabled - also requires the Blaze plan. Profile photo uploads via Storage are not yet available; the app currently relies on external links (e.g., Google Drive) for some media.
iOS/macOS/Linux package identifiers - still using placeholder com.example.* values. Only Android (com.vconnect.app) has been properly renamed, since that's the primary target platform currently in use. Update these before building for those platforms.
Admin panel authentication - firebase-admin-panel/index.html has a login gate but real enforcement depends on Firestore Security Rules; see comments in that file for details.
Troubleshooting
"Flutter not found"
Make sure Flutter is added to your system PATH
Restart your terminal/command prompt
Run flutter doctor to verify installation
"Gradle build failed" (Android)
Open android/ folder in Android Studio
Let it sync and download dependencies
Try running again
If you see a Java/Gradle version mismatch, check that Flutter is configured to use a compatible JDK: flutter config --jdk-dir="path/to/jdk17"
"Pod install failed" (iOS)
Navigate to ios/ folder
Run: pod install
If that fails: pod repo update then pod install
"Firebase configuration error"
Make sure you ran flutterfire configure
Check that firebase_options.dart exists
Verify your Firebase project is set up correctly
App crashes on startup
Check Firebase Console > Authentication is enabled
Verify Firestore Database is created
Confirm Firestore Security Rules are published (see firestore.rules)
Building for Release
Android APK:
bash
flutter build apk --release

Output: build/app/outputs/flutter-apk/app-release.apk

Note: requires android/key.properties pointing to a valid signing keystore. This file is intentionally excluded from git — each developer/environment needs their own local copy. Contact the team for the current release signing key if you need to produce an official release build.

iOS App (Mac only):
bash
flutter build ios --release

Then open Xcode to archive and distribute.

Web:
bash
flutter build web

Output: build/web/ folder

Contributing
Fork the repository (or create a feature branch if you're a team member)
Create a feature branch
Make your changes
Submit a pull request
Important Notes
Prototype Status: This app is under active development. Features may be incomplete or change without notice.
Firebase Limits: The free Firebase Spark plan has usage limits. Storage and Cloud Functions require the Blaze plan (see Known Issues).
Security: Firestore Security Rules are configured and enforced (see firestore.rules) - do not revert to open test-mode rules.
Signing Keys: Never commit .jks keystore files or key.properties to version control.
Support

For issues specific to this codebase:

Check existing GitHub issues
Create a new issue with detailed description
Include error messages and screenshots

For Firebase-specific issues:

Visit Firebase Documentation
Check FlutterFire Documentation

Flutter Version: 3.47+ Dart Version: 3.13+

Firebase Admin Panel

A lightweight admin panel for managing users in the V-Connect Firebase project, located at firebase-admin-panel/index.html.

Features
Manual user creation (email, password, department, etc.)
CSV bulk user import (using PapaParse)
Displays all users in a live table
Login-gated - requires signing in with an authorized account before use
Setup Instructions
Go to Firebase Console → Project Settings → "General" tab
Scroll to Your apps → Web App
Copy your Firebase config and paste it into the firebaseConfig object inside firebase-admin-panel/index.html
Do not commit your filled-in config to a public repository.
Usage
Open index.html in your browser (no server required)
Sign in with an authorized account
Use the Manual Form to add users individually, or import a CSV with columns:
   Name,Email,Password,Dept,ID,Phone,PhotoUrl
Important Notes
Do NOT commit filled-in Firebase credentials to a public GitHub repository
Always use test accounts when trying bulk imports
For production, restrict API key access in the Firebase Console