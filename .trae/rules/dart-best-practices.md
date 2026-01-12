---
description: Dart language best practices, coding style, and conventions. Load when writing new Dart code, refactoring existing code, discussing code quality, null safety patterns, async/await usage, exception handling, or following Effective Dart guidelines.
---

# Dart Best Practices

## Core Principles

- Follow [Effective Dart](https://dart.dev/effective-dart) guidelines
- Apply SOLID principles throughout the codebase
- Write concise, modern, technical Dart code
- Prefer functional and declarative patterns
- Favor composition over inheritance

## Code Quality Standards

- **Line length:** 80 characters max
- **Naming:** `PascalCase` for classes/enums, `camelCase` for members/variables, `snake_case` for files
- **Functions:** Keep short and single-purpose (≤20 lines)
- **Simplicity:** Straightforward code over clever/obscure implementations
- **Error Handling:** Never fail silently; anticipate and handle errors

## Null Safety

- Write soundly null-safe code
- Leverage Dart's null safety features fully
- Avoid `!` unless value is guaranteed non-null
- Use pattern matching to simplify null checks

## Async/Await

- Use `Future's`, `async`, `await` for single async operations
- Use `Stream`s for sequences of async events
- Always include robust error handling with `try-catch`

## Modern Dart Features

- **Pattern Matching:** Use where it simplifies code
- **Records:** Return multiple values without defining full classes
- **Switch Expressions:** Prefer exhaustive switches (no `break` needed)
- **Arrow Functions:** Use `=>` for simple one-liners

## Code Organization

- Define related classes in same library file
- Export smaller libraries from top-level library
- Group related libraries in same folder
- Add doc comments to all public APIs

## Comments & Documentation

- Write clear comments for complex/non-obvious code
- Avoid over-commenting obvious code
- No trailing comments
- Use `///` for documentation comments

## Exception Handling

```dart
try {
  await riskyOperation();
} on SpecificException catch (e) {
  // Handle specific case
} catch (e, stackTrace) {
  // Handle general case with stack trace
  rethrow; // If appropriate
}
```

## Logging

Use `dart:developer` for structured logging:

```dart
import 'dart:developer' as developer;

developer.log(
  'Operation failed',
  name: 'myapp.feature',
  level: 1000, // SEVERE
  error: e,
  stackTrace: s,
);
```

## Code Generation

- Use `build_runner` for code generation tasks
- Run `dart run build_runner build --delete-conflicting-outputs` after changes
- Never edit generated files (`*.g.dart`, `*.freezed.dart`)
