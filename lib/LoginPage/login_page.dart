import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:v_connect/LoginPage/forgot_password.dart';
import 'package:v_connect/LoginPage/username.dart';
import 'package:v_connect/LoginPage/password.dart';
import 'package:v_connect/LoginPage/sign_in.dart';
import 'package:v_connect/theme/app_theme.dart';
import 'package:v_connect/theme/widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: const VAppBar(
          titleWidget: VBrandMark(),
          automaticallyImplyLeading: false,
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'V-Connect connects your campus',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: AppColors.primary,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Text(
                        'One platform for faculty messaging, events, timetables and presence.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    VSectionCard(
                      title: 'Faculty Login',
                      icon: Icons.badge_outlined,
                      accent: AppColors.primary,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          UserName(usernameController),
                          const SizedBox(height: 16),
                          PasswordField(passwordController),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ForgotPassword(usernameController),
                          ),
                          const SizedBox(height: 8),
                          SignInButton(usernameController, passwordController),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.lock_outline,
                            size: 14,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Accounts are issued by the campus administrator.',
                              style: GoogleFonts.inter(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const VFooter(),
          ],
        ),
      ),
    );
  }
}
