import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:v_connect/theme/app_theme.dart';
import 'package:v_connect/theme/widgets.dart';

class ForgotPassword extends StatelessWidget {
  final TextEditingController usernameController;
  const ForgotPassword(this.usernameController, {super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () async {
        if (usernameController.text.trim().isEmpty) {
          showVSnackBar(
            context,
            "Please enter your email to reset your password.",
            isError: true,
          );
          return;
        }
        try {
          await FirebaseAuth.instance.sendPasswordResetEmail(
            email: usernameController.text.trim(),
          );
          showVSnackBar(
            context,
            "Password reset email sent. Check your inbox.",
          );
        } catch (e) {
          showVSnackBar(
            context,
            "Failed to send reset email. Please try again.",
            isError: true,
          );
        }
      },
      style: TextButton.styleFrom(foregroundColor: AppColors.maroon),
      child: Text('Forgot Password?', style: GoogleFonts.inter(fontSize: 13)),
    );
  }
}
