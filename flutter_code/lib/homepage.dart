import 'package:event_manager/appLaunch.dart';
import 'package:event_manager/event_creation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String host;
  final String title;
  final String startTime;
  final String endTime;
  final String date;
  final String description;
  final String venue;

  Event({
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.venue,
    required this.date,
    required this.description,
    required this.host,
  });

  factory Event.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Event(
      host: data["host"] ?? "",
      title: data["title"] ?? "",
      startTime: data["start-time"] ?? "",
      endTime: data["end-time"] ?? "",
      venue: data["venue"] ?? "",
      date: data["date"] ?? "",
      description: data["description"] ?? "",
    );
  }
}

class HomepageState extends StatefulWidget {
  const HomepageState({super.key});

  @override
  State<HomepageState> createState() => Homepage();
}

class Homepage extends State<HomepageState> {
  DateTime focusedDate = DateTime.now();
  DateTime selectedDate = DateTime.now();

  final FirebaseFirestore firebase = FirebaseFirestore.instance;

  final List<Event> events = [];
  final Set<String> selectedIndices = {};
  final Set<String> removableIndices = {};
  final Map<String, bool> organizations = {};

  bool isLoading = true;

  final Color primary = const Color(0xFF6C63FF);
  final Color background = const Color(0xFFF8F9FE);
  final Color textMain = const Color(0xFF2D2D2D);
  final Color textMuted = const Color(0xFF9E9E9E);
  final Color white = Colors.white;

  @override
  void initState() {
    super.initState();
    initData();
  }

  Future<void> initData() async {
    await Future.wait([
      fetchEvents(),
      initializeSelectedEvents(),
      getRemovableEvents(),
      generateFilters(),
    ]);

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchEvents() async {
    final snapshot = await firebase.collection("events").get();
    events.clear();
    for (var doc in snapshot.docs) {
      events.add(Event.fromDoc(doc));
    }
  }

  Future<bool> getStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final token = await user.getIdTokenResult(true);
    return token.claims?['admin'] == true;
  }

  Future<void> signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MyHomepage()),
    );
  }

  Future<void> generateFilters() async {
    final entry = await firebase.collection('organizations').get();
    for (var doc in entry.docs) {
      organizations[doc['club-name']] = true;
    }
  }

  Future<void> deleteEntry(Event e) async {
    final batch = firebase.batch();

    final entry = await firebase
        .collection('events')
        .where('title', isEqualTo: e.title)
        .where('date', isEqualTo: e.date)
        .get();

    for (var doc in entry.docs) {
      batch.delete(doc.reference);
    }

    final adminEntry = await firebase
        .collection('admin')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .collection('events')
        .where('title', isEqualTo: e.title)
        .where('date', isEqualTo: e.date)
        .get();

    for (var doc in adminEntry.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  Future<void> initializeSelectedEvents() async {
    final data = await firebase
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .collection('events')
        .get();

    for (var doc in data.docs) {
      selectedIndices.add(doc['key']);
    }
  }

  void toggleEventSelection(String key) async {
    final userRef = firebase
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .collection('events');

    if (selectedIndices.contains(key)) {
      final snapshots =
      await userRef.where("key", isEqualTo: key).get();
      for (var doc in snapshots.docs) {
        await doc.reference.delete();
      }
      selectedIndices.remove(key);
    } else {
      await userRef.add({'key': key});
      selectedIndices.add(key);
    }

    if (mounted) setState(() {});
  }

  Future<void> getRemovableEvents() async {
    final data = await firebase
        .collection('admin')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .collection('events')
        .get();

    for (var doc in data.docs) {
      removableIndices.add("${doc['title']}${doc['date']}");
    }
  }

  List<Event> eventFinder(DateTime date) {
    return events.where((event) {
      final eventDate = DateTime.tryParse(event.date);
      if (eventDate == null) return false;
      return isSameDay(eventDate, date) &&
          (organizations[event.host] ?? true);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {

    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: primary)),
      );
    }

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Calendar",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textMain,
                    ),
                  ),
                  Row(
                    children: [
                      _headerButton(
                          icon: Icons.logout,
                          onTap: () => signOut(context)),
                    ],
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TableCalendar(
                focusedDay: focusedDate,
                firstDay: DateTime.utc(2024, 1, 1),
                lastDay: DateTime.utc(2028, 12, 31),
                selectedDayPredicate: (value) =>
                    isSameDay(value, selectedDate),
                onDaySelected: (d, f) {
                  setState(() {
                    selectedDate = d;
                    focusedDate = f;
                  });
                },
                eventLoader: eventFinder,
              ),
            ),
            Expanded(
              child: FutureBuilder<bool>(
                future: getStatus(),
                builder: (context, snapshot) {
                  final isAdmin = snapshot.data == true;
                  final filteredEvents = eventFinder(selectedDate);

                  if (filteredEvents.isEmpty) {
                    return const Center(child: Text("No events"));
                  }

                  return ListView.builder(
                    itemCount: filteredEvents.length,
                    itemBuilder: (context, index) {
                      final e = filteredEvents[index];
                      final key = "${e.title}${e.date}";

                      Widget? trailing;

                      if (isAdmin &&
                          removableIndices.contains(key)) {
                        trailing = IconButton(
                          icon: const Icon(Icons.delete,
                              color: Colors.red),
                          onPressed: () async {
                            await deleteEntry(e);
                            if (!mounted) return;
                            await fetchEvents();
                            setState(() {});
                          },
                        );
                      } else {
                        final isSelected =
                        selectedIndices.contains(key);

                        trailing = IconButton(
                          icon: Icon(
                            isSelected
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                            color: isSelected
                                ? Colors.green
                                : primary,
                          ),
                          onPressed: () {
                            toggleEventSelection(key);
                          },
                        );
                      }

                      return ListTile(
                        title: Text(e.title),
                        subtitle:
                        Text("${e.startTime} - ${e.endTime}"),
                        trailing: trailing,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FutureBuilder<bool>(
        future: getStatus(),
        builder: (context, snapshot) {
          if (snapshot.data == true) {
            return FloatingActionButton(
              backgroundColor: primary,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const EventCreationState()),
                );
              },
              child: const Icon(Icons.add),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _headerButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return IconButton(
      icon: Icon(icon, color: textMain),
      onPressed: onTap,
    );
  }
}