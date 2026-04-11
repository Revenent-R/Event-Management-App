import 'package:event_manager/homepage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventCreationState extends StatefulWidget {
  const EventCreationState({super.key});

  @override
  State<EventCreationState> createState() => EventCreation();
}

class EventCreation extends State<EventCreationState> {
  final TextEditingController eventName = TextEditingController();
  final TextEditingController eventVenue = TextEditingController();
  final TextEditingController eventDescription = TextEditingController();

  DateTime? eventDate;
  TimeOfDay? eventStartTime;
  TimeOfDay? eventEndTime;

  final FirebaseFirestore fireStore = FirebaseFirestore.instance;

  bool isLoading = false;

  static const Color primary = Color(0xFF9D7BFF);
  static const Color background = Color(0xFFF4F2FF);
  static const Color textMain = Color(0xFF1F2937);
  static const Color textMuted = Color(0xFF6B7280);

  @override
  void dispose() {
    eventName.dispose();
    eventVenue.dispose();
    eventDescription.dispose();
    super.dispose();
  }

  void showSnack(String text, bool success) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          backgroundColor: success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  void pickDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date != null) {
      setState(() => eventDate = date);
    }
  }

  void pickStartTime(BuildContext context) async {
    final time =
    await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time != null) {
      setState(() => eventStartTime = time);
    }
  }

  void pickEndTime(BuildContext context) async {
    final time =
    await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time != null) {
      setState(() => eventEndTime = time);
    }
  }

  String formatTime(TimeOfDay? time) {
    if (time == null) return "";
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  String formatDateWords(DateTime? date) {
    if (date == null) return "";
    return DateFormat('EEE d MMM yyyy').format(date);
  }

  Future<void> createEvent(BuildContext context) async {
    if (isLoading) return;

    if (eventName.text.isEmpty ||
        eventVenue.text.isEmpty ||
        eventDescription.text.isEmpty ||
        eventDate == null ||
        eventStartTime == null ||
        eventEndTime == null) {
      showSnack("Fill all fields", false);
      return;
    }

    final startMinutes =
        eventStartTime!.hour * 60 + eventStartTime!.minute;
    final endMinutes =
        eventEndTime!.hour * 60 + eventEndTime!.minute;

    if (startMinutes >= endMinutes) {
      showSnack("End time must be after start time", false);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => isLoading = true);

    try {
      final token = await user.getIdTokenResult(true);

      final data = {
        'date': DateFormat('yyyy-MM-dd').format(eventDate!),
        'description': eventDescription.text.trim(),
        'host': token.claims?['club-name']?.toString(),
        'start-time': formatTime(eventStartTime),
        'end-time': formatTime(eventEndTime),
        'title': eventName.text.trim(),
        'venue': eventVenue.text.trim()
      };

      final batch = fireStore.batch();

      final eventRef = fireStore.collection("events").doc();
      batch.set(eventRef, data);

      final adminRef = fireStore
          .collection('admin')
          .doc(user.uid)
          .collection('events')
          .doc();
      batch.set(adminRef, data);

      await batch.commit();

      if (!mounted) return;

      showSnack("Event is live!", true);

      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => HomepageState()),
              (route) => false,
        );
      });
    } catch (e) {
      showSnack("Error Occurred", false);
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Row(
                children: [
                  Text(
                    "Create an Event",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: textMain,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(40)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _inputRow(
                          icon: Icons.event,
                          hint: "Event Name",
                          controller: eventName),
                      _inputRow(
                          icon: Icons.location_on,
                          hint: "Event Venue",
                          controller: eventVenue),
                      _inputRow(
                          icon: Icons.description,
                          hint: "Description",
                          controller: eventDescription,
                          maxLines: 3),
                      const SizedBox(height: 20),
                      _dateTimeDisplay(
                        icon: Icons.calendar_today,
                        label: "Date",
                        value: formatDateWords(eventDate),
                        onTap: () => pickDate(context),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _dateTimeDisplay(
                              icon: Icons.schedule,
                              label: "Start",
                              value: formatTime(eventStartTime),
                              onTap: () => pickStartTime(context),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _dateTimeDisplay(
                              icon: Icons.schedule,
                              label: "End",
                              value: formatTime(eventEndTime),
                              onTap: () => pickEndTime(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: isLoading ? null : () => createEvent(context),
            child: isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  "Create Event",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded,
                    color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputRow({
    required IconData icon,
    required String hint,
    int maxLines = 1,
    required TextEditingController controller,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Icon(icon, color: primary),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateTimeDisplay({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: primary),
                const SizedBox(width: 8),
                Text(label,
                    style:
                    const TextStyle(color: textMuted, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value.isEmpty ? "Select" : value,
              style: TextStyle(
                color: value.isEmpty ? textMuted : textMain,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}