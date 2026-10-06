import 'package:cloud_firestore/cloud_firestore.dart';

/// Read-only view of a `users/{uid}` document for the faculty screens.
///
/// Every text field is trimmed and defaults to an empty string, so the UI
/// can simply check `isNotEmpty`.
class FacultyInfo {
  final String id;
  final String name;
  final String email;
  final String dept;
  final String customId;
  final String phone;
  final String designation;
  final String cabin;
  final String specialization;
  final String officeHours;
  final String? photoUrl;
  final String? timetableUrl;
  final bool isPresent;
  final bool isOnline;
  final DateTime? lastStatusUpdate;

  const FacultyInfo({
    required this.id,
    required this.name,
    required this.email,
    required this.dept,
    required this.customId,
    required this.phone,
    required this.designation,
    required this.cabin,
    required this.specialization,
    required this.officeHours,
    required this.photoUrl,
    required this.timetableUrl,
    required this.isPresent,
    required this.isOnline,
    required this.lastStatusUpdate,
  });

  factory FacultyInfo.fromMap(String id, Map<String, dynamic> data) {
    String text(String key) => (data[key] ?? '').toString().trim();
    String? optional(String key) => text(key).isEmpty ? null : text(key);

    final phoneNumber = text('phoneNumber');
    final statusTime = data['lastStatusUpdate'];

    return FacultyInfo(
      id: id,
      name: text('name'),
      email: text('email'),
      dept: text('dept'),
      customId: text('customId'),
      phone: phoneNumber.isNotEmpty ? phoneNumber : text('phone'),
      designation: text('designation'),
      cabin: text('cabin'),
      specialization: text('specialization'),
      officeHours: text('officeHours'),
      photoUrl: optional('photoUrl'),
      timetableUrl: optional('timetableUrl'),
      isPresent: data['isPresent'] == true,
      isOnline: data['isOnline'] == true,
      lastStatusUpdate: statusTime is Timestamp ? statusTime.toDate() : null,
    );
  }

  String get displayName => name.isEmpty ? 'Unnamed faculty' : name;

  /// The map `ChatPage` / `ensureDirectChat` expect for the other user.
  Map<String, dynamic> toChatUser() => {
    'id': id,
    'uid': id,
    'name': displayName,
    'email': email,
    'dept': dept,
    'customId': customId,
    'phoneNumber': phone,
    'photoUrl': photoUrl,
  };

  bool matches(String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return [
      name,
      dept,
      customId,
      designation,
      specialization,
      email,
    ].any((field) => field.toLowerCase().contains(q));
  }
}
