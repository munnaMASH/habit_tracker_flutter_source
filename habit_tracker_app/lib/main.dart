
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox('habits');

  runApp(const HabitTrackerApp());
}

const Color primaryColor = Color(0xFF16866A);
const Color backgroundColor = Color(0xFFF5F7F6);

String _dateKey(DateTime date) {
  final local = DateTime(date.year, date.month, date.day);
  return '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}

class Habit {
  Habit({
    required this.id,
    required this.name,
    required this.createdAt,
    Set<String>? completedDates,
  }) : completedDates = {...completedDates ?? const <String>{}};

  final String id;
  final String name;
  final DateTime createdAt;
  final Set<String> completedDates;

  bool isCompletedOn(DateTime date) {
    return completedDates.contains(_dateKey(date));
  }

  int currentStreakFor(DateTime referenceDate) {
    final anchor = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
    );

    DateTime current = anchor;

    if (!isCompletedOn(current)) {
      current = current.subtract(const Duration(days: 1));
    }

    int streak = 0;
    while (isCompletedOn(current)) {
      streak++;
      current = current.subtract(const Duration(days: 1));
    }

    return streak;
  }

  List<_HabitHistoryEntry> historyForMonth(int year, int month) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final entries = <_HabitHistoryEntry>[];

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      if (isCompletedOn(date)) {
        entries.add(_HabitHistoryEntry(date));
      }
    }

    return entries;
  }
}

class _HabitHistoryEntry {
  const _HabitHistoryEntry(this.date);

  final DateTime date;
}

