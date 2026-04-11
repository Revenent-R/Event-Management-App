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

    try {
      if (selectedIndices.contains(key)) {
        final snapshots =
        await userRef.where("key", isEqualTo: key).get();
        for (var doc in snapshots.docs) {
          await doc.reference.delete();
        }
        selectedIndices.remove(key);
        showSnack("Removed from your events", false);
      } else {
        await userRef.add({'key': key});
        selectedIndices.add(key);
        showSnack("Added to your events", true);
      }

      if (mounted) setState(() {});
    } catch (e) {
      showSnack("Action failed", false);
    }
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

  void showEventDetails(Event e) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                e.title,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(e.host, style: TextStyle(color: textMuted)),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 18),
                  const SizedBox(width: 8),
                  Text("${e.startTime} - ${e.endTime}"),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(e.venue)),
                ],
              ),
              const SizedBox(height: 20),
              const Text("About",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(e.description),
            ],
          ),
        );
      },
    );
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
                  Text("Calendar",
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: textMain)),
                  IconButton(
                      icon: Icon(Icons.logout, color: textMain),
                      onPressed: () => signOut(context))
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

            Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              height: 6,
              width: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
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
                    padding: const EdgeInsets.all(16),
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
                            try {
                              await deleteEntry(e);
                              await fetchEvents();
                              if (!mounted) return;
                              setState(() {});
                              showSnack("Event deleted", true);
                            } catch (e) {
                              showSnack("Failed to delete event", false);
                            }
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

                      return GestureDetector(
                        onTap: () => showEventDetails(e),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: primary.withValues(alpha: 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: primary,
                                  borderRadius:
                                  BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(e.title,
                                        style: const TextStyle(
                                            fontWeight:
                                            FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    Text(
                                        "${e.startTime} - ${e.endTime}",
                                        style: TextStyle(
                                            color: textMuted)),
                                    Text(e.venue,
                                        style: TextStyle(
                                            color: textMuted)),
                                  ],
                                ),
                              ),
                              if (trailing != null) trailing,
                            ],
                          ),
                        ),
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
}