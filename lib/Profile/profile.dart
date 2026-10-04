import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:v_connect/LoginPage/login_page.dart';
import 'package:v_connect/Profile/edit_profile.dart';
// Note: You will need to create this page if it doesn't exist
// import 'package:v_connect/Profile/notification_settings_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  // --- (Helper functions remain the same) ---
  void _showFeedbackSnackBar(
    BuildContext context,
    String message, {
    bool isError = true,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: isError
            ? Colors.redAccent.shade200.withOpacity(0.9)
            : Colors.green.withOpacity(0.9),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginPage();
        }

        final user = snapshot.data!;
        final userEmail = user.email ?? "no-email@example.com";

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: const Color(0xFF1A1A1A),
            elevation: 0,
            shape: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              "Profile",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black, Color(0xFF111111), Colors.black],
              ),
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _profileHeaderCard(context, user: user, userEmail: userEmail),

                  const SizedBox(height: 30),
                  _buildSectionHeader("Account"),
                  _settingsTile(
                    context: context,
                    icon: Icons.edit_outlined,
                    title: "Edit Profile",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfilePage(),
                        ),
                      );
                    },
                  ),
                  _settingsTile(
                    context: context,
                    icon: Icons.lock_outline,
                    title: "Change Password",
                    onTap: () async {
                      try {
                        await FirebaseAuth.instance.sendPasswordResetEmail(
                          email: userEmail,
                        );
                        _showFeedbackSnackBar(
                          context,
                          "Password reset email sent to $userEmail.",
                          isError: false,
                        );
                      } catch (e) {
                        _showFeedbackSnackBar(
                          context,
                          "Failed to send email. Please try again.",
                        );
                      }
                    },
                  ),
                  // _settingsTile(
                  //   context: context,
                  //   icon: Icons.notifications_outlined,
                  //   title: "Notification Settings",
                  //   onTap: () {
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(builder: (context) => const NotificationSettingsPage()),
                  //     );
                  //   },
                  // ),
                  const SizedBox(height: 30),
                  _buildSectionHeader("Support & Legal"),
                  _settingsTile(
                    context: context,
                    icon: Icons.help_outline,
                    title: "Support",
                    onTap: () => _launchUrl(
                      'mailto:support@vconnect.com?subject=Support Request',
                    ),
                  ),

                  // --- MODIFIED LOGOUT BUTTON SECTION ---
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30.0),
                    child: Center(
                      // Center the button horizontally
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.15),
                          foregroundColor: Colors.red.shade300,
                          overlayColor: Colors.red.withOpacity(0.1),
                          // Add padding to give the content breathing room
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                            ),
                            (Route<dynamic> route) => false,
                          );
                        },
                        child: Row(
                          mainAxisSize:
                              MainAxisSize.min, // Shrink Row to fit content
                          children: [
                            const Icon(Icons.logout, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              "Logout",
                              style: GoogleFonts.inter(
                                color: Colors.red.shade300,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- WIDGETS WITH RIPPLE EFFECTS ---

  Widget _profileHeaderCard(
    BuildContext context, {
    required User user,
    required String userEmail,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            splashColor: Colors.white.withOpacity(0.1),
            highlightColor: Colors.white.withOpacity(0.05),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfilePage(),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    backgroundImage: user.photoURL != null
                        ? NetworkImage(user.photoURL!)
                        : null,
                    child: user.photoURL == null
                        ? const Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.white54,
                          )
                        : null,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName ?? "User Name",
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          userEmail,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.7),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0, bottom: 16),
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ),
    );
  }

  Widget _settingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            splashColor: Colors.white.withOpacity(0.1),
            highlightColor: Colors.white.withOpacity(0.05),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white.withOpacity(0.8)),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
