# Agent Guidelines for StudyCircle Flutter App

## Build & Test Commands

- **Run app**: `flutter run`
- **Run tests**: `flutter test`
- **Run single test**: `flutter test test/widget_test.dart` or `flutter test --name "test description"`
- **Analyze code**: `flutter analyze`
- **Format code**: `dart format .`
- **Clean & rebuild**: `flutter clean && flutter pub get`

## Code Style & Conventions

- **Linting**: Use `package:flutter_lints/flutter.yaml` (already configured)
- **Imports**: Group in order: dart imports, package imports, relative imports (separated by blank lines)
- **Formatting**: Use `const` constructors wherever possible, prefer single quotes for strings
- **Naming**: UpperCamelCase for classes, lowerCamelCase for variables/methods, snake_case for files
- **Types**: Always specify return types and parameter types explicitly
- **Error Handling**: Use try-catch blocks, log errors via `AppLogger.error(message, error, stackTrace)`

## Project Structure

- **Theme**: Use `AppColors` and `AppTheme` classes (in `lib/theme/`)
- **Logging**: Use `AppLogger` for all logging (debug, info, warning, error)
- **Firebase**: Project uses Firebase (Auth, Firestore) - ensure proper initialization
- **Storage**: Cloudnairy
- **State Management**: Not yet configured - use setState for now, consider Provider/Riverpod for complex state

## Project Context

StudyCircle is a study group finder app with user auth, group management, session scheduling, and dashboards. Focus on clean, modular code following Flutter best practices.
