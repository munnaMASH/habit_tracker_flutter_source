// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:habit_tracker/main.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final tempDir = await Directory.systemTemp.createTemp('habit_tracker_test');
    Hive.init(tempDir.path);
    if (!Hive.isBoxOpen('habits')) {
      await Hive.openBox('habits');
    }
  });

  testWidgets('Habit tracker app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const HabitTrackerApp());

    expect(find.text('Habit Tracker'), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
  });

  test('habit streak counts consecutive completed days', () {
    final today = DateTime.now();
    final habit = Habit(
      id: 'habit-1',
      name: 'Read 20 minutes',
      createdAt: today.subtract(const Duration(days: 10)),
      completedDates: {
        _dateKey(today),
        _dateKey(today.subtract(const Duration(days: 1))),
        _dateKey(today.subtract(const Duration(days: 2))),
      },
    );

    expect(habit.currentStreakFor(today), 3);
    expect(habit.isCompletedOn(today), isTrue);
  });

  test('habit history returns completed dates inside the selected month', () {
    final now = DateTime(2026, 9, 15);
    final habit = Habit(
      id: 'habit-2',
      name: 'Workout',
      createdAt: now.subtract(const Duration(days: 20)),
      completedDates: {
        _dateKey(DateTime(2026, 9, 2)),
        _dateKey(DateTime(2026, 9, 8)),
        _dateKey(DateTime(2026, 9, 15)),
      },
    );

    final monthHistory = habit.historyForMonth(2026, 9);

    expect(monthHistory.length, 3);
    expect(monthHistory.any((entry) => entry.date.day == 15), isTrue);
  });
}

String _dateKey(DateTime date) {
  final local = DateTime(date.year, date.month, date.day);
  return '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}
