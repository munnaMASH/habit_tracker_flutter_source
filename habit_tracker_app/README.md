# Habit Tracker — Flutter University Project

Features:
- Add a new habit
- View today's habit list
- Complete/uncomplete today's habit with checkbox or tap
- Automatic current streak calculation
- Local persistence using SharedPreferences
- Delete habits
- Today's progress percentage
- Swipe a habit left to delete

## Run in VS Code / PowerShell

1. Create a Flutter shell project:

```powershell
flutter create habit_tracker
```

2. Replace the generated `pubspec.yaml` with the `pubspec.yaml` from this package.

3. Replace the generated `lib/main.dart` with this package's `lib/main.dart`.

4. From the project folder run:

```powershell
flutter pub get
flutter run
```

If you are putting these files into an existing Flutter project, just replace `pubspec.yaml` and `lib/main.dart`, then run `flutter pub get`.

## How streak works

The streak shown is the number of consecutive days completed ending today. If today's habit is not completed, the current streak becomes 0. Completion history is stored locally on the device, so closing the app does not erase it.
