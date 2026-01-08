---
description: "Flutter widget development patterns and best practices. Load when creating new widgets, optimizing widget performance, implementing const constructors, breaking down large build methods, using ListView.builder for lists, or discussing widget composition and reusability."
---

# Flutter Widget Best Practices

## Core Principles

- Everything in Flutter UI is a widget
- Widgets (especially `StatelessWidget`) are immutable
- When UI changes, Flutter rebuilds the widget tree
- Compose complex UIs from smaller, reusable widgets

## Widget Composition

- **Prefer composition** over extending existing widgets
- Use composition to avoid deep widget nesting
- Create small, focused widgets with single responsibilities

## Private Widgets Pattern

Use private `Widget` classes instead of helper methods:

```dart
// ✅ Good: Private widget class
class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Card(child: Text(title));
}

// ❌ Avoid: Private helper method returning Widget
Widget _buildFeatureCard(String title) => Card(child: Text(title));
```

## Build Method Optimization

- Break large `build()` methods into smaller private widgets
- Use `const` constructors wherever possible to reduce rebuilds
- Never perform expensive operations (network calls, complex computations) in `build()`

## Performance Patterns

### List Performance

```dart
// ✅ Use builder for long lists (lazy loading)
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
)

// ✅ For grids
GridView.builder(
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
  itemBuilder: (context, index) => ItemWidget(items[index]),
)
```

### Heavy Computations

```dart
// Use compute() for expensive operations
final result = await compute(parseJsonData, jsonString);
```

## Const Constructors

```dart
// ✅ Prefer const where possible
const Padding(
  padding: EdgeInsets.all(16),
  child: Text('Hello'),
)

// In build methods
return const Column(
  children: [
    Icon(Icons.star),
    Text('Constant widget'),
  ],
);
```

## Widget Keys

Use keys when:

- Reordering list items
- Preserving state in `StatefulWidget`s within collections
- Distinguishing widgets of same type

```dart
ListView.builder(
  itemBuilder: (context, index) => ItemCard(
    key: ValueKey(items[index].id),
    item: items[index],
  ),
)
```

## Flutter Hooks + Riverpod

For this project, use `HookConsumerWidget` for pages combining hooks with Riverpod:

```dart
class MyPage extends HookConsumerWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();
    final asyncValue = ref.watch(myProvider);
    // ...
  }
}
```
