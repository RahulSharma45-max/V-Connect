import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:v_connect/theme/app_theme.dart';

class PasswordField extends StatefulWidget {
  final TextEditingController passwordController;
  const PasswordField(this.passwordController, {super.key});

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _isPasswordObscured = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.passwordController,
      obscureText: _isPasswordObscured,
      style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: "Password",
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordObscured ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () {
            setState(() {
              _isPasswordObscured = !_isPasswordObscured;
            });
          },
        ),
      ),
    );
  }
}
