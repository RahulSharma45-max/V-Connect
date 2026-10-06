import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:v_connect/theme/app_theme.dart';

class UserName extends StatelessWidget {
  final TextEditingController usernameController;

  const UserName(this.usernameController, {super.key});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: usernameController,
      keyboardType: TextInputType.emailAddress,
      style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15),
      decoration: const InputDecoration(
        labelText: "Username (Email)",
        prefixIcon: Icon(Icons.person_outline),
      ),
    );
  }
}
