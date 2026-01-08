---
description: "Flutter testing patterns, best practices, and conventions. Load when writing unit tests, widget tests, or integration tests, using mocktail for mocking, testing Riverpod providers with ProviderScope overrides, following Arrange-Act-Assert pattern, or implementing test coverage."
---

# Flutter Testing Best Practices

## Test Types & Packages

- **Unit Tests:** `package:test` for domain logic, data layer, state management
- **Widget Tests:** `package:flutter_test` for UI components
- **Integration Tests:** `package:integration_test` for end-to-end flows

## Test Structure (Arrange-Act-Assert)

```dart
test('should increment counter', () {
  // Arrange
  final counter = Counter();

  // Act
  counter.increment();

  // Assert
  expect(counter.value, equals(1));
});
```

## Widget Testing

```dart
testWidgets('MyWidget shows title', (tester) async {
  // Arrange & Act
  await tester.pumpWidget(
    const MaterialApp(
      home: MyWidget(title: 'Test'),
    ),
  );

  // Assert
  expect(find.text('Test'), findsOneWidget);
});
```

### Common Widget Test Actions

```dart
// Tap
await tester.tap(find.byType(ElevatedButton));
await tester.pump(); // Rebuild after state change

// Enter text
await tester.enterText(find.byType(TextField), 'hello');

// Scroll
await tester.drag(find.byType(ListView), const Offset(0, -300));
await tester.pumpAndSettle(); // Wait for animations
```

## Finders

```dart
find.text('Hello')              // By text
find.byType(ElevatedButton)     // By widget type
find.byKey(const Key('submit')) // By key
find.byIcon(Icons.add)          // By icon
find.descendant(                // Nested finder
  of: find.byType(Card),
  matching: find.text('Title'),
)
```

## Assertions with `package:checks`

Prefer `checks` for expressive assertions:

```dart
import 'package:checks/checks.dart';

check(value).equals(expected);
check(list).length.equals(3);
check(result).isA<SuccessState>();
```

## Mocking Strategy

### Prefer Fakes/Stubs over Mocks

```dart
// ✅ Fake implementation
class FakeAuthRepo implements IAuthRepo {
  @override
  Future<User> login(String email, String password) async {
    return User(id: '1', email: email);
  }
}

// Use in test
final repo = FakeAuthRepo();
```

### When Mocks are Necessary

Use `mocktail` (no code generation):

```dart
import 'package:mocktail/mocktail.dart';

class MockAuthRepo extends Mock implements IAuthRepo {}

test('login calls repo', () {
  final mockRepo = MockAuthRepo();
  when(() => mockRepo.login(any(), any()))
      .thenAnswer((_) async => User(id: '1'));

  // ... test logic

  verify(() => mockRepo.login('test@test.com', 'pass')).called(1);
});
```

## Testing Riverpod Providers

```dart
testWidgets('provider test', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepoProvider.overrideWithValue(FakeAuthRepo()),
      ],
      child: const MaterialApp(home: LoginPage()),
    ),
  );

  // ... test
});
```

## Integration Tests

```dart
// integration_test/app_test.dart
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('full login flow', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(Key('email')), 'test@test.com');
    await tester.tap(find.byKey(Key('submit')));
    await tester.pumpAndSettle();

    expect(find.text('Welcome'), findsOneWidget);
  });
}
```

## Project Conventions

- Test files: `*_test.dart`
- Mirror feature structure: `test/features/auth/...`
- Run with: `make test` or `flutter test`
- Coverage: `make coverage`

## Running Tests

```bash
# All tests
flutter test

# Specific file
flutter test test/unit/auth_test.dart

# With coverage
flutter test --coverage
```
