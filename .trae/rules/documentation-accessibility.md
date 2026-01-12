---
description: Documentation standards and accessibility guidelines. Load when writing doc comments, API documentation, improving code readability, implementing accessibility features (Semantics widget, screen reader support), ensuring WCAG compliance, or discussing A11Y best practices.
---

# Documentation & Accessibility

## Documentation Philosophy

- Comment **why**, not what (code should be self-explanatory)
- Write for the reader who has a question
- No useless documentation that restates the obvious
- Use consistent terminology throughout

## Doc Comment Style

### Use `///` for Documentation

```dart
/// Authenticates the user with the provided credentials.
///
/// Returns the authenticated [User] on success.
///
/// Throws [AuthException] if credentials are invalid.
Future<User> login(String email, String password);
```

### Summary First

Start with a single-sentence summary:

```dart
/// Calculates the total price including tax.
///
/// The [taxRate] should be a decimal (e.g., 0.08 for 8%).
/// Returns the total with tax applied.
double calculateTotal(double price, double taxRate);
```

### Document Parameters Naturally

```dart
/// Creates a new user with the given [name] and [email].
///
/// If [isAdmin] is true, grants administrative privileges.
User createUser(String name, String email, {bool isAdmin = false});
```

## What to Document

- ✅ All public APIs (classes, methods, functions)
- ✅ Complex private logic
- ✅ Non-obvious behavior
- ✅ Library-level overview comments
- ❌ Obvious getters/setters
- ❌ Self-explanatory code

## Code Examples in Docs

````dart
/// Parses a date string in ISO 8601 format.
///
/// ```dart
/// final date = parseDate('2024-01-15');
/// print(date.year); // 2024
/// ```
DateTime parseDate(String dateString);
````

## Comment Placement

```dart
/// Documentation comment (before annotations)
@override
Future<void> dispose() async {
  // Implementation comment for complex logic
  await _cleanup();
}
```

---

# Accessibility (A11Y)

## Core Principles

Design for users with varying:

- Physical abilities
- Visual abilities
- Cognitive abilities
- Age groups

## Color Contrast (WCAG 2.1)

| Element            | Minimum Ratio |
| ------------------ | ------------- |
| Normal text        | **4.5:1**     |
| Large text (18pt+) | **3:1**       |
| UI components      | **3:1**       |

```dart
// Test contrast programmatically
final isAccessible =
    ThemeData.estimateBrightnessForColor(backgroundColor) !=
    ThemeData.estimateBrightnessForColor(textColor);
```

## Semantics Widget

Provide clear labels for screen readers:

```dart
Semantics(
  label: 'Delete item',
  hint: 'Double tap to delete this item',
  button: true,
  child: IconButton(
    icon: const Icon(Icons.delete),
    onPressed: _deleteItem,
  ),
)
```

### Semantic Properties

```dart
Semantics(
  label: 'Profile picture',
  image: true,
  child: CircleAvatar(...),
)

Semantics(
  label: 'Loading',
  liveRegion: true, // Announces changes
  child: CircularProgressIndicator(),
)
```

## Dynamic Text Scaling

Test with increased system font sizes:

```dart
// Respect user's text scale preference
Text(
  'Hello',
  style: Theme.of(context).textTheme.bodyMedium,
  // Avoid hardcoded sizes that ignore scaling
)

// If needed, limit scaling
MediaQuery.withClampedTextScaling(
  minScaleFactor: 1.0,
  maxScaleFactor: 1.5,
  child: MyWidget(),
)
```

## Touch Targets

Minimum touch target: **48x48** logical pixels

```dart
IconButton(
  icon: const Icon(Icons.menu),
  onPressed: _openMenu,
  // IconButton already enforces minimum size
)

// For custom widgets
GestureDetector(
  child: Container(
    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    child: CustomIcon(),
  ),
  onTap: _onTap,
)
```

## Focus Management

```dart
// Request focus programmatically
FocusScope.of(context).requestFocus(myFocusNode);

// Ensure logical focus order
Focus(
  autofocus: true,
  child: TextField(),
)
```

## Screen Reader Testing

- **Android:** TalkBack
- **iOS:** VoiceOver
- **Desktop:** System screen readers

Test all interactive elements have meaningful labels.

## Checklist

- [ ] Color contrast meets WCAG 2.1
- [ ] All images have alternative text
- [ ] Interactive elements have semantic labels
- [ ] UI works with 200% text scaling
- [ ] Touch targets are at least 48x48
- [ ] Focus order is logical
- [ ] Tested with screen reader
