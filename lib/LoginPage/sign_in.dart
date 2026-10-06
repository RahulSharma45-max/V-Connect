import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:v_connect/HomePage/homepage.dart'; // Ensure this path is correct
import 'package:v_connect/theme/app_theme.dart';
import 'package:v_connect/theme/widgets.dart';

class SignInButton extends StatelessWidget {
  final TextEditingController usernameController;
  final TextEditingController passwordController;

  const SignInButton(
    this.usernameController,
    this.passwordController, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(color: AppColors.onPrimary),
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
            showVSnackBar(
              context,
              e.message ?? "An unknown error occurred.",
              isError: true,
            );
          }
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        icon: const Icon(Icons.login, size: 20),
        label: Text(
          'Sign In',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
