import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:v_connect/theme/app_theme.dart';
import 'package:v_connect/theme/widgets.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _phoneController = TextEditingController();

  /// Optional faculty details shown on the Faculty profile page, keyed by
  /// their Firestore field name.
  final Map<String, TextEditingController> _facultyFields = {
    'designation': TextEditingController(),
    'cabin': TextEditingController(),
    'specialization': TextEditingController(),
    'officeHours': TextEditingController(),
  };

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance.collection('users').doc(user.uid).get().then((
        doc,
      ) {
        final data = doc.data();
        if (!mounted || !doc.exists || data == null) return;
        setState(() {
          if (data.containsKey('phoneNumber')) {
            _phoneController.text = data['phoneNumber'];
          }
          _facultyFields.forEach((field, controller) {
            controller.text = (data[field] ?? '').toString();
          });
        });
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    for (final controller in _facultyFields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final phoneNumber = _phoneController.text.trim();

    if (phoneNumber.isEmpty) {
      _showFeedbackSnackBar("Phone number cannot be empty.");
      return;
    }

    // 10 digits only
    final phoneRegex = RegExp(r'^[0-9]{10}$');
    if (!phoneRegex.hasMatch(phoneNumber)) {
      _showFeedbackSnackBar("Phone number must be exactly 10 digits.");
      return;
    }

    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not found");

      final dataToUpdate = <String, dynamic>{
        'phoneNumber': phoneNumber,
        for (final entry in _facultyFields.entries)
          entry.key: entry.value.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(dataToUpdate, SetOptions(merge: true));

      _showFeedbackSnackBar("Profile updated successfully!", isError: false);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showFeedbackSnackBar("Failed to update profile. Please try again.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showFeedbackSnackBar(String message, {bool isError = true}) {
    showVSnackBar(context, message, isError: isError);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const VAppBar(title: "Edit Profile"),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        children: [
          Center(
            child: VAvatar(
              name: user?.displayName ?? user?.email ?? '',
              photoUrl: user?.photoURL,
              radius: 50,
            ),
          ),
          const SizedBox(height: 24),
          VSectionCard(
            title: 'Contact Details',
            icon: Icons.contact_phone_outlined,
            child: _buildTextField(
              controller: _phoneController,
              labelText: "Phone Number",
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              digitsOnly: true,
            ),
          ),
          VSectionCard(
            title: 'Faculty Details',
            icon: Icons.work_outline,
            child: Column(
              children: [
                _buildTextField(
                  controller: _facultyFields['designation']!,
                  labelText: "Designation (e.g. Assistant Professor)",
                  icon: Icons.work_outline,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _facultyFields['cabin']!,
                  labelText: "Cabin / Room",
                  icon: Icons.meeting_room_outlined,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _facultyFields['specialization']!,
                  labelText: "Specialization",
                  icon: Icons.school_outlined,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _facultyFields['officeHours']!,
                  labelText: "Office Hours (e.g. Mon–Fri, 2–4 PM)",
                  icon: Icons.schedule_outlined,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _isLoading ? null : _saveProfile,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.onPrimary,
                        ),
                      )
                    : Text(
                        "Save Changes",
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType? keyboardType,
    bool digitsOnly = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: digitsOnly
          ? TextCapitalization.none
          : TextCapitalization.words,
      inputFormatters: digitsOnly
          ? [
              LengthLimitingTextInputFormatter(10),
              FilteringTextInputFormatter.digitsOnly,
            ]
          : [LengthLimitingTextInputFormatter(80)],
      style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15),
      decoration: InputDecoration(labelText: labelText, prefixIcon: Icon(icon)),
    );
  }
}
