import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart' hide NavigationBar;
import 'package:image_picker/image_picker.dart';
import 'package:v_connect/HomePage/navigation_bar.dart';
import 'package:v_connect/HomePage/profile_card.dart';
import 'package:photo_view/photo_view.dart';

class Homepage extends StatefulWidget {
  User? user;
  Homepage({super.key, required this.user});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> with WidgetsBindingObserver {
  String name = "";
  String dept = "";
  String customId = "";
  bool isPresent = false; // true = Present, false = Absent

  bool _selectedToday = false;
  bool _selectedFuture = false;
  bool _selectedTime = false;

  bool _showTodayEvents = false;
  bool _showFutureEvents = false;
  bool _showTimeTable = false;

  String? timetableUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    fetchUserData();
    fetchTimetable();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// ✅ Toggle status between Present and Absent
  Future<void> toggleStatus() async {
    if (widget.user == null) return;

    bool newStatus = !isPresent;

    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.user!.uid)
          .update({
            'isPresent': newStatus,
            'lastStatusUpdate': FieldValue.serverTimestamp(),
          });

      setState(() {
        isPresent = newStatus;
      });
    } catch (e) {
      print("Error updating status: $e");
    }
  }

  Future<void> fetchUserData() async {
    if (widget.user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.user!.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        setState(() {
          name = data?['name'] ?? "";
          dept = data?['dept'] ?? "";
          customId = data?['customId'] ?? "";
          isPresent = data?['isPresent'] ?? false;
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  /// ✅ Stream for TODAY events
  Stream<List<Map<String, dynamic>>> streamTodayEvents() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    final now = DateTime.now();
    DateTime todayStart = DateTime(now.year, now.month, now.day);
    DateTime todayEnd = todayStart.add(const Duration(days: 1));

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('events')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .where('date', isLessThan: Timestamp.fromDate(todayEnd))
        .orderBy('date')
        .snapshots()
        .map((snap) {
          return snap.docs.map((doc) {
            final d = doc.data();
            return {
              "id": doc.id,
              "title": d["title"],
              "time": d["time"],
              "date": (d["date"] as Timestamp).toDate(),
            };
          }).toList();
        });
  }

  /// ✅ Stream for FUTURE events
  Stream<List<Map<String, dynamic>>> streamFutureEvents() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('events')
        .where(
          'date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()),
        )
        .orderBy('date')
        .snapshots()
        .map((snap) {
          return snap.docs.map((doc) {
            final d = doc.data();
            return {
              "id": doc.id,
              "title": d["title"],
              "time": d["time"],
              "date": (d["date"] as Timestamp).toDate(),
            };
          }).toList();
        });
  }

  /// ✅ Load timetable
  Future<void> fetchTimetable() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    if (doc.exists && doc.data()?["timetableUrl"] != null) {
      setState(() {
        timetableUrl = doc.data()?["timetableUrl"];
      });
    }
  }

  /// ✅ Convert Google Drive sharing link to direct link
  String? convertGoogleDriveLink(String link) {
    try {
      RegExp regExp = RegExp(r'(?:id=|\/d\/|\/file\/d\/)([a-zA-Z0-9_-]+)');
      final match = regExp.firstMatch(link);

      if (match != null && match.groupCount >= 1) {
        String fileId = match.group(1)!;
        return 'https://drive.google.com/uc?export=view&id=$fileId';
      }
    } catch (e) {
      print("Error converting link: $e");
    }
    return null;
  }

  /// ✅ Upload timetable via Google Drive link
  Future<void> uploadTimetable() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final TextEditingController linkController = TextEditingController();

    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: BorderSide(color: Colors.white.withOpacity(0.2)),
          ),
          title: const Center(
            child: Text(
              "Enter Google Drive Link",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 20,
              ),
            ),
          ),
          content: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: TextField(
              controller: linkController,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: "Paste Google Drive link here",
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                border: InputBorder.none,
              ),
              maxLines: 3,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            SizedBox(
              width: 120,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.15),
                  foregroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                    side: BorderSide(color: Colors.red.withOpacity(0.3)),
                  ),
                ),
                child: const Text(
                  "Cancel",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 120,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  side: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                onPressed: () async {
                  if (linkController.text.isNotEmpty) {
                    final convertedUrl = convertGoogleDriveLink(
                      linkController.text,
                    );

                    if (convertedUrl != null) {
                      await FirebaseFirestore.instance
                          .collection("users")
                          .doc(user.uid)
                          .update({"timetableUrl": convertedUrl});

                      setState(() {
                        timetableUrl = convertedUrl;
                      });

                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Invalid Google Drive link"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text(
                  "Save",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// ✅ Show timetable in zoomable popup
  void _showTimetablePopup() {
    if (timetableUrl == null) return;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            PhotoView(
              imageProvider: NetworkImage(timetableUrl!),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 3,
              backgroundDecoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              loadingBuilder: (context, event) => Center(
                child: CircularProgressIndicator(
                  value: event == null
                      ? 0
                      : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
                  color: Colors.white,
                ),
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 70),

                  /// ✅ PROFILE CARD WITH COMPACT TOGGLE ON RIGHT SIDE
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),

                        /// Middle - User Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dept,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                customId,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ),

                        /// ✅ Right Side - Compact Status Toggle Button
                        GestureDetector(
                          onTap: toggleStatus,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isPresent
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: isPresent ? Colors.green : Colors.red,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPresent ? Icons.check_circle : Icons.cancel,
                                  color: isPresent ? Colors.green : Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isPresent ? "PRESENT" : "ABSENT",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// ✅ TOP BUTTONS
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      height: 50,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _topButton("Current Events", _selectedToday, () {
                            setState(() {
                              if (_selectedToday) {
                                _selectedToday = false;
                                _showTodayEvents = false;
                              } else {
                                _selectedToday = true;
                                _selectedFuture = false;
                                _selectedTime = false;

                                _showTodayEvents = true;
                                _showFutureEvents = false;
                                _showTimeTable = false;
                              }
                            });
                          }),

                          const SizedBox(width: 10),

                          _topButton("Future Events", _selectedFuture, () {
                            setState(() {
                              if (_selectedFuture) {
                                _selectedFuture = false;
                                _showFutureEvents = false;
                              } else {
                                _selectedFuture = true;
                                _selectedToday = false;
                                _selectedTime = false;

                                _showFutureEvents = true;
                                _showTodayEvents = false;
                                _showTimeTable = false;
                              }
                            });
                          }),

                          const SizedBox(width: 10),

                          _topButton("Time Table", _selectedTime, () {
                            setState(() {
                              if (_selectedTime) {
                                _selectedTime = false;
                                _showTimeTable = false;
                              } else {
                                _selectedTime = true;
                                _selectedToday = false;
                                _selectedFuture = false;

                                _showTimeTable = true;
                                _showTodayEvents = false;
                                _showFutureEvents = false;
                              }
                            });
                          }),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  if (_showTodayEvents)
                    _eventsListSection(
                      title: "Current Events",
                      stream: streamTodayEvents(),
                    ),

                  if (_showFutureEvents)
                    _eventsListSection(
                      title: "Upcoming Events",
                      stream: streamFutureEvents(),
                    ),

                  if (_showTimeTable) _timetableSection(),
                ],
              ),
            ),
          ),

          NavigationBar(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// ✅ BUTTON UI
  Widget _topButton(String text, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withOpacity(0.20)
              : Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected
                ? Colors.white.withOpacity(0.50)
                : Colors.white.withOpacity(0.25),
            width: selected ? 1.3 : 1,
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  /// ✅ Timetable Section
  Widget _timetableSection() {
    return _wrapContainer(
      child: Column(
        children: [
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.table_chart, color: Colors.white, size: 26),
                SizedBox(width: 10),
                Text(
                  "Time Table",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          timetableUrl == null
              ? Column(
                  children: [
                    const Text(
                      "No Time Table Uploaded",
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: uploadTimetable,
                          icon: const Icon(Icons.link),
                          label: const Text("Add Google Drive Link"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    GestureDetector(
                      onTap: _showTimetablePopup,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            Image.network(
                              timetableUrl!,
                              height: 200,
                              fit: BoxFit.contain,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return SizedBox(
                                      height: 200,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value:
                                              loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                              : null,
                                          color: Colors.white,
                                        ),
                                      ),
                                    );
                                  },
                            ),
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.zoom_in,
                                    color: Colors.white,
                                    size: 48,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: uploadTimetable,
                          icon: const Icon(Icons.link),
                          label: const Text("Replace Timetable Link"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  /// ✅ EVENTS LIST
  Widget _eventsListSection({
    required String title,
    required Stream<List<Map<String, dynamic>>> stream,
  }) {
    return StreamBuilder(
      stream: stream,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        final events = snap.data!;

        return _wrapContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.event, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: events.length,
                itemBuilder: (_, i) {
                  final e = events[i];
                  final isLast = i == events.length - 1;

                  return Container(
                    margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e["title"],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 17,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${e['time']} • ${e['date'].day}/${e['date'].month}/${e['date'].year}",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// ✅ Container Styling
  Widget _wrapContainer({required Widget child}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: child,
    );
  }
}
