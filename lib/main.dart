import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/services.dart';
// ignore: depend_on_referenced_packages
import 'package:google_fonts/google_fonts.dart';
import 'package:v_connect/LoginPage/login_page.dart';
import 'package:v_connect/HomePage/homepage.dart';
import 'package:v_connect/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.grey[900],
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          secondary: Colors.transparent, // For the overscroll glow
        ),

        // MODIFICATION: Add this AppBarTheme to control all AppBars
        appBarTheme: const AppBarTheme(
          // This ensures the AppBar background is consistent
          backgroundColor: Color(0xFF1A1A1A),
          // This is the key property to prevent the color change on scroll
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),

        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.blueAccent,
          selectionColor: Colors.blueAccent.withOpacity(0.4),
          selectionHandleColor: Colors.blueAccent,
        ),
        scaffoldBackgroundColor: const Color.fromARGB(255, 0, 0, 0),
      ),
      home: const AuthGate(),
    );
  }
}
