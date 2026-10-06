import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:v_connect/theme/app_theme.dart';
import 'package:v_connect/theme/widgets.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  Map<DateTime, List<Map<String, dynamic>>> _firestoreEvents = {};
  late final StreamSubscription<QuerySnapshot> _eventsSubscription;
  bool _isLoading = true;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _mainScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _listenToEvents();
  }

  void _listenToEvents() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    _eventsSubscription = _getEventsCollection().snapshots().listen(
      (snapshot) {
        if (!mounted) return;

        final newEvents = <DateTime, List<Map<String, dynamic>>>{};
        for (var doc in snapshot.docs) {
          final data = doc.data();
          if (data['date'] != null) {
            final date = (data['date'] as Timestamp).toDate();
            final event = {
              'id': doc.id,
              'title': data['title'],
              'time': data['time'],
            };
            final dateKey = DateUtils.dateOnly(date);
            newEvents.putIfAbsent(dateKey, () => []).add(event);
          }
        }

        setState(() {
          _firestoreEvents = newEvents;
          _isLoading = false;
        });
      },
      onError: (error) {
        print("Error listening to events: $error");
        setState(() => _isLoading = false);
      },
    );
  }

  @override
  void dispose() {
    _eventsSubscription.cancel();
    _titleController.dispose();
    _timeController.dispose();
    _scrollController.dispose();
    _mainScrollController.dispose();
    super.dispose();
  }

  CollectionReference<Map<String, dynamic>> _getEventsCollection() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null)
      throw Exception("User not found for calendar operations.");
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('events');
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _firestoreEvents[DateUtils.dateOnly(day)] ?? [];
  }

  void _addEvent() {
    _titleController.clear();
    _timeController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return _eventDialog(
          title: "Add Event",
          onSave: () async {
            if (_titleController.text.isNotEmpty &&
                _timeController.text.isNotEmpty) {
              await _getEventsCollection().add({
                'title': _titleController.text,
                'time': _timeController.text,
                'date': Timestamp.fromDate(_selectedDay),
              });
              if (mounted) Navigator.pop(context);
            }
          },
        );
      },
    );
  }

  void _editEvent(Map<String, dynamic> eventToEdit) {
    showDialog(
      context: context,
      builder: (context) {
        return _eventDialog(
          title: "Edit Event",
          initialTitle: eventToEdit['title'],
          initialTime: eventToEdit['time'],
          onSave: () async {
            if (_titleController.text.isNotEmpty &&
                _timeController.text.isNotEmpty) {
              await _getEventsCollection().doc(eventToEdit['id']).update({
                'title': _titleController.text,
                'time': _timeController.text,
              });
              if (mounted) Navigator.pop(context);
            }
          },
        );
      },
    );
  }

  void _deleteEvent(String eventId) {
    _getEventsCollection().doc(eventId).delete();
  }

  void _showEventOptions(Map<String, dynamic> event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const VSheetHandle(),
                const SizedBox(height: 18),
                Text(
                  event["title"] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.schedule,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      event["time"] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.edit, color: AppColors.primary),
                  title: Text(
                    "Edit Event",
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _editEvent(event);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: AppColors.danger,
                  ),
                  title: Text(
                    "Delete Event",
                    style: GoogleFonts.inter(
                      color: AppColors.danger,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteEvent(event['id']);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _eventDialog({
    required String title,
    required VoidCallback onSave,
    String? initialTitle,
    String? initialTime,
  }) {
    _titleController.text = initialTitle ?? '';
    _timeController.text = initialTime ?? '';
    TimeOfDay? localPickedTime = _timeController.text.isNotEmpty
        ? _parseTimeOfDay(_timeController.text)
        : null;
    return StatefulBuilder(
      builder: (context, setStateDialog) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.event_note, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
                decoration: const InputDecoration(
                  labelText: "Event Title",
                  prefixIcon: Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: localPickedTime ?? TimeOfDay.now(),
                    );
                    if (picked != null) {
                      localPickedTime = picked;
                      _timeController.text = picked.format(context);
                      setStateDialog(() {});
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.schedule),
                  label: Text(
                    localPickedTime != null
                        ? localPickedTime!.format(context)
                        : (_timeController.text.isNotEmpty
                              ? _timeController.text
                              : "Pick time"),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
              ),
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(onPressed: onSave, child: const Text("Save")),
          ],
        );
      },
    );
  }

  TimeOfDay _parseTimeOfDay(String formatted) {
    try {
      final regex = RegExp(
        r'(\d{1,2}):(\d{2})\s*(AM|PM)',
        caseSensitive: false,
      );
      final match = regex.firstMatch(formatted);
      if (match != null) {
        int hour = int.parse(match.group(1)!);
        final minute = int.parse(match.group(2)!);
        final ampm = match.group(3)!.toUpperCase();
        if (ampm == 'PM' && hour != 12) hour += 12;
        if (ampm == 'AM' && hour == 12) hour = 0;
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (_) {}
    return TimeOfDay.now();
  }

  Widget _eventCard({
    required String title,
    required String time,
    required VoidCallback onEdit,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(4),
        border: const Border(
          left: BorderSide(color: AppColors.accentGold, width: 3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt, color: AppColors.maroon, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  time,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit, color: AppColors.primary, size: 20),
            tooltip: 'Edit event',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please log in to use the calendar.")),
      );
    }

    final todayEvents = _getEventsForDay(_selectedDay);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const VAppBar(title: "Events"),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addEvent,
        icon: const Icon(Icons.add),
        label: Text(
          'Add Event',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              controller: _mainScrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                children: [
                  VSectionCard(
                    title: 'Calendar',
                    icon: Icons.calendar_month,
                    accent: AppColors.primary,
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                    child: TableCalendar(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) =>
                          isSameDay(_selectedDay, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      daysOfWeekHeight: 32,
                      rowHeight: 46,
                      availableGestures: AvailableGestures.horizontalSwipe,
                      eventLoader: _getEventsForDay,

                      // Custom builder to make only Sunday dates red
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) {
                          // Check if it's Sunday (weekday 7)
                          if (day.weekday == DateTime.sunday) {
                            return Center(
                              child: Text(
                                '${day.day}',
                                style: const TextStyle(
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            );
                          }
                          return null; // Use default styling for other days
                        },
                      ),

                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        headerPadding: const EdgeInsets.symmetric(vertical: 8),
                        titleTextStyle: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                        leftChevronIcon: const Icon(
                          Icons.chevron_left,
                          color: AppColors.primary,
                        ),
                        rightChevronIcon: const Icon(
                          Icons.chevron_right,
                          color: AppColors.primary,
                        ),
                      ),
                      daysOfWeekStyle: DaysOfWeekStyle(
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceAlt,
                        ),
                        weekdayStyle: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        weekendStyle: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      calendarStyle: CalendarStyle(
                        cellMargin: const EdgeInsets.all(6),
                        defaultTextStyle: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                        // Saturday stays normal, only Sunday is red (handled in builder)
                        weekendTextStyle: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                        outsideTextStyle: const TextStyle(
                          color: AppColors.border,
                          fontSize: 15,
                        ),
                        // Today: outlined circle
                        todayDecoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                          shape: BoxShape.circle,
                        ),
                        todayTextStyle: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                        // Selected: filled circle
                        selectedDecoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        selectedTextStyle: const TextStyle(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        markersMaxCount: 1,
                        markerDecoration: const BoxDecoration(
                          color: AppColors.maroon,
                          shape: BoxShape.circle,
                        ),
                        markerSize: 5,
                        markerMargin: const EdgeInsets.symmetric(
                          horizontal: 0.5,
                        ),
                        markersAnchor: 0.7,
                      ),
                    ),
                  ),
                  VSectionCard(
                    title:
                        "Events for ${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}",
                    icon: Icons.event_note,
                    child: todayEvents.isEmpty
                        ? const VEmptyState(
                            icon: Icons.event_busy,
                            title: "No Events",
                            subtitle: 'Tap "Add Event" to schedule one.',
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            itemCount: todayEvents.length,
                            itemBuilder: (context, index) {
                              final event = todayEvents[index];
                              return GestureDetector(
                                onTap: () => _showEventOptions(event),
                                child: _eventCard(
                                  title: event["title"] ?? '',
                                  time: event["time"] ?? '',
                                  onEdit: () => _editEvent(event),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }
}