class HabitTrackerApp extends StatelessWidget {
  const HabitTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
        ),
        scaffoldBackgroundColor: backgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: backgroundColor,
          elevation: 0,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Box box = Hive.box('habits');

  int selectedTab = 0;

  String get today =>
      DateFormat('yyyy-MM-dd').format(DateTime.now());

  List<Map<String, dynamic>> get habits {
    return box.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  bool isCompleted(Map<String, dynamic> habit) {
    final completed =
        List<String>.from(habit['completed'] ?? []);

    return completed.contains(today);
  }

  int streakFor(Map<String, dynamic> habit) {
    final completed =
        List<String>.from(habit['completed'] ?? []);

    DateTime currentDay = DateTime.now();

    // If today's habit is not done, check yesterday's streak.
    if (!completed.contains(
      DateFormat('yyyy-MM-dd').format(currentDay),
    )) {
      currentDay =
          currentDay.subtract(const Duration(days: 1));
    }

    int streak = 0;

    while (completed.contains(
      DateFormat('yyyy-MM-dd').format(currentDay),
    )) {
      streak++;

      currentDay =
          currentDay.subtract(const Duration(days: 1));
    }

    return streak;
  }

  Future<void> addHabit(String name) async {
    if (name.trim().isEmpty) return;

    await box.add({
      'name': name.trim(),
      'createdAt': today,
      'completed': <String>[],
    });

    if (mounted) setState(() {});
  }

  Future<void> editHabit(
    int index,
    Map<String, dynamic> habit,
    String newName,
  ) async {
    if (newName.trim().isEmpty) return;

    final key = box.keyAt(index);

    habit['name'] = newName.trim();

    await box.put(key, habit);

    if (mounted) setState(() {});
  }

  Future<void> toggleHabit(
    int index,
    Map<String, dynamic> habit,
  ) async {
    final key = box.keyAt(index);

    final completed =
        List<String>.from(habit['completed'] ?? []);

    if (completed.contains(today)) {
      completed.remove(today);
    } else {
      completed.add(today);
    }

    habit['completed'] = completed;

    await box.put(key, habit);

    if (mounted) setState(() {});
  }

  Future<void> deleteHabit(int index) async {
    await box.deleteAt(index);

    if (mounted) setState(() {});
  }

  void showHabitDialog({
    int? index,
    Map<String, dynamic>? habit,
  }) {
    final controller = TextEditingController(
      text: habit?['name'] ?? '',
    );

    final isEditing = habit != null && index != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 22,
            right: 22,
            top: 25,
            bottom:
                MediaQuery.of(context).viewInsets.bottom + 25,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Edit Habit' : 'Create a Habit',
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization:
                    TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Enter habit name',
                  prefixIcon: const Icon(Icons.edit_note),
                  filled: true,
                  fillColor: backgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (value) {
                  if (isEditing) {
                    editHabit(index, habit, value);
                  } else {
                    addHabit(value);
                  }

                  Navigator.pop(context);
                },
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (isEditing) {
                      editHabit(
                        index,
                        habit,
                        controller.text,
                      );
                    } else {
                      addHabit(controller.text);
                    }

                    Navigator.pop(context);
                  },
                  style: FilledButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: primaryColor,
                  ),
                  child: Text(
                    isEditing ? 'Save Changes' : 'Add Habit',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> confirmDelete(int index, String name) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Habit?'),
          content: Text(
            'Do you want to delete "$name"?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      deleteHabit(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(
              Icons.spa_rounded,
              color: primaryColor,
              size: 29,
            ),
            SizedBox(width: 9),
            Text(
              'Habit Tracker',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 23,
              ),
            ),
          ],
        ),
      ),

      body: IndexedStack(
        index: selectedTab,
        children: [
          buildHome(),
          buildHistory(),
          buildStatistics(),
        ],
      ),

      floatingActionButton: selectedTab == 0
          ? FloatingActionButton.extended(
              onPressed: () => showHabitDialog(),
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add Habit'),
            )
          : null,

      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedTab,
        onDestinationSelected: (index) {
          setState(() => selectedTab = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Statistics',
          ),
        ],
      ),
    );
  }

  // HOME SCREEN

  Widget buildHome() {
    final list = habits;

    final completedCount =
        list.where((h) => isCompleted(h)).length;

    final progress = list.isEmpty
        ? 0.0
        : completedCount / list.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        Text(
          DateFormat('EEEE, d MMMM yyyy')
              .format(DateTime.now()),
          style: const TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Build better habits.',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 5),

        const Text(
          'একটু একটু করে প্রতিদিন এগিয়ে যাও।',
          style: TextStyle(
            color: Colors.black54,
            fontSize: 15,
          ),
        ),

        const SizedBox(height: 22),

        // PROGRESS CARD

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF16866A),
                Color(0xFF0D5D4B),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.wb_sunny_outlined,
                    color: Colors.white70,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "TODAY'S PROGRESS",
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$completedCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: 7,
                    ),
                    child: Text(
                      ' / ${list.length} completed',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 9,
                  backgroundColor: Colors.white24,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                list.isEmpty
                    ? 'Add your first habit to get started!'
                    : '${(progress * 100).round()}% completed today',
                style: const TextStyle(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 27),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Today's Habits",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),

            Text(
              '${list.length} habits',
              style: const TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        if (list.isEmpty)
          const EmptyState()
        else
          ...list.asMap().entries.map((entry) {
            final index = entry.key;
            final habit = entry.value;

            return habitCard(index, habit);
          }),
      ],
    );
  }

  // HABIT CARD

  Widget habitCard(
    int index,
    Map<String, dynamic> habit,
  ) {
    final done = isCompleted(habit);
    final streak = streakFor(habit);

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: done
              ? primaryColor.withValues(alpha: 0.25)
              : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // SINGLE CHECKBOX

          InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () => toggleHabit(index, habit),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: done
                    ? primaryColor
                    : const Color(0xFFEAF4F0),
                shape: BoxShape.circle,
              ),
              child: Icon(
                done
                    ? Icons.check_rounded
                    : Icons.circle_outlined,
                color: done ? Colors.white : primaryColor,
                size: 25,
              ),
            ),
          ),

          const SizedBox(width: 14),

          // HABIT NAME AND STREAK

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit['name'] ?? 'Habit',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 7),

                Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      size: 17,
                      color: Color(0xFFE99A32),
                    ),

                    const SizedBox(width: 4),

                    Text(
                      '$streak day streak',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // MENU: EDIT AND DELETE

          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              color: Colors.black45,
            ),
            onSelected: (value) {
              if (value == 'edit') {
                showHabitDialog(
                  index: index,
                  habit: habit,
                );
              } else if (value == 'delete') {
                confirmDelete(
                  index,
                  habit['name'] ?? 'Habit',
                );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined),
                    SizedBox(width: 10),
                    Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline),
                    SizedBox(width: 10),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // HISTORY SCREEN

  Widget buildHistory() {
    final list = habits;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Habit History',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'তোমার গত ৭ দিনের Habit completion দেখো।',
          style: TextStyle(color: Colors.black54),
        ),

        const SizedBox(height: 20),

        ...List.generate(7, (index) {
          final date = DateTime.now().subtract(
            Duration(days: index),
          );

          final dateKey =
              DateFormat('yyyy-MM-dd').format(date);

          final doneCount = list.where((habit) {
            final completed =
                List<String>.from(habit['completed'] ?? []);

            return completed.contains(dateKey);
          }).length;

          final percentage = list.isEmpty
              ? 0
              : (doneCount / list.length * 100).round();

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF4F0),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    DateFormat('d').format(date),
                    style: const TextStyle(
                      color: primaryColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        index == 0
                            ? 'Today'
                            : DateFormat('EEE, MMM d')
                                .format(date),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '$doneCount of ${list.length} habits completed',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                Text(
                  '$percentage%',
                  style: const TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // STATISTICS SCREEN

  Widget buildStatistics() {
    final list = habits;

    int totalCompletions = 0;

    for (final habit in list) {
      totalCompletions +=
          List<String>.from(habit['completed'] ?? []).length;
    }

    final totalPossible = list.length * 7;

    final weeklyCompleted = list.fold<int>(
      0,
      (sum, habit) {
        final completed =
            List<String>.from(habit['completed'] ?? []);

        int count = 0;

        for (int i = 0; i < 7; i++) {
          final date = DateFormat('yyyy-MM-dd').format(
            DateTime.now().subtract(Duration(days: i)),
          );

          if (completed.contains(date)) {
            count++;
          }
        }

        return sum + count;
      },
    );

    final weeklyProgress = totalPossible == 0
        ? 0
        : (weeklyCompleted / totalPossible * 100).round();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Statistics',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Track your consistency and progress.',
          style: TextStyle(color: Colors.black54),
        ),

        const SizedBox(height: 25),

        Row(
          children: [
            Expanded(
              child: statCard(
                'Total Habits',
                '${list.length}',
                Icons.checklist_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: statCard(
                'Completed',
                '$totalCompletions',
                Icons.check_circle_outline,
              ),
            ),
          ],
        ),

        const SizedBox(height: 15),

        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Last 7 Days',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 18),

              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$weeklyProgress%',
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(
                      bottom: 8,
                      left: 8,
                    ),
                    child: Text(
                      'completion rate',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: weeklyProgress / 100,
                  minHeight: 10,
                  color: primaryColor,
                  backgroundColor: const Color(0xFFEAF4F0),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        const Text(
          'Habit Streaks',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        if (list.isEmpty)
          const EmptyState()
        else
          ...list.map((habit) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: Color(0xFFE99A32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      habit['name'] ?? 'Habit',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${streakFor(habit)} days',
                    style: const TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget statCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryColor, size: 27),
          const SizedBox(height: 15),
          Text(
            value,
            style: const TextStyle(
              fontSize: 29,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 35,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.checklist_rounded,
            size: 48,
            color: primaryColor,
          ),
          SizedBox(height: 12),
          Text(
            'No habits yet',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Tap Add Habit to create your first daily habit.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
