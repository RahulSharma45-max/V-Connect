import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:v_connect/HomePage/homepage.dart'; // Ensure this path is correct

class SignInButton extends StatelessWidget {
  final TextEditingController usernameController;
  final TextEditingController passwordController;

  const SignInButton(
    this.usernameController,
    this.passwordController, {
    super.key,
  });

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: Colors.redAccent.shade200.withOpacity(0.9),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );

          try {
            final email = usernameController.text.trim();
            final password = passwordController.text.trim();

            UserCredential credential = await FirebaseAuth.instance
                .signInWithEmailAndPassword(email: email, password: password);

            User? user = credential.user;

            if (context.mounted) Navigator.of(context).pop();

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => Homepage(user: user)),
            );
          } on FirebaseAuthException catch (e) {
            if (context.mounted) Navigator.of(context).pop();
            _showErrorSnackBar(
              context,
              e.message ?? "An unknown error occurred.",
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.15),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: Text(
          'Sign In',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
