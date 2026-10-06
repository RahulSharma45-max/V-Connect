import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import for getting the current user
import 'package:cloud_firestore/cloud_firestore.dart'; // Import for updating Firestore
import 'package:v_connect/theme/app_theme.dart';
import 'package:v_connect/theme/widgets.dart';

class ProfileCard extends StatefulWidget {
  final String name;
  final String dept;
  final String customId;
  final bool isOn;

  const ProfileCard({
    required this.name,
    required this.dept,
    required this.customId,
    required this.isOn,
    super.key,
  });

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  late bool _isOn;

  @override
  void initState() {
    super.initState();
    _isOn = false;
  }

  // --- FUNCTION TO UPDATE STATUS IN FIRESTORE ---
  Future<void> _updateOnlineStatus(bool newStatus) async {
    // Get the current user from Firebase Auth
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("Error: No user logged in to update status.");
      return; // Exit if no user is found
    }

    try {
      // Find the user's document in the 'users' collection and update the 'isOnline' field.
      // Using .update() is efficient as it only changes the specified field.
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'isOnline': newStatus},
      );
    } catch (e) {
      // Handle potential errors, e.g., if the document doesn't exist or there's a network issue.
      print("Failed to update online status: $e");
      // Optionally, show a SnackBar to the user
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to update status.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: const Border(
          top: BorderSide(color: AppColors.maroon, width: 2),
        ),
        boxShadow: vCardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.dept,
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.customId,
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CupertinoSwitch(
                value: _isOn,
                onChanged: (value) {
                  // This is the main change
                  // 1. Update the UI immediately
                  setState(() {
                    _isOn = value;
                  });
                  // 2. Call the function to update the database in the background
                  _updateOnlineStatus(value);
                },
                activeTrackColor: AppColors.success,
                inactiveTrackColor: AppColors.border,
              ),
              const SizedBox(height: 8),
              Text(
                _isOn ? "Online" : "Offline",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _isOn
                      ? AppColors.success
                      : AppColors.danger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
